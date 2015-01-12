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
  int nb_label = 0;

  char *cur_return_statement = NULL;
  char *parameter_declaration_str = NULL;

  generic_list_t *declaration_list = NULL;
  generic_list_t *declarator_list = NULL;
  generic_list_t *function_list = NULL;

  char* param_regs[6] = { "%rdi", "%rsi", "%rdx", "%rcx", "r8", "r9" };
%}

%token <str> IDENTIFIER
%token <integer> ICONSTANT
%token <floating> FCONSTANT
%token INC_OP DEC_OP LE_OP GE_OP EQ_OP NE_OP
%token <basic_type> INT FLOAT VOID CLASS
%token IF ELSE WHILE RETURN FOR DO
%type <str> statement statement_list compound_statement jump_statement declaration iteration_statement selection_statement declaration_list parameter_declaration
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
    char* msg;
    asprintf(&msg, "undeclared variable '%s'", $1.name);
    yyerror(msg);
  }
  $$.type = var->type;
  if (is_function(&(var->type))) {
    $$.body = "";
    int i = 0;
    char *param_reg;
    generic_element_t *e;
    expression_t *exp;
    TAILQ_FOREACH(e, &($1.params), pointers) {
      if (i < 7) {
	param_reg = param_regs[i];
      } else {
	asprintf(&param_reg, "%d(%%rsp)", (i - 7) * 8); //a corriger avec des pushs
      }
      exp = (expression_t*)(e->data);
      asprintf(&($$.body), "%s%s\n\tpop %%rax\n\tmov %%rax, %s", $$.body, exp->body, param_reg);
    }
    //$$.reg = "%rax";
    asprintf(&($$.body), "%s\n\tcall %s\n\tpush %%rax", $$.body, $1.name); 
  } else {
    //$$.reg = "%rbx";
    if (is_pointer(&(var->type))) {
      //asprintf(&($$.body), "%s\n\tmov %s, %%ecx\n\tmov -%d(%%rbp), %%ebx\n\tadd %%ecx, %%ebx\n\tmov %s, (%%ebx)", $1.offset.body, $1.offset.reg, var->addr, $$.reg);
    } else {
      asprintf(&($$.body), "\n\tpush -%d(%%rbp)", var->addr);
    }
  }
}
| ICONSTANT {
  //$$.reg = "%rax";
  asprintf(&($$.body), "\n\tpush $%d", $1);
  }
| FCONSTANT {
  union FloatInt u;
  u.f = $1;
  //$$.reg = "%rax";
  asprintf(&($$.body), "\n\tpush $%d", u.i);
}
| '(' expression ')' { $$ = $2; }
| compound_identifier INC_OP {
  variable_t *var = is_defined($1.name, ns);
  if (var == NULL) {
    char* msg;
    asprintf(&msg, "undeclared variable '%s'", $1.name);
    yyerror(msg);
  }
  asprintf(&($$.body), "\n\tmov -%d(%%ebp), %%rax\n\tinc %%rax\n\tpush %%rax", var->addr);
}
| compound_identifier DEC_OP {
  variable_t *var = is_defined($1.name, ns);
  if (var == NULL) {
    char* msg;
    asprintf(&msg, "undeclared variable '%s'", $1.name);
    yyerror(msg);
  }
  asprintf(&($$.body), "\n\tmov -%d(%%ebp), %%rax\n\tdec %%rax\n\tpush %%rax", var->addr);
}
;

compound_identifier
: IDENTIFIER { $$.name = $1; $$.offset.body = ""; }
| IDENTIFIER '[' expression ']' {
  //marche pas
  $$.name = $1;
  $$.offset = $3;
  variable_t *var = is_defined($$.name, ns);
  if(var == NULL) {
    char* msg;
    asprintf(&msg, "undeclared variable '%s'", $1);
    yyerror(msg);
  }
  //$$.offset.reg = "%rbx";
  if (is_pointer(&(var->type))) {
    //asprintf(&($$.offset.body), "%s\n\tmul $4, %s\n\tmov %%rbx, -%d(%%rbp)\n\tadd %%rbx, %s", $3.body, $3.reg, var->addr, $3.reg);
  } else {
    //asprintf(&($$.offset.body), "%s\n\tmul $4, %s\n\tmov -%d(%%rbp), %%rbx\n\tadd %%rbx, %s", $3.body, $3.reg, var->addr, $3.reg);
  }
}
| IDENTIFIER '(' argument_expression_list ')' { $$.name = $1; $$.params = $3; }
| IDENTIFIER '(' ')' { $$.name = $1; TAILQ_INIT(&($$.params)); }
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
  asprintf(&($$.body), "%s\n\tpop %%rax\n\tnot %%rax\n\tpush %%rax", $2.body);;
}
;

multiplicative_expression
: unary_expression { $$ = $1; }
| multiplicative_expression '*' unary_expression{ 
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
  asprintf(&($$.body), "%s%s\n\tpop %%rax\n\tpop %%rbx\n\tcmp %%rbx, %%rax\n\tjl label%d\n\tpush $0\n\tjmp label%d\nlabel%d:\n\tpush $1\nlabel%d:", $1.body, $3.body, nb_label, nb_label + 1, nb_label, nb_label + 1);
  nb_label += 2;
  }
| additive_expression '>' additive_expression {
  asprintf(&($$.body), "%s%s\n\tpop %%rax\n\tpop %%rbx\n\tcmp %%rbx, %%rax\n\tjg label%d\n\tpush $0\n\tjmp label%d\nlabel%d:\n\tpush $1\nlabel%d:", $1.body, $3.body, nb_label, nb_label + 1, nb_label, nb_label + 1);
  nb_label += 2;
  }
| additive_expression LE_OP additive_expression {
  asprintf(&($$.body), "%s%s\n\tpop %%rax\n\tpop %%rbx\n\tcmp %%rbx, %%rax\n\tjle label%d\n\tpush $0\n\tjmp label%d\nlabel%d:\n\tpush $1\nlabel%d:", $1.body, $3.body, nb_label, nb_label + 1, nb_label, nb_label + 1);
  nb_label += 2;
  }
| additive_expression GE_OP additive_expression {
  asprintf(&($$.body), "%s%s\n\tpop %%rax\n\tpop %%rbx\n\tcmp %%rbx, %%rax\n\tjge label%d\n\tpush $0\n\tjmp label%d\nlabel%d:\n\tpush $1\nlabel%d:", $1.body, $3.body, nb_label, nb_label + 1, nb_label, nb_label + 1);
  nb_label += 2;
  }
| additive_expression EQ_OP additive_expression {
  asprintf(&($$.body), "%s%s\n\tpop %%rax\n\tpop %%rbx\n\tcmp %%rbx, %%rax\n\tje label%d\n\tpush $0\n\tjmp label%d\nlabel%d:\n\tpush $1\nlabel%d:", $1.body, $3.body, nb_label, nb_label + 1, nb_label, nb_label + 1);
  nb_label += 2;
  }
| additive_expression NE_OP additive_expression {
  asprintf(&($$.body), "%s%s\n\tpop %%rax\n\tpop %%rbx\n\tcmp %%rbx, %%rax\n\tjne label%d\n\tpush $0\n\tjmp label%d\nlabel%d:\n\tpush $1\nlabel%d:", $1.body, $3.body, nb_label, nb_label + 1, nb_label, nb_label + 1);
  nb_label += 2;
  }
;

expression
: compound_identifier '=' comparison_expression {
  //missing automatic cast
  variable_t *var = is_defined($1.name, ns);
  if(var == NULL) {
    char* msg;
    asprintf(&msg, "undeclared variable '%s'", $1);
    yyerror(msg);
  }
  if (strcmp($1.offset.body, "") != 0) {
    var->type.pointer = 0;
  }
  if (!are_compatible(&(var->type), &($3.type))) {
    yyerror("incompatible type assignement");
  }
  asprintf(&($$.body), "%s\n\tpop %%rax\n\tmov %%rax, -%d(%%rbp)", $3.body, var->addr);
 }
| comparison_expression { $$ = $1; }
;

declaration
: type_name declarator_list ';' {
  //printf("declaration -> type_name declarator_list;\n");
  generic_element_t *e;
  declarator_t *declarator;
  $$ = "";
  TAILQ_FOREACH(e, &$2, pointers) {
    declarator = (declarator_t*)(e->data);
    declarator->type.basic = $1;
    if (is_defined(declarator->name, ns) != NULL) {
      char *msg;
      asprintf(&msg, "variable '%s' already declared", declarator->name);
      yyerror(msg);
    }
    if (is_function(&(declarator->type))) {
      if (!current_name_space_is_root(ns)) {
	yyerror("nested function declaration");
      }
    }/* else {
      size = get_size(&(declarator->type));
      }*/
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
  $2.type.basic = $1;
}
;

statement
: compound_statement { $$ = $1; /*stack_new_name_space(ns);*/ }
| expression_statement { $$ = $1.body; }
| selection_statement { $$ = $1; }
| iteration_statement { $$ = $1; }
| jump_statement { $$ = $1; }
;

compound_statement
: '{' '}' { 
  //mettre return statement ailleurs
  //$$ = "\n\tret\n";
  $$ = "";
  //pop_name_space(ns);
  parameter_declaration_str = "";
}
| '{' statement_list '}' { 
  //asprintf(&$$, "\n\tpush %%rbp\n\tmov %%rsp, %%rbp%s%s%s\n\tleave\n\tret\n", parameter_declaration_str, $2, cur_return_statement);
  $$ = $2;
  //pop_name_space(ns);
  parameter_declaration_str = "";
}
| '{' declaration_list statement_list '}' {
  //printf("compound_statement -> { ... }\n");
  //asprintf(&$$, "\n\tpush %%rbp\n\tmov %%rsp, %%rbp%s%s%s%s\n\tleave\n\tret\n", parameter_declaration_str, $2, $3, cur_return_statement);
  asprintf(&$$, "%s%s", $2, $3);
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
: ';' { $$.body = ""; }
| expression ';' { $$ = $1; }
;

selection_statement
: IF '(' expression ')' statement {
  asprintf(&($$), "%s\n\tpop %%rax\n\tcmp $1, %%rax\n\tjne label%d\n\t%s\n\tlabel%d:", $3.body, nb_label, $5, nb_label);
  nb_label++;
 }
| IF '(' expression ')' statement ELSE statement {
  asprintf(&($$), "%s\n\tpop %%rax\n\tcmp $1, %%rax\n\tjne label%d\n\t%s\n\tjmp label%d\nlabel%d:\n\t%s\nlabel%d:", $3.body, nb_label, $5, nb_label + 1, nb_label, $7, nb_label + 1);
  nb_label += 2;
 }
;

iteration_statement
: WHILE '(' expression ')' statement {
  asprintf(&($$), "\nlabel%d:\n\t%s\n\tpop %%rax\n\tcmp $1, %%rax\n\tjne label%d%s\n\tpop %%rax\n\tcmp $1, %%rax\n\tje label%d\nlabel%d:", nb_label, $3.body, nb_label + 1, $5, nb_label, nb_label + 1);
  nb_label += 2;
 }
| FOR '(' expression_statement expression_statement expression ')' statement {
  asprintf(&($$), "%s\nlabel%d:\n\t%s\n\tpop %%rax\n\tcmp $1, %%rax\n\tjne label%d%s%s\n\tpop %%rax\n\tcmp $1, %%rax\n\tje label%d\nlabel%d:", $3.body, nb_label, $4.body, nb_label + 1, $7, $5.body, nb_label, nb_label + 1);
  nb_label += 2;
 }
| DO statement WHILE '(' expression ')' ';' {
  asprintf(&($$), "\nlabel%d:\n\t%s\n\tpop %%rax\n\tcmp $1, %%rax\n\tjne label%d%s\n\tpop %%rax\n\tcmp $1, %%rax\n\tje label%d\nlabel%d:", nb_label, $2, nb_label + 1, $5.body, nb_label, nb_label + 1);
  nb_label += 2;
 }
;

jump_statement
: RETURN ';'  { asprintf(&$$, "\n\tmov $0, %%rax\n\tleave\n\t\ret\n"); /*cur_return_statement = "";*/ /*ne marche que pour 1 return*/ }
| RETURN expression ';'  { asprintf(&$$, "%s\n\tpop %%rax\n\tleave\n\tret\n", $2.body); /*asprintf(&cur_return_statement, "%s\n\tpop %%rax", $2.body);*/ }
;

program
: external_declaration { fprintf(output, "%s", $1.body); }
| program external_declaration { fprintf(output, "%s", $2.body); }
;

external_declaration
: function_definition { 
  //printf("external_declaration -> function_definition\n");
  $$ = $1;
  if (strcmp($$.body, "") == 0) {
    asprintf(&($$.body), "\t.text\n\t.globl %s\n\t.type %s, @function \n%s:\n\tpush %%rbp\n\tmov %%rsp, %%rbp\n\tmov $0, %%rax\n\tleave\n\tret\n", $$.name, $$.name, $$.name);
    } else {
      asprintf(&($$.body), "\t.text\n\t.globl %s\n\t.type %s, @function \n%s:\n\tpush %%rbp\n\tmov %%rsp, %%rbp%s", $$.name, $$.name, $$.name, $$.body);
    }
  pop_name_space(ns);
  stack_new_name_space(ns); //problème dans première fonction rencontrée
 };
| class_definition { $$.body = ""; }
| declaration { $$.body = $1; }
;

function_definition
: type_name declarator compound_statement  {
  //printf("function_definition ->type_name declarator compound_statement\n");
  $$.type = $2.type;
  $$.type.basic = $1;
  $$.name = $2.name;
  $$.body = $3;
  insert_in_current_name_space($$.name, new_variable($$.type, 0), ns);
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
  variable_type_t type;
  type.basic = TYPE_VOID;
  type.pointer = 0;
  insert_in_current_name_space("printint", new_variable(type, 0), ns);
  insert_in_current_name_space("printfloat", new_variable(type, 0), ns);
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
