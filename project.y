%code {
#include <stdio.h>
#include <glib.h>


extern int yylex (void);
void yyerror (const char *s);
}

enum SymbolType {
  INTEGER,
  FLOAT,
  STRING
};

struct Symbol {
  enum SymbolType type;
  union {
    int int_value;
    float float_value;
    char* string_value;
  } value;
};

GHashTable *symbol_table = g_hash_table_new(g_str_hash, g_str_equal);

void symbol_free(gpointer data) {
  free(data);
}

GList *symbols = NULL;
int symbol_count = 0;

%code requires {

}

%union {
   int ival;
   double fval;
   char* sval;
}

//structs for semantic values of non terminals
struct Factor {
  int type;
  union {
    int ival;
    double fval;
    char *sval;
  } value;
};

%token <reserved_word> BREAK CASE DEFAULT ELSE FLOAT IF INPUT INT OUTPUT SWITCH WHILE

%token '(' /* character literal */
%token ')' /* character literal */
%token '{' /* character literal */
%token '}' /* character literal */
%token ',' /* character literal */
%token ':' /* character literal */
%token ';' /* character literal */
%token '=' /* character literal */

%token <int> <double> NUM
%token <char*> ID

%token '<' '>' '<=' '>=' '!=' '=='
%token <op> RELOP

%token '+' '-'
%token <op> ADDOP

%token '*' '/'
%token <op> MULOP

%token '!'
%token <op> NOT

%token '||'
%token <op> OR

%token '&&'
%token <op> AND

%token 'static_cast<int>' 'static_cast<float>'
%token <op> CAST


%left MULOP
%left ADDOP
%left RELOP
%left NOT
%left AND
%left OR

/*
%nterm program
%nterm declarations
%nterm declaration
%nterm type
%nterm idlist
%nterm stmt
%nterm assignment_stmt
%nterm input_stmt
%nterm output_stmt
%nterm if_stmt
%nterm while_stmt
%nterm switch_stmt
%nterm caselist
%nterm break_stmt
%nterm stmt_block
%nterm stmtlist
%nterm boolexp
%nterm boolterm
%nterm boolfactor
%nterm expression
%nterm term
%nterm factor
*/

%type <struct Factor> factor

 
%define parse.error verbose
/* %error-verbose */

%%
program:	declarations stmt_block {
	g_hash_table_foreach(symbol_table, symbol_free, NULL);
    g_hash_table_remove_all(symbol_table);
}

declarations:	declarations declaration | epsilon

declaration:	idlist ':' type ';' {
	GList *list = symbols;
	while (list != NULL) {
		char *current = list->data;
		struct Symbol *symbol = malloc(sizeof(struct Symbol));
		symbol->type = $3;
		g_hash_table_insert(symbol_table, strdup(current), symbol);
		list = g_list_next(list);
	}
    declaration_count++;
    symbol_count = 0;
	symbols = NULL;
  }

type:	INT { $$ = INT }| FLOAT { $$ = FLOAT }

idlist:		idlist ',' ID {
    symbols = g_list_append(symbols, strdup($3));
  }

idlist:		ID {
    symbols = g_list_append(symbols, strdup($1));
  }

stmt:	assignment_stmt

stmt:	input_stmt

stmt:	output_stmt

stmt:	if_stmt

stmt:	while_stmt

stmt:	switch_stmt

stmt:	break_stmt

stmt:	stmt_block

assignment_stmt:	ID '=' expression ';'

input_stmt:		INPUT '(' ID ')' ';'

output_stmt:	OUTPUT '(' expression ')' ';'

if_stmt:	IF '(' boolexpr ')' stmt ELSE stmt

while_stmt:		WHILE '(' boolexpr ')' stmt

switch_stmt:	SWITCH '(' expression ')' '{' caselist
							DEFAULT ':' stmtlist '}'

caselist:	caselist CASE NUM ':' stmtlist | ""

break_stmt:		BREAK ';'

stmt_block:		'{' stmtlist '}'

stmtlist:	stmtlist stmt | ""

boolexpr:	boolexpr OR boolterm | boolterm

boolterm:	boolterm AND boolfactor | boolfactor

boolfactor:		NOT '(' boolexpr ')' |
					expression RELOP expression

expression:		expression ADDOP term | term

term:	term MULOP factor | factor

factor:		'(' expression ')'

factor:		CAST '(' expression ')'

factor:		ID {
  $$.type = STRING;
  $$.value.sval = $1;
}

factor:		NUM {
    if (typeof($1) == typeof(int)) {
      /* NUM is an integer */
      $$.type = INT;
      $$.value.ival = $1;
    } 
    else {
      if (typeof($1) == typeof(double)) {
        /* NUM is a float */
      $$.type = FLOAT;
      $$.value.fval = fval;
      } else {
        /* NUM is neither an integer nor a float */
      }
    }
  }


NOT:	'!' { $$ = $1 }

AND:	'&&' { $$ = $1 }

OR:		'||' { $$ = $1 }

MULOP:	'*' { $$ = $1 } | '/' { $$ = $1 }

ADDOP:	'+' { $$ = $1 } | '-' { $$ = $1 }

RELOP:	'<' { $$ = $1 } | '>' { $$ = $1 } | '<=' { $$ = $1 } | '>=' { $$ = $1 }

RELOP:	'!=' { $$ = $1 } | '==' { $$ = $1 }

CAST:	'static_cast<int>' { $$ = $1 } | 'static_cast<float>' { $$ = $1 }

		   
%%
int main (int argc, char **argv)
{
  extern FILE *yyin;
  if (argc != 2) {
     fprintf (stderr, "Usage: %s <input-file-name>\n", argv[0]);
	 return 1;
  }
  yyin = fopen (argv [1], "r");
  if (yyin == NULL) {
       fprintf (stderr, "failed to open %s\n", argv[1]);
	   return 2;
  }
#if 0

#ifdef YYDEBUG
   yydebug = 1;
#endif
#endif
  yyparse ();
  
  fclose (yyin);
  return 0;
}


void yyerror (const char *s)
{
  extern int yylineno;
  
  fprintf (stderr, "error. line %d:%s\n", yylineno,s);
}





