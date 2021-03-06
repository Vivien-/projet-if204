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
  name_space_t *ns_glob = NULL;
  name_space_t *ns_loc = NULL;
  class_name_space_t *cns = NULL;
  char *file_name = NULL;
  char *file_output = NULL;
  FILE* output = NULL;
  FILE *input = NULL;
  int nb_label = 0;

  char *cur_return_statement = NULL;
  char *parameter_declaration_str = NULL;

  generic_list_t *declaration_list = NULL;
  generic_list_t *declarator_list = NULL;
  generic_list_t *function_list = NULL;

  char* param_regs[6] = { "%rdi", "%rsi", "%rdx", "%rcx", "%r8", "%r9" };
%}

%token <str> IDENTIFIER
%token <integer> ICONSTANT
%token <floating> FCONSTANT
%token INC_OP DEC_OP LE_OP GE_OP EQ_OP NE_OP
%token <basic_type> INT FLOAT VOID CLASS
%token IF ELSE WHILE RETURN FOR DO
%type <str> statement statement_list compound_statement jump_statement declaration iteration_statement selection_statement declaration_list
%type <basic_type> type_name
%type <declarator> declarator parameter_declaration
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
  variable_t *var = is_defined($1.name, ns_glob, ns_loc);
  if (var == NULL) {
    char* msg;
    asprintf(&msg, "undeclared variable '%s'", $1.name);
    yyerror(msg);
  }
  $$.type = var->type;
  if (strlen($1.offset.body) > 0) {
    $$.type.pointer = 0;
  }
  if (is_function(&($$.type))) {
    $$.body = "";
    int i = 0;
    generic_element_t *e;
    expression_t *exp;
    TAILQ_FOREACH(e, &($1.params), pointers) {
      exp = (expression_t*)(e->data);
      if (i < 7) {
	asprintf(&($$.body), "%s%s\n\tpop %s", $$.body, exp->body, param_regs[i]);
      } else {
	asprintf(&($$.body), "%s%s", $$.body, exp->body);
      }
      i++;
    }
    asprintf(&($$.body), "%s\n\tcall %s\n\tpush %%rax", $$.body, $1.name); 
  } else {
    if (is_pointer(&(var->type)) && !is_pointer(&($$.type))) {
      asprintf(&($$.body), "%s\n\tpop %%rax\n\tpush -%d(%%rbp, %%rax, 4)", $1.offset.body, var->addr);
    } else {
      asprintf(&($$.body), "\n\tpush -%d(%%rbp)", var->addr);
    }
  }
}
| ICONSTANT {
  asprintf(&($$.body), "\n\tpush $%d", $1);
  }
| FCONSTANT {
  union FloatInt u;
  u.f = $1;
  asprintf(&($$.body), "\n\tpush $%d", u.i);
}
| '(' expression ')' { $$ = $2; }
| compound_identifier INC_OP {
  variable_t *var = is_defined($1.name, ns_glob, ns_loc);
  if (var == NULL) {
    char* msg;
    asprintf(&msg, "undeclared variable '%s'", $1.name);
    yyerror(msg);
  }
  asprintf(&($$.body), "\n\tmov -%d(%%rbp), %%rax\n\tinc %%rax\n\tmov %%rax, -%d(%%rbp)\n\tpush %%rax", var->addr, var->addr);
}
| compound_identifier DEC_OP {
  variable_t *var = is_defined($1.name, ns_glob, ns_loc);
  if (var == NULL) {
    char* msg;
    asprintf(&msg, "undeclared variable '%s'", $1.name);
    yyerror(msg);
  }
  asprintf(&($$.body), "\n\tmov -%d(%%rbp), %%rax\n\tdec %%rax\n\tmov %%rax, -%d(%%rbp)\n\tpush %%rax", var->addr, var->addr);
}
;

compound_identifier
: IDENTIFIER { $$.name = $1; $$.offset.body = ""; }
| IDENTIFIER '[' expression ']' {
  $$.name = $1;
  $$.offset = $3;
  variable_t *var = is_defined($$.name, ns_glob, ns_loc);
  if(var == NULL) {
    char* msg;
    asprintf(&msg, "undeclared variable '%s'", $1);
    yyerror(msg);
  }
  $$.offset.body = $3.body;
}
| IDENTIFIER '(' argument_expression_list ')' { $$.name = $1; $$.params = $3; $$.offset.body = ""; }
| IDENTIFIER '(' ')' { $$.name = $1; TAILQ_INIT(&($$.params)); $$.offset.body = ""; }
| IDENTIFIER '[' expression ']' '.' compound_identifier {  }
| IDENTIFIER '(' argument_expression_list ')' '.' compound_identifier {  }
| IDENTIFIER '(' ')' '.' compound_identifier {  }
| IDENTIFIER '.' compound_identifier {  }
;

argument_expression_list
: expression { TAILQ_INIT(&$$); insert(&$$, &$1, sizeof(expression_t)); }
| argument_expression_list ',' expression { $$ = $1; insert(&$$, &$3, sizeof(expression_t)); }
;

unary_expression
: primary_expression { $$ = $1; }
| '-' unary_expression {
  asprintf(&($$.body), "%s\n\tpop %%rax\n\tmov $0, %%rbx\n\tsub %%rbx, %%rax\n\tpush %%rbx", $2.body);;
}
| '!' unary_expression {
  asprintf(&($$.body), "%s\n\tpop %%rax\n\tnot %%rax\n\tpush %%rax", $2.body);
}
;

multiplicative_expression
: unary_expression { $$ = $1; }
| multiplicative_expression '*' unary_expression {
  asprintf(&($$.body), "%s\n\t%s\n\tpop %%rax\n\tpop %%rbx\n\timul %%rax, %%rbx\n\tpush %%rbx", $1.body, $3.body);
}
;

additive_expression
: multiplicative_expression { $$ = $1; }
| additive_expression '+' multiplicative_expression { 
  asprintf(&($$.body), "%s\n\t%s\n\tpop %%rax\n\tpop %%rbx\n\tadd %%rax, %%rbx\n\tpush %%rbx", $1.body, $3.body);
}
| additive_expression '-' multiplicative_expression {
  asprintf(&($$.body), "%s\n\t%s\n\tpop %%rax\n\tpop %%rbx\n\tsub %%rax, %%rbx\n\tpush %%rbx", $1.body, $3.body);
  }
;

comparison_expression
: additive_expression { $$ = $1; }
| additive_expression '<' additive_expression {
  asprintf(&($$.body), "%s%s\n\tpop %%rax\n\tpop %%rbx\n\tcmp %%rax, %%rbx\n\tjl label%d\n\tpush $0\n\tjmp label%d\nlabel%d:\n\tpush $1\nlabel%d:", $1.body, $3.body, nb_label, nb_label + 1, nb_label, nb_label + 1);
  nb_label += 2;
  }
| additive_expression '>' additive_expression {
  asprintf(&($$.body), "%s%s\n\tpop %%rax\n\tpop %%rbx\n\tcmp %%rax, %%rbx\n\tjg label%d\n\tpush $0\n\tjmp label%d\nlabel%d:\n\tpush $1\nlabel%d:", $1.body, $3.body, nb_label, nb_label + 1, nb_label, nb_label + 1);
  nb_label += 2;
  }
| additive_expression LE_OP additive_expression {
  asprintf(&($$.body), "%s%s\n\tpop %%rax\n\tpop %%rbx\n\tcmp %%rax, %%rbx\n\tjle label%d\n\tpush $0\n\tjmp label%d\nlabel%d:\n\tpush $1\nlabel%d:", $1.body, $3.body, nb_label, nb_label + 1, nb_label, nb_label + 1);
  nb_label += 2;
  }
| additive_expression GE_OP additive_expression {
  asprintf(&($$.body), "%s%s\n\tpop %%rax\n\tpop %%rbx\n\tcmp %%rax, %%rbx\n\tjge label%d\n\tpush $0\n\tjmp label%d\nlabel%d:\n\tpush $1\nlabel%d:", $1.body, $3.body, nb_label, nb_label + 1, nb_label, nb_label + 1);
  nb_label += 2;
  }
| additive_expression EQ_OP additive_expression {
  asprintf(&($$.body), "%s%s\n\tpop %%rax\n\tpop %%rbx\n\tcmp %%rax, %%rbx\n\tje label%d\n\tpush $0\n\tjmp label%d\nlabel%d:\n\tpush $1\nlabel%d:", $1.body, $3.body, nb_label, nb_label + 1, nb_label, nb_label + 1);
  nb_label += 2;
  }
| additive_expression NE_OP additive_expression {
  asprintf(&($$.body), "%s%s\n\tpop %%rax\n\tpop %%rbx\n\tcmp %%rax, %%rbx\n\tjne label%d\n\tpush $0\n\tjmp label%d\nlabel%d:\n\tpush $1\nlabel%d:", $1.body, $3.body, nb_label, nb_label + 1, nb_label, nb_label + 1);
  nb_label += 2;
  }
;

expression
: compound_identifier '=' comparison_expression {
  //missing automatic cast
  variable_t *var = is_defined($1.name, ns_glob,  ns_loc);
  if(var == NULL) {
    char* msg;
    asprintf(&msg, "undeclared variable '%s'", $1.name);
    yyerror(msg);
  }
  $$.type = var->type;
  if (strlen($1.offset.body) > 0) {
    $$.type.pointer = 0;
  }
  if (!are_compatible(&($$.type), &($3.type))) {
    yyerror("incompatible type assignement");
  }
  if (is_pointer(&(var->type)) && !is_pointer(&($$.type))) {
    asprintf(&($$.body), "%s%s\n\tpop %%rax\n\tpop %%rbx\n\tmov %%rax, -%d(%%rbp, %%rbx, 4)\n\tpush %%rax", $1.offset.body, $3.body, var->addr);
  } else {
    asprintf(&($$.body), "%s\n\tpop %%rax\n\tmov %%rax, -%d(%%rbp)\n\tpush %%rax", $3.body, var->addr);
  }
 }
| comparison_expression { $$ = $1; }
;

declaration
: type_name declarator_list ';' {
  generic_element_t *e;
  declarator_t *declarator;
  $$ = "";
  TAILQ_FOREACH(e, &$2, pointers) {
    declarator = (declarator_t*)(e->data);
    declarator->type.basic = $1;
    if (is_defined(declarator->name, ns_glob, ns_loc) != NULL) {
      char *msg;
      asprintf(&msg, "variable '%s' already declared", declarator->name);
      yyerror(msg);
    }
    if (is_function(&(declarator->type))) {
      insert_in_name_space(declarator->name, new_variable(declarator->type, 0), ns_glob);
      free_name_space(ns_loc);
      ns_loc = new_name_space();
    } else {
      insert_in_name_space(declarator->name, new_variable(declarator->type, ns_loc->size), ns_loc);
    }
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
| FLOAT { $$ = TYPE_FLOAT; }
| CLASS IDENTIFIER { $$ = TYPE_CLASS; }
;

declarator
: IDENTIFIER  { $$.name = $1; $$.type.array_size = -1; $$.type.nb_param = -1; $$.type.pointer = 0; }
| '*' IDENTIFIER { $$.name = $2; $$.type.array_size = -1; $$.type.nb_param = -1; $$.type.pointer = 1; }
| IDENTIFIER '[' ICONSTANT ']' { $$.name = $1; $$.type.array_size = $3; $$.type.nb_param = -1; $$.type.pointer = 1; }
| declarator '(' parameter_list ')' { $$ = $1; $$.type.nb_param = nb_element(&$3); $$.type.params = $3; }
| declarator '(' ')' { $$ = $1; $$.type.nb_param = 0; }
;

parameter_list
: parameter_declaration { TAILQ_INIT(&$$); insert(&$$, &$1, sizeof(declarator_t)); }
| parameter_list ',' parameter_declaration { $$ = $1; insert(&$$, &$3, sizeof(declarator_t)); }
;

parameter_declaration
: type_name declarator {
  $$ = $2;
  $$.type.basic = $1;
  insert_in_name_space($2.name, new_variable($2.type, ns_loc->size), ns_loc);
}
;

statement
: compound_statement { $$ = $1; }
| expression_statement { $$ = $1.body; }
| selection_statement { $$ = $1; }
| iteration_statement { $$ = $1; }
| jump_statement { $$ = $1; }
;

compound_statement
: '{' '}' { $$ = ""; parameter_declaration_str = ""; }
| '{' statement_list '}' { $$ = $2; parameter_declaration_str = ""; }
| '{' declaration_list statement_list '}' { asprintf(&$$, "%s%s", $2, $3); parameter_declaration_str = ""; }
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
: ';' { $$.body = ""; }
| expression ';' { $$ = $1; }
;

selection_statement
: IF '(' expression ')' statement {
  asprintf(&($$), "%s\n\tpop %%rax\n\tcmp $1, %%rax\n\tjne label%d%s\nlabel%d:", $3.body, nb_label, $5, nb_label);
  nb_label++;
 }
| IF '(' expression ')' statement ELSE statement {
  asprintf(&($$), "%s\n\tpop %%rax\n\tcmp $1, %%rax\n\tjne label%d%s\n\tjmp label%d\nlabel%d:%s\nlabel%d:", $3.body, nb_label, $5, nb_label + 1, nb_label, $7, nb_label + 1);
  nb_label += 2;
 }
;

iteration_statement
: WHILE '(' expression ')' statement {
  asprintf(&($$), "\nlabel%d:%s\n\tpop %%rax\n\tcmp $1, %%rax\n\tjne label%d%s\n\tjmp label%d\nlabel%d:", nb_label, $3.body, nb_label + 1, $5, nb_label, nb_label + 1);
  nb_label += 2;
 }
| FOR '(' expression_statement expression_statement expression ')' statement {
  asprintf(&($$), "%s\nlabel%d:%s\n\tpop %%rax\n\tcmp $1, %%rax\n\tjne label%d%s%s\n\tjmp label%d\nlabel%d:", $3.body, nb_label, $4.body, nb_label + 1, $7, $5.body, nb_label, nb_label + 1);
  nb_label += 2;
 }
| DO statement WHILE '(' expression ')' ';' {
  asprintf(&($$), "\nlabel%d:%s%s\n\tpop %%rax\n\tcmp $1, %%rax\n\tjne label%d\n\tjmp label%d\nlabel%d:", nb_label, $2, $5.body, nb_label + 1, nb_label, nb_label + 1);
  nb_label += 2;
 }
;

jump_statement
: RETURN ';'  { asprintf(&$$, "\n\tmov $0, %%rax\n\tleave\n\t\ret\n"); }
| RETURN expression ';'  { asprintf(&$$, "%s\n\tpop %%rax\n\tleave\n\tret\n", $2.body); }
;

program
: external_declaration { fprintf(output, "%s", $1.body); }
| program external_declaration { free_name_space(ns_loc); ns_loc = new_name_space(); fprintf(output, "%s", $2.body); }
;

external_declaration
: function_definition { 
  $$ = $1;
  if (strcmp($$.body, "") == 0) {
    asprintf(&($$.body), "\t.text\n\t.globl %s\n\t.type %s, @function \n%s:\n\tpush %%rbp\n\tmov %%rsp, %%rbp\n\tmov $0, %%rax\n\tleave\n\tret\n", $$.name, $$.name, $$.name);
  } else {
    asprintf(&($$.body), "\t.text\n\t.globl %s\n\t.type %s, @function \n%s:\n\tpush %%rbp\n\tmov %%rsp, %%rbp\n\tsub $%d, %%rsp%s", $$.name, $$.name, $$.name, ns_loc->size, $$.body);
  }
  free_name_space(ns_loc);
  ns_loc = new_name_space();
 }
| class_definition { $$.body = ""; }
| declaration { $$.body = $1; }
;

function_definition
: type_name declarator compound_statement  {
  $$.type = $2.type;
  $$.type.basic = $1;
  $$.name = $2.name;
  $$.body = "";
  variable_t *param;
  generic_element_t *e;
  declarator_t *declarator;
  int i = 0;
  TAILQ_FOREACH(e, &($$.type.params), pointers) {
    declarator = (declarator_t*)(e->data);
    param = is_defined(declarator->name, NULL, ns_loc);
    if (i < 7) {
      asprintf(&($$.body), "%s\n\tmov %s, -%d(%%rbp)", $$.body, param_regs[i], param->addr);
    } else {
      asprintf(&($$.body), "%s\n\tpop -%d(%%rbp)", $$.body, param->addr);
    }
    i++;
  }
  asprintf(&($$.body), "%s%s", $$.body, $3);
  insert_in_name_space($$.name, new_variable($$.type, 0), ns_glob);
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
  ns_glob = new_name_space();
  ns_loc = new_name_space();
  variable_type_t type;
  type.basic = TYPE_VOID;
  type.pointer = 0;
  insert_in_name_space("printint", new_variable(type, 0), ns_glob);
  insert_in_name_space("printfloat", new_variable(type, 0), ns_glob);
  cns = new_class_name_space();
  function_list = new_list();
  parameter_declaration_str = "";
}

void free_variables() {
  free(file_name);
  free(file_output);
  free_list(function_list, free);
  free_name_space(ns_glob);
  free_name_space(ns_loc);
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
