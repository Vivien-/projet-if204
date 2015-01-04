%{
  #include <stdio.h>
  #include <string.h>
  #include "variable_type.h"
  #include "name_space.h"
  extern int yylineno;
  extern int asprintf(char** strp, const char *fmt, ...);
  int yylex ();
  int yyerror ();
  char* code = NULL;
  name_space_stack_t *ns = NULL;
  class_name_space_t *cns = NULL;
  int stack_head = 0;

  declaration_list_t *declaration_list = NULL;
%}

%token <str> IDENTIFIER
%token <integer> ICONSTANT
%token <floating> FCONSTANT
%token INC_OP DEC_OP LE_OP GE_OP EQ_OP NE_OP
%token <basic_type> INT FLOAT VOID CLASS
%token IF ELSE WHILE RETURN FOR DO
%type <str> primary_expression unary_expression multiplicative_expression additive_expression comparison_expression expression
%type <basic_type> type_name
%type <declaration> declarator
%union {
  enum BASIC_TYPE basic_type;
  char *str;
  int integer;
  float floating;
  declaration_t declaration;
}
%start program
%%

primary_expression
: compound_identifier
| ICONSTANT { asprintf(&$$, "%d", $1); }
| FCONSTANT { asprintf(&$$, "%f", $1); }
| '(' expression ')'
| compound_identifier INC_OP
| compound_identifier DEC_OP
;

compound_identifier
: IDENTIFIER
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
: compound_identifier '=' comparison_expression
| compound_identifier '[' expression ']' '=' comparison_expression
| comparison_expression { $$ = $1; }
;

declaration
: type_name declarator_list ';' {
  int size;
  declaration_t *declaration;
  variable_type_t *type;
  TAILQ_FOREACH(declaration, declaration_list, pointers) {
    printf("declaring variable %s\n", declaration->name);
    if (findInNameSpace(declaration->name, ns) != NULL) { //doesn't work
      yyerror("variable already declared");
    }
    type = getType($1, declaration);
    size = getSize(type);
    stack_head += size;
    insertInCurrentNameSpace(declaration->name, newVariable(type, stack_head), ns);
    asprintf(&code, "%s\tsub $%d, %%esp\n", code, size);
  }
  freeDeclarationList(declaration_list);
  declaration_list = NULL;
 }
;

declarator_list
: declarator { 
  if (declaration_list == NULL) {
    declaration_list = newDeclarationList();
  }
  insertDeclaration(declaration_list, &$1); }
| declarator_list ',' declarator { 
  if (declaration_list == NULL) {
    declaration_list = newDeclarationList();
  }
  insertDeclaration(declaration_list, &$3); }
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
: compound_statement
| expression_statement 
| selection_statement
| iteration_statement
| jump_statement
;

compound_statement
: '{' '}'
| '{' statement_list '}'
| '{' declaration_list statement_list '}'
;

declaration_list
: declaration
| declaration_list declaration
;

statement_list
: statement
| statement_list statement
;

expression_statement
: ';'
| expression ';'
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
: RETURN ';'  { asprintf(&code, "%s\n ret", code); } 
| RETURN expression ';'  {
  char * var1 = "%eax";
  asprintf(&code, "%s\tmovl $0, %s\n\tret\n", code, var1); } 
;

program
: external_declaration
| program external_declaration
;

external_declaration
: function_definition
| class_definition
| declaration
;

function_definition
: type_name declarator compound_statement  { 
  if(strcmp($2.name, "main") == 0) { asprintf(&code,"\t.globl main\n\t.type main, @function\n main:\n%s",code);}}
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
#include "name_space.h"
#include "variable_type.h"

extern char yytext[];
extern int column;
extern int yylineno;
extern FILE *yyin;

char *file_name = NULL;
char *file_output = NULL;
FILE* output = NULL;
FILE *input = NULL;

void init(char* filename){
  code = "";	    
  file_name = strdup(filename);
  file_output = strdup(filename);
  file_output[strlen(file_output)-1] = 's';
  output = fopen(file_output, "w");
  input = fopen(filename, "r");
  ns = newNameSpaceStack();
  cns = newClassNameSpace();
}

int yyerror (char *s) {
    fflush (stdout);
    fprintf (stderr, "%s:%d:%d: %s\n", file_name, yylineno, column, s);
    return 0;
}


int main (int argc, char *argv[]) {
  if (argc==2) {
    init(argv[1]);
    if (input && output) {
      yyin = input;
      yyparse();
      fprintf(output, "%s", code);
    }
    else {
      fprintf (stderr, "%s: Could not open %s\n", *argv, argv[1]);
      return 1;
    }
    free(file_name);
    free(file_output);
    free(code);
    freeNameSpaceStack(ns);
    freeClassNameSpace(cns);
    fclose(input);
    fclose(output);
  }
  else {
    fprintf (stderr, "%s: error: no input file\n", *argv);
	return 1;
  }
  return 0;
}
