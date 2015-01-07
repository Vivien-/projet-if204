%{
  #define _GNU_SOURCE
  #include <stdio.h>
  #include <string.h>
  #include <stdlib.h>
  #include "variable_type.h"
  #include "name_space.h"
  #include "generic_list.h"
  extern int yylineno;
  extern int asprintf(char** strp, const char *fmt, ...);
  int yylex ();
  int yyerror ();
  name_space_stack_t *ns = NULL;
  class_name_space_t *cns = NULL;
  char *file_name = NULL;
  char *file_output = NULL;
  FILE* output = NULL;
  FILE *input = NULL;

  char *cur_return_statement = NULL;
  char *parameter_declaration_str = NULL;

  generic_list_t *declaration_list = NULL;
  generic_list_t *declarator_list = NULL;
  generic_list_t *function_list = NULL;
%}

%token <str> IDENTIFIER
%token <integer> ICONSTANT
%token <floating> FCONSTANT
%token INC_OP DEC_OP LE_OP GE_OP EQ_OP NE_OP
%token <basic_type> INT FLOAT VOID CLASS
%token IF ELSE WHILE RETURN FOR DO
%type <str> statement statement_list compound_statement jump_statement declaration declaration_list parameter_declaration
%type <basic_type> type_name
%type <declarator> declarator
%type <identifier> compound_identifier
%type <function> external_declaration function_definition
%type <list> declarator_list parameter_list argument_expression_list
%type <expression> primary_expression unary_expression multiplicative_expression additive_expression comparison_expression expression_statement expression
%union {
  enum BASIC_TYPE basic_type;
  char *str;
  int integer;
  float floating;
  declarator_t declarator;
  identifier_t identifier;
  function_t function;
  expression_t expression;
  generic_list_t list;
}
%start program
%%

primary_expression
: compound_identifier { 
  variable_t *var = is_defined($1.name, ns);
  if (var == NULL) {
    yyerror("undeclared variable");
  }
  if (is_function(&(var->type))) {
    asprintf(&($$.reg), "-%d(%rbp)", get_stack_size(ns));
    asprintf(&($$.body), "\tcall %s", $1.name); 
  } else {
    $$.reg = "%ebx";
    asprintf(&($$.body), "\tmov -%d(%%rbp), %s", var->addr, $$.reg);
  }
}
| ICONSTANT { 
  $$.reg = "%ebx";
  asprintf(&($$.body), "\tmov $%d, %s", $1, $$.reg);
}
| FCONSTANT {
  union FloatInt u;
  u.f = $1;
  $$.reg = "%ebx";
  asprintf(&($$.body), "\tmov $%d, %s", u.i, $$.reg);
}
| '(' expression ')'
| compound_identifier INC_OP
| compound_identifier DEC_OP
;

compound_identifier
: IDENTIFIER { $$.name = $1; }
| IDENTIFIER '[' expression ']' { $$.name = $1; /*$$.offset = $3;*/ }
| IDENTIFIER '(' argument_expression_list ')' { $$.name = $1; $$.params = $3; }
| IDENTIFIER '(' ')' { $$.name = $1; TAILQ_INIT(&($$.params)); }
| IDENTIFIER '[' expression ']' '.' compound_identifier
| IDENTIFIER '(' argument_expression_list ')' '.' compound_identifier
| IDENTIFIER '(' ')' '.' compound_identifier
| IDENTIFIER '.' compound_identifier
;

argument_expression_list
: expression { TAILQ_INIT(&$$); insert(&$$, &$1, sizeof(expression_t)); }
| argument_expression_list ',' expression { $$ = $1; insert(&$$, &$3, sizeof(expression_t)); }
;

unary_expression
: primary_expression { $$ = $1; }
| '-' unary_expression
| '!' unary_expression
;

multiplicative_expression
: unary_expression { $$ = $1; }
| multiplicative_expression '*' unary_expression
;

additive_expression
: multiplicative_expression { $$ = $1; }
| additive_expression '+' multiplicative_expression
| additive_expression '-' multiplicative_expression
;

comparison_expression
: additive_expression { $$ = $1; }
| additive_expression '<' additive_expression
| additive_expression '>' additive_expression
| additive_expression LE_OP additive_expression
| additive_expression GE_OP additive_expression
| additive_expression EQ_OP additive_expression
| additive_expression NE_OP additive_expression
;

expression
: compound_identifier '=' comparison_expression { 
  variable_t *var;
  if ((var = is_defined($1.name, ns)) == NULL) {
    yyerror("undeclared variable");
  }
  asprintf(&($$.body), "%s\n\tmov %s, -%d(%%rbp)\n", $3.body, $3.reg, var->addr);
}
| compound_identifier '[' expression ']' '=' comparison_expression
| comparison_expression { $$ = $1; }
;

declaration
: type_name declarator_list ';' {
  int size;
  generic_element_t *e;
  declarator_t *declarator;
  $$ = "";
  TAILQ_FOREACH(e, &$2, pointers) {
    declarator = (declarator_t*)(e->data);
    declarator->type.basic = $1;
    if (is_defined(declarator->name, ns) != NULL) {
      yyerror("variable already declared");
    }
    if (is_function(&(declarator->type))) {
      if (!current_name_space_is_root(ns)) {
	yyerror("nested function declaration");
      }
    } else {
      size = get_size(&(declarator->type));
      //asprintf(&$$, "%s\tmovl $%d, %%esp\n", $$, size);
    }
    insert_in_current_name_space(declarator->name, new_variable(declarator->type, get_stack_size(ns)), ns);
  }
 }
;

declarator_list
: declarator { TAILQ_INIT(&$$); insert(&$$, &$1, sizeof(declarator_t)); }
| declarator_list ',' declarator { $$ = $1; insert(&$$, &$3, sizeof(declarator_t)); }
;

type_name
: VOID { $$ = TYPE_VOID; }
| INT { $$ = TYPE_INT; }
| FLOAT {$$ = TYPE_FLOAT; }
| CLASS IDENTIFIER { $$ = TYPE_CLASS; }
;

declarator
: IDENTIFIER  { $$.name = $1; $$.type.array_size = -1; $$.type.nb_param = -1; $$.type.pointer = 0; }
| '*' IDENTIFIER { $$.name = $2; $$.type.array_size = -1; $$.type.nb_param = -1; $$.type.pointer = 1; }
| IDENTIFIER '[' ICONSTANT ']' { $$.name = $1; $$.type.array_size = $3; $$.type.nb_param = -1; $$.type.pointer = 0; }
| declarator '(' parameter_list ')' { $$ = $1; $$.type.nb_param = nb_element(&$3); $$.type.params = $3; }
| declarator '(' ')' { $$ = $1; $$.type.nb_param = 0; }
;

parameter_list
: parameter_declaration { TAILQ_INIT(&$$); insert(&$$, &$1, sizeof(declarator_t)); }
| parameter_list ',' parameter_declaration { $$ = $1; insert(&$$, &$3, sizeof(declarator_t)); }
;

parameter_declaration
: type_name declarator { 
  int size;
  $2.type.basic = $1;
  size = get_size(&($2.type));
  asprintf(&$$, "%s\tsub $%d, %%esp\n", parameter_declaration_str, size);
  insert_in_current_name_space($2.name, new_variable($2.type, get_stack_size(ns)), ns);
}
;

statement
: compound_statement { $$ = $1; stack_new_name_space(ns); }
| expression_statement { $$ = $1.body; }
| selection_statement
| iteration_statement
| jump_statement { $$ = $1; }
;

compound_statement
: '{' '}' { 
  $$ = "\tret\n";
  //pop_name_space(ns);
  parameter_declaration_str = "";
}
| '{' statement_list '}' { 
  asprintf(&$$, "\tpushq %%rbp\n\tmov %%rsp, %%rbp\n%s%s\tmov %%rbp, %%rsp\n%s\n\tpopq %%rbp\n\tret\n", parameter_declaration_str, $2, cur_return_statement);
  //pop_name_space(ns);
  parameter_declaration_str = "";
}
| '{' declaration_list statement_list '}' {
  asprintf(&$$, "\tpushq %%rbp\n\tmov %%rsp, %%rbp\n%s%s%s\tmov %%rbp, %%rsp\n%s\n\tpopq %%rbp\n\tret\n", parameter_declaration_str, $2, $3, cur_return_statement);
  //pop_name_space(ns);
  parameter_declaration_str = "";
}
;

declaration_list
: declaration { $$ = $1; }
| declaration_list declaration { asprintf(&$$, "%s%s", $1, $2); }
;

statement_list
: statement { $$ = $1; }
| statement_list statement { asprintf(&$$, "%s%s", $1, $2); }
;

expression_statement
: ';'
| expression ';' { $$ = $1; }
;

selection_statement
: IF '(' expression ')' statement
| IF '(' expression ')' statement ELSE statement
;

iteration_statement
: WHILE '(' expression ')' statement
| FOR '(' expression_statement expression_statement expression ')' statement
| DO statement WHILE '(' expression ')' ';'
;

jump_statement
: RETURN ';'  { $$ = ""; cur_return_statement = ""; }
| RETURN expression ';'  { $$ = ""; asprintf(&cur_return_statement, "%s\n\tmov %s, %%eax", $2.body, $2.reg); }
;

program
: external_declaration { fprintf(output, "%s", $1.body); }
| program external_declaration { fprintf(output, "%s", $2.body); }
;

external_declaration
: function_definition { $$ = $1; asprintf(&($$.body), "\t.globl %s\n\t.type %s, @function \n%s:\n%s", $$.name, $$.name, $$.name, $$.body); };
| class_definition { $$.body = ""; }
| declaration { $$.body = $1; /*add usual push and pop?*/ }
;

function_definition
: type_name declarator compound_statement  {
  $$.type = $2.type;
  $$.name = $2.name;
  $$.body = $3;
 }
;

class_definition
: CLASS IDENTIFIER '{' class_internal_declaration_list '}'
| CLASS IDENTIFIER '{' '}'
;

class_internal_declaration_list
: class_internal_declaration
| class_internal_declaration class_internal_declaration_list
;

class_internal_declaration
: declaration
| function_definition
;

%%
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "name_space.h"
#include "variable_type.h"
#include "generic_list.h"

extern char yytext[];
extern int column;
extern int yylineno;
extern FILE *yyin;

void init(char* filename){
  file_name = strdup(filename);
  file_output = strdup(filename);
  file_output[strlen(file_output)-1] = 's';
  output = fopen(file_output, "w");
  input = fopen(filename, "r");
  ns = new_name_space_stack();
  cns = new_class_name_space();
  function_list = new_list();
  parameter_declaration_str = "";
}

void free_variables() {
  free(file_name);
  free(file_output);
  free_list(function_list, free);
  free_name_space_stack(ns);
  free_class_name_space(cns);
  fclose(input);
  fclose(output);
}

int yyerror (char *s) {
    fflush (stdout);
    fprintf (stderr, "%s:%d:%d: %s\n", file_name, yylineno, column, s);
    exit(1);
}

int main (int argc, char *argv[]) {
  if (argc==2) {
    init(argv[1]);
    if (input && output) {
      yyin = input;
      yyparse();
    }
    else {
      fprintf (stderr, "%s: Could not open %s\n", *argv, argv[1]);
      return 1;
    }
    free_variables();
  }
  else {
    fprintf (stderr, "%s: error: no input file\n", *argv);
	return 1;
  }
  return 0;
}
