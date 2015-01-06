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
%type <str> primary_expression unary_expression multiplicative_expression additive_expression comparison_expression expression expression_statement statement statement_list compound_statement jump_statement declaration declaration_list
%type <basic_type> type_name
%type <declarator> declarator
%type <identifier> compound_identifier
%type <function> external_declaration function_definition
%type <list> declarator_list parameter_list
%union {
  enum BASIC_TYPE basic_type;
  char *str;
  int integer;
  float floating;
  declarator_t declarator;
  identifier_t identifier;
  function_t function;
  generic_list_t list;
}
%start program
%%

primary_expression
: compound_identifier
| ICONSTANT { asprintf(&$$, "%d", $1); }
| FCONSTANT {
  union FloatInt u;
  u.f = $1;
  asprintf(&$$, "%d", u.i); 
}
| '(' expression ')'
| compound_identifier INC_OP
| compound_identifier DEC_OP
;

compound_identifier
: IDENTIFIER { $$.name = $1; }
| IDENTIFIER '[' expression ']' { $$.name = $1; $$.offset = $3; }
| IDENTIFIER '(' argument_expression_list ')' { $$.name = $1; /*$$.params = $3;*/ }
| IDENTIFIER '(' ')' { $$.name = $1; TAILQ_INIT(&($$.params)); }
| IDENTIFIER '[' expression ']' '.' compound_identifier
| IDENTIFIER '(' argument_expression_list ')' '.' compound_identifier
| IDENTIFIER '(' ')' '.' compound_identifier
| IDENTIFIER '.' compound_identifier
;

argument_expression_list
: expression
| argument_expression_list ',' expression
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
  asprintf(&$$, "\tmovl $%s, -%d(%%rbp)\n", $3, var->addr);
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
      asprintf(&$$, "%s\tsub $%d, %%esp\n", $$, size);
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
| declarator '(' parameter_list ')' { $$ = $1; /*$$.type.nb_param = nb_element(&$3); $$.type.params = $3; DONT FORGET TO INIT LIST*/ }
| declarator '(' ')' { $$ = $1; $$.type.nb_param = 0; }
;

parameter_list
: parameter_declaration
| parameter_list ',' parameter_declaration
;

parameter_declaration
: type_name declarator
;

statement
: compound_statement { $$ = $1; stack_new_name_space(ns); }
| expression_statement
| selection_statement
| iteration_statement
| jump_statement { $$ = $1; }
;

compound_statement
: '{' '}' { $$ = "\tret\n"; }
| '{' statement_list '}' { asprintf(&$$, "%s%s", $2, cur_return_statement); }
| '{' declaration_list statement_list '}' {
  asprintf(&$$, "\tpushq %%rbp\n\tmov %%rsp, %%rbp\n%s%s\tadd $%d, %%esp\n\tmov %%rbp, %%rsp\n\tpopq %%rbp\n%s", $2, $3, get_top_stack_size(ns), cur_return_statement);
  pop_name_space(ns);
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
: RETURN ';'  { $$ = ""; cur_return_statement = "\n\tret\n"; } 
| RETURN expression ';'  { $$ = ""; asprintf(&cur_return_statement, "\tmovl $%s, %%eax\n\tret\n", $2); }
;

program
: external_declaration { fprintf(output, "\t.globl %s\n\t.type %s, @function \n%s:\n%s", $1.name, $1.name, $1.name, $1.body); }
| program external_declaration { fprintf(output, "\t.globl %s\n\t.type %s, @function \n%s:\n%s", $2.name, $2.name, $2.name, $2.body); }
;

external_declaration
: function_definition { $$ = $1; };
| class_definition
| declaration
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
