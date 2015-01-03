%{
    #include <stdio.h>
    extern int yylineno;
    int yylex ();
    int yyerror ();
    char* code = NULL;
%}

%token <str> IDENTIFIER ICONSTANT FCONSTANT
%token INC_OP DEC_OP LE_OP GE_OP EQ_OP NE_OP
%token INT FLOAT VOID CLASS
%token IF ELSE WHILE RETURN FOR DO
%union {
  char *str;
}
%start program
%%

primary_expression
: compound_identifier
| ICONSTANT
| FCONSTANT
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
: primary_expression
| '-' unary_expression
| '!' unary_expression
;

multiplicative_expression
: unary_expression
| multiplicative_expression '*' unary_expression
;

additive_expression
: multiplicative_expression
| additive_expression '+' multiplicative_expression
| additive_expression '-' multiplicative_expression
;

comparison_expression
: additive_expression
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
| comparison_expression
;

declaration
: type_name declarator_list ';'
;

declarator_list
: declarator
| declarator_list ',' declarator
;

type_name
: VOID 
| INT  
| FLOAT
| CLASS IDENTIFIER
;

declarator
: IDENTIFIER  
| '*' IDENTIFIER
| IDENTIFIER '[' ICONSTANT ']'
| declarator '(' parameter_list ')'
| declarator '(' ')'
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
  char * var1 = "%%eax";
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
: type_name declarator compound_statement
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

extern char yytext[];
extern int column;
extern int yylineno;
extern FILE *yyin;

char *file_name = NULL;

int yyerror (char *s) {
    fflush (stdout);
    fprintf (stderr, "%s:%d:%d: %s\n", file_name, yylineno, column, s);
    return 0;
}


int main (int argc, char *argv[]) {
    FILE *input = NULL;
    if (argc==2) {
      asprintf(&code, "\t.globl main\n\t.type main, @function\n main:\n");
	input = fopen (argv[1], "r");
	file_name = strdup (argv[1]);
	
	if (input) {
	    yyin = input;
	    yyparse();
	 
	    
	    char * file_output = argv[1];
	    file_output[strlen(file_output)-1] = 's';
	    FILE* output = fopen(file_output, "w");
	    fprintf(output, code);
	}
	else {
	  fprintf (stderr, "%s: Could not open %s\n", *argv, argv[1]);
	    return 1;
	}
	free(file_name);
    }
    else {
	fprintf (stderr, "%s: error: no input file\n", *argv);
	return 1;
    }
    return 0;
}
