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
  char* code = NULL;
  name_space_stack_t *ns = NULL;
  class_name_space_t *cns = NULL;
  int stack_head = 0;
  char *file_name = NULL;
  char *file_output = NULL;
  FILE* output = NULL;
  FILE *input = NULL;

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
%type <str> primary_expression unary_expression multiplicative_expression additive_expression comparison_expression expression expression_statement statement statement_list compound_statement jump_statement declaration declaration_list compound_identifier
%type <basic_type> type_name
%type <declaration> declarator
%type <function> external_declaration function_definition
%union {
  enum BASIC_TYPE basic_type;
  char *str;
  int integer;
  float floating;
  declaration_t declaration;
  function_t function;
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
: IDENTIFIER { $$ = $1; }
| IDENTIFIER '[' expression ']'
| IDENTIFIER '(' argument_expression_list ')'
| IDENTIFIER '(' ')'
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
  variable_t *var = findInNameSpace($1, ns);
  asprintf(&$$, "\tmovl $%s, -%d(%%rbp)\n", $3, var->addr);
}
| compound_identifier '[' expression ']' '=' comparison_expression
| comparison_expression { $$ = $1; }
;

declaration
: type_name declarator_list ';' {
  int size;
  generic_element_t *e;
  declaration_t *declaration;
  variable_type_t *type;
  $$ = "";
  //asprintf(&code, "%s\tpushq %%rbp\n\tmov %%rsp, %%rbp\n", code);
  TAILQ_FOREACH(e, declaration_list, pointers) {
    declaration = (declaration_t*)(e->data);
    if (findInNameSpace(declaration->name, ns) != NULL) {
      yyerror("variable already declared");
    }
    type = getType($1, declaration);
    size = getSize(type);
    stack_head += size;
    insertInCurrentNameSpace(declaration->name, newVariable(type, stack_head), ns);
    asprintf(&$$, "%s\tsub $%d, %%esp\n", $$, size);
  }
  //asprintf(&code, "%s\tmov %%rbp, %%rsp\n\tpopq %%rbp\n");
  free_list(declaration_list, NULL);
  declaration_list = NULL;
 }
;

declarator_list
: declarator { 
  if (declaration_list == NULL) {
    declaration_list = new_list();
  }
  insert(declaration_list, &$1, sizeof(declaration_t)); 
}
| declarator_list ',' declarator { 
  if (declaration_list == NULL) {
    declaration_list = new_list();
  }
  insert(declaration_list, &$3, sizeof(declaration_t));
}
;

type_name
: VOID { $$ = TYPE_VOID; }
| INT { $$ = TYPE_INT; }
| FLOAT {$$ = TYPE_FLOAT; }
| CLASS IDENTIFIER { $$ = TYPE_CLASS; }
;

declarator
: IDENTIFIER  { $$.array_size = 1; $$.pointer = 0; $$.name = $1;}
| '*' IDENTIFIER { $$.array_size = 1; $$.pointer = 1; $$.name = $2; }
| IDENTIFIER '[' ICONSTANT ']' { $$.array_size = $3; $$.pointer = 0; $$.name = $1; }
| declarator '(' parameter_list ')' { $$ = $1; }
| declarator '(' ')' { $$ = $1; }
;

parameter_list
: parameter_declaration
| parameter_list ',' parameter_declaration
;

parameter_declaration
: type_name declarator
;

statement
: compound_statement { $$ = $1; }
| expression_statement
| selection_statement
| iteration_statement
| jump_statement { $$ = $1; }
;

compound_statement
: '{' '}' { $$ = ""; }
| '{' statement_list '}' { $$ = $2; }
| '{' declaration_list statement_list '}' { 
  asprintf(&$$, "%s%s", $2, $3);
  //asprintf(&$$, "\tpushq %%rbp\n\tmov %%rsp, %%rbp\n%s\tmov %%rbp, %%rsp\n\tpopq %%rbp\n%s", $2, $3);
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
: RETURN ';'  { $$ = "\tmov %%rbp, %%rsp\n\tpopq %%rbp\n\n\tret"; } 
| RETURN expression ';'  { asprintf(&$$, "\tmov %%rbp, %%rsp\n\tpopq %%rbp\n\tmovl $%s, %%eax\n\tret\n", $2); }
;

program
: external_declaration { fprintf(output, "\t.globl %s\n\t.type %s, @function \n%s:\n\tpushq %%rbp\n\tmov %%rsp, %%rbp\n%s", $1.name, $1.name, $1.name, $1.body); }
| program external_declaration { fprintf(output, "\t.globl %s\n\t.type %s, @function \n%s:\n\tpushq %%rbp\n\tmov %%rsp, %%rbp\n%s", $2.name, $2.name, $2.name, $2.body); }
;

external_declaration
: function_definition { $$ = $1; };
| class_definition
| declaration
;

function_definition
: type_name declarator compound_statement  {
  $$.type = getType($1, &$2);
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
  code = "";	    
  file_name = strdup(filename);
  file_output = strdup(filename);
  file_output[strlen(file_output)-1] = 's';
  output = fopen(file_output, "w");
  input = fopen(filename, "r");
  ns = newNameSpaceStack();
  cns = newClassNameSpace();
  function_list = new_list();
}

void freeVariables() {
  free(file_name);
  free(file_output);
  //free(code);
  free_list(function_list, free);
  freeNameSpaceStack(ns);
  freeClassNameSpace(cns);
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
    freeVariables();
  }
  else {
    fprintf (stderr, "%s: error: no input file\n", *argv);
	return 1;
  }
  return 0;
}
