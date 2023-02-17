%code {
#include <stdio.h>
#include <glib.h>
#include "outputlist.h"

static GHashTable *symbol_table = NULL;

Line* buffer = NULL;
GList *symbols = NULL;
int symbol_count = 0;

int current_line = 0;
int temp_var_count = 0;



struct Symbol {
  int type;
  union {
    int int_value;
    float float_value;
    char* string_value;
  } value;
};


void symbol_free(gpointer key, gpointer value, gpointer userdata) {
  free(value);
}

int get_symbol_type(char* id){
  gconstpointer id_gconstpointer = (gconstpointer)id;
  gpointer symbol_id = g_hash_table_lookup(symbol_table, id_gconstpointer);
  struct Symbol *symbol = (struct Symbol*)symbol_id;
  int symbol_type = symbol->type;
  return symbol_type;
}

}

%code requires {
  #include "outputlist.h"

  enum {
    INTEGER_TYPE = 1,
    FLOAT_TYPE = 2
  } TYPE;

  typedef enum {
    ADD_TYPE = 1,
    SUB_TYPE = 2
  } ADDOPTYPE;

  typedef enum {
    MUL_TYPE = 1,
    DIV_TYPE = 2
  } MULOPTYPE;

  typedef enum {
    LT_TYPE = 1,
    GT_TYPE = 2,
    LE_TYPE = 3,
    GE_TYPE = 4,
    NEQ_TYPE = 5,
    EQ_TYPE = 6
  } RELOPTYPE;

  typedef enum {
    CAST_INT_TYPE = 1,
    CAST_FLOAT_TYPE = 2
  } CASTTYPE;

  extern int yylex (void);
  void yyerror (const char *s);
}

%union {
   int ival;
   double fval;
   char* sval;
   struct Factor {
       int type;
       char* ftext;
       union {
           int ival;
           double fval;
       } value;
   } factor_struct;
   struct Term {
       int type;
       char* ttext;
       union {
           int ival;
           double fval;
       } value;
   } term_struct;
   struct Expression {
       int type;
       char* etext;
       union {
           int ival;
           double fval;
       } value;
   } expression_struct;
}


%token BREAK CASE DEFAULT ELSE FLOAT IF INPUT INT OUTPUT SWITCH WHILE

%token <sval> NUM
%token <sval> ID


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

%type <factor_struct> factor
%type <term_struct> term
%type <expression_struct> expression
%type <ival> type
%type <ival> ADDOP
%type <ival> MULOP
%type <ival> RELOP
%type <ival> CAST

 
%define parse.error verbose
/* %error-verbose */

%%
program:	declarations stmt_block

declarations:	declarations declaration {
  symbols = g_list_reverse(symbols);
}

declarations: ""

declaration:	idlist ':' type ';' {
  int type_val;
  type_val = $3;
	GList *list = symbols;
	while (list != NULL) {
		char *current = list->data;
		struct Symbol *symbol = malloc(sizeof(struct Symbol));
		symbol->type = type_val;
		g_hash_table_insert(symbol_table, strdup(current), symbol);
		list = g_list_next(list);
	}
    //declaration_count++;
    //symbol_count = 0;
	//symbols = NULL;
}

type:	INT { $$ = INTEGER_TYPE; } | FLOAT { $$ = FLOAT_TYPE; }

idlist:		idlist ',' ID {
    symbols = g_list_prepend(symbols, strdup($3));
  }

idlist:		ID {
    symbols = g_list_prepend(symbols, strdup($1));
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

input_stmt:		INPUT '(' ID ')' ';' {
    int symbol_type = get_symbol_type($3);
    if(symbol_type == INTEGER_TYPE) {
      char* line_string;
      sprintf(line_string, "%s%s", "IINP ", $3);
      insert_line(buffer, current_line, line_string);
    }
    else {
      char* line_string;
      sprintf(line_string, "%s%s", "RINP ", $3);
      insert_line(buffer, current_line, line_string);
    }
    current_line++;
}

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

boolfactor:		NOT '(' boolexpr ')'

boolfactor: expression RELOP expression

expression:		expression ADDOP term {
  if($2 == ADD_TYPE) {
    if(($1).type == FLOAT_TYPE && ($3).type == FLOAT_TYPE) {
      $$.type = FLOAT_TYPE;
      $$.value.fval = ($1).value.fval + ($3).value.fval;
    }
    else if(($1).type == FLOAT_TYPE && ($3).type == INTEGER_TYPE) {
      $$.type = FLOAT_TYPE;
      $$.value.fval = ($1).value.fval + ($3).value.ival;
    }
    else if(($1).type == INTEGER_TYPE && ($3).type == FLOAT_TYPE) {
      $$.type = FLOAT_TYPE;
      $$.value.fval = ($1).value.ival + ($3).value.fval;
    }
    else {
      $$.type = INTEGER_TYPE;
      $$.value.fval = ($1).value.ival + ($3).value.ival;
    }
  }
  else {
    if(($1).type == FLOAT_TYPE && ($3).type == FLOAT_TYPE) {
      $$.type = FLOAT_TYPE;
      $$.value.fval = ($1).value.fval - ($3).value.fval;
    }
    else if(($1).type == FLOAT_TYPE && ($3).type == INTEGER_TYPE) {
      $$.type = FLOAT_TYPE;
      $$.value.fval = ($1).value.fval - ($3).value.ival;
    }
    else if(($1).type == INTEGER_TYPE && ($3).type == FLOAT_TYPE) {
      $$.type = FLOAT_TYPE;
      $$.value.fval = ($1).value.ival - ($3).value.fval;
    }
    else {
      $$.type = INTEGER_TYPE;
      $$.value.fval = ($1).value.ival - ($3).value.ival;
    }
  }
  sprintf($$.etext, "_t%d", temp_var_count);
  temp_var_count++;
}

expression:   term {
  if(($1).type == INTEGER_TYPE) {
    $$.type = INTEGER_TYPE;
    $$.value.ival = ($1).value.ival;
  }
  else if(($1).type == FLOAT_TYPE) {
    $$.type = FLOAT_TYPE;
    $$.value.fval = ($1).value.fval;
  }
  $$.etext = ($1).ttext;
}

term:	term MULOP factor {
  if($2 == MUL_TYPE) {
    if(($1).type == FLOAT_TYPE && ($3).type == FLOAT_TYPE) {
      $$.type = FLOAT_TYPE;
      $$.value.fval = ($1).value.fval * ($3).value.fval;
    }
    else if(($1).type == FLOAT_TYPE && ($3).type == INTEGER_TYPE) {
      $$.type = FLOAT_TYPE;
      $$.value.fval = ($1).value.fval * ($3).value.ival;
    }
    else if(($1).type == INTEGER_TYPE && ($3).type == FLOAT_TYPE) {
      $$.type = FLOAT_TYPE;
      $$.value.fval = ($1).value.ival * ($3).value.fval;
    }
    else {
      $$.type = INTEGER_TYPE;
      $$.value.fval = ($1).value.ival * ($3).value.ival;
    }
  }
  else {
    if(($1).type == FLOAT_TYPE && ($3).type == FLOAT_TYPE) {
      $$.type = FLOAT_TYPE;
      $$.value.fval = ($1).value.fval / ($3).value.fval;
    }
    else if(($1).type == FLOAT_TYPE && ($3).type == INTEGER_TYPE) {
      $$.type = FLOAT_TYPE;
      $$.value.fval = ($1).value.fval / ($3).value.ival;
    }
    else if(($1).type == INTEGER_TYPE && ($3).type == FLOAT_TYPE) {
      $$.type = FLOAT_TYPE;
      $$.value.fval = ($1).value.ival / ($3).value.fval;
    }
    else {
      $$.type = INTEGER_TYPE;
      $$.value.fval = ($1).value.ival / ($3).value.ival;
    }
  }
  sprintf($$.ttext, "_t%d", temp_var_count);
  temp_var_count++;
}

term: factor {
  if(($1).type == INTEGER_TYPE) {
    $$.type = INTEGER_TYPE;
    $$.value.ival = ($1).value.ival;
  }
  else if(($1).type == FLOAT_TYPE) {
    $$.type = FLOAT_TYPE;
    $$.value.fval = ($1).value.fval;
  }
  $$.ttext = ($1).ftext;
}

factor:		'(' expression ')' {
  if(($2).type == INTEGER_TYPE) {
    $$.type = INTEGER_TYPE;
    $$.value.ival = ($2).value.ival;
  }
  else if(($2).type == FLOAT_TYPE) {
    $$.type = FLOAT_TYPE;
    $$.value.fval = ($2).value.fval;
  }
  //TODO: check this later
  $$.ftext = ($1).etext;
}

factor:		CAST '(' expression ')' {
  sprintf($$.ftext, "_t%d", temp_var_count);
  temp_var_count++;
  if($1 == CAST_INT_TYPE) {
    $$.type = INTEGER_TYPE;
    if(($3).type == INTEGER_TYPE) {
      $$.value.ival = ($3).value.ival;
    }
    else {
      $$.value.ival = (int)($3).value.fval;
    }
    char* line_string;
    sprintf(line_string, "%s %s %s", "RTOI", $$.ftext, ($3).etext);
    insert_line(buffer, current_line, line_string);
  }
  else {
    $$.type = FLOAT_TYPE;
    if(($3).type == FLOAT_TYPE) {
      $$.value.fval = ($3).value.fval;
    }
    else {
      $$.value.fval = (double)($3).value.ival;
    }
  }
}

factor:		ID {
  struct Symbol *symbol = g_hash_table_lookup(symbol_table, $1);
  if(symbol -> type == INTEGER_TYPE) {
    $$.type = INTEGER_TYPE;
    $$.value.ival = symbol -> value.int_value;
  }
  else if(symbol -> type == FLOAT_TYPE) {
    $$.type = FLOAT_TYPE;
    $$.value.fval = symbol -> value.float_value;
  }
  $$.ftext = $1;
}

factor:		NUM {
  char* endptr;
  long int_value = strtol($1, &endptr, 10);
  if (*endptr == '\0') {
    /* NUM is an integer */
    $$.type = INTEGER_TYPE;
    $$.value.ival = int_value;
  } else {
    double float_value = strtod($1, &endptr);
    if (*endptr == '\0') {
      /* NUM is a float */
      $$.type = FLOAT_TYPE;
      $$.value.fval = float_value;
    } else {
      /* NUM is not a valid integer or float */
      yyerror("Invalid number");
    }
  }
  $$.ftext = $1;
}


/*
factor:		NUM {
  if (typeof($1) == typeof(int)) {
    $$.type = INT;
    $$.value.ival = $1;
  } 
  else {
    if (typeof($1) == typeof(double)) {
    $$.type = FLOAT;
    $$.value.fval = fval;
    } else {
    }
  }
}*/



NOT:	'!'

AND:	"&&"

OR:		"||"

MULOP:	'*' { $$ = MUL_TYPE; } | '/' { $$ = DIV_TYPE; }

ADDOP:	'+' { $$ = ADD_TYPE; } | '-' { $$ = SUB_TYPE; }

RELOP:	'<' { $$ = LT_TYPE; } | '>' { $$ = GT_TYPE; } | "<=" { $$ = LE_TYPE; } | ">=" { $$ = GE_TYPE; }

RELOP:	"!=" { $$ = NEQ_TYPE; } | "==" { $$ = EQ_TYPE; }

CAST:	"static_cast<int>" { $$ = CAST_INT_TYPE; } | "static_cast<float>" { $$ = CAST_FLOAT_TYPE; }


		   
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

  GList* labels_list = NULL;
  symbol_table = g_hash_table_new(g_str_hash, g_str_equal);
  buffer = create_buffer();

#if 0

#ifdef YYDEBUG
   yydebug = 1;
#endif
#endif
  yyparse ();

  g_hash_table_foreach(symbol_table, symbol_free, NULL);
  g_hash_table_destroy(symbol_table);
  
  fclose (yyin);
  return 0;
}


void yyerror (const char *s)
{
  extern int yylineno;
  
  fprintf (stderr, "error. line %d:%s\n", yylineno,s);
}



