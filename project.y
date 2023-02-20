%code {
#include <stdio.h>
#include <glib.h>
#include "outputlist.h"

static GHashTable *symbol_table = NULL;
GList* labels_list = NULL;

Line* buffer = NULL;
GList *symbols = NULL;
int symbol_count = 0;

int current_line = 0;
int temp_var_count = 0;
int label_count = 0;

int error_exists = 0;

char* input_file_name = NULL;



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

void fix_break_lines(gpointer data, gpointer user_data) {
  int current_line = GPOINTER_TO_INT(user_data);
  int break_line = GPOINTER_TO_INT(data);

  Element e;
  e.type = LABEL;
  e.data.l = current_line;
  set_element(buffer, break_line, 1, e);
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
   struct TextType {
    int type;
    char* vtext;
   } textype_struct;
   struct Stmt {
    GList* break_lines_list;
   } stmt_struct;
   //TODO: check if it's possible to delete the follow structs
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
   struct CaseList{
       int type;
       char* cltext;
       GList* break_lines_list;
   } caselist_struct;
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
%type <ival> IF
%type <ival> ELSE
%type <ival> WHILE
%type <ival> CASE
%type <stmt_struct> stmt assignment_stmt input_stmt output_stmt if_stmt while_stmt switch_stmt break_stmt stmt_block stmtlist
%type <sval> boolfactor
%type <sval> boolterm
%type <sval> boolexpr

%nterm <caselist_struct> caselist

 
%define parse.error verbose
/* %error-verbose */

%%
program:	declarations stmt_block {
  labels_list = g_list_reverse(labels_list);
  char* line_string;
  sprintf(line_string, "%s", "HALT");
  insert_line(buffer, current_line++, line_string);

  if(error_exists == 0){
    create_qud_file(buffer, input_file_name);
  }
}

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
{
  $$.break_lines_list = NULL;
}

stmt:	input_stmt
{
  $$.break_lines_list = NULL;
}

stmt:	output_stmt
{
  $$.break_lines_list = NULL;
}

stmt:	if_stmt
{
  $$.break_lines_list = g_list_copy(($1).break_lines_list);
}

stmt:	while_stmt
{
  $$.break_lines_list = g_list_copy(($1).break_lines_list);
}

stmt:	switch_stmt
{
  $$.break_lines_list = g_list_copy(($1).break_lines_list);
}

stmt:	break_stmt
{
  $$.break_lines_list = g_list_copy(($1).break_lines_list);
}

stmt:	stmt_block
{
  $$.break_lines_list = g_list_copy(($1).break_lines_list);
}

assignment_stmt:	ID '=' expression ';' 
{
  struct Symbol *symbol = g_hash_table_lookup(symbol_table, $1);
  int id_type;
  char* endptr;
  long expression_int_value = strtol(($3).etext, &endptr, 10);
  double expression_double_value = (double)expression_int_value;
  if(symbol -> type == INTEGER_TYPE) {
    id_type = INTEGER_TYPE;
  }
  else if(symbol -> type == FLOAT_TYPE) {
    id_type = FLOAT_TYPE;
  }
  //TODO: print errors
  if(id_type == FLOAT_TYPE && ($3).type == FLOAT_TYPE) {
      char* line_string;
      sprintf(line_string, "%s %s %s", "RASN", $1, ($3).etext);
      insert_line(buffer, current_line++, line_string);
  }
  else if(id_type == FLOAT_TYPE && ($3).type == INTEGER_TYPE) {
      char* line_string;
      sprintf(line_string, "%s %s %.3f", "RASN", $1, expression_double_value);
      insert_line(buffer, current_line++, line_string);
  }
  else if(id_type == INTEGER_TYPE && ($3).type == FLOAT_TYPE) {
    //error
    error_exists = 1;
    //print error
  }
  else {
      char* line_string;
      sprintf(line_string, "%s %s %s", "IASN", $1, ($3).etext);
      insert_line(buffer, current_line++, line_string);
  }
}

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

output_stmt:	OUTPUT '(' expression ')' ';' {
    if(($3).type == INTEGER_TYPE) {
      char* line_string;
      sprintf(line_string, "%s%s", "IPRT ", ($3).etext);
      insert_line(buffer, current_line, line_string);
    }
    else {
      char* line_string;
      sprintf(line_string, "%s%s", "RPRT ", ($3).etext);
      insert_line(buffer, current_line, line_string);
    }
    current_line++;
}

if_stmt:	IF '(' boolexpr ')'
{
  Element e1;
  Element e2;
  Element e3;
  e1.type = STRING;
  e2.type = LABEL;
  e3.type = STRING;
  sprintf(e1.data.s, "%s ", "JMPZ");
  e2.data.l = label_count;
  label_count++;
  sprintf(e3.data.s, " %s", $3);
  insert_element(buffer, current_line, 0, e1);
  insert_element(buffer, current_line, 1, e2);
  insert_element(buffer, current_line, 2, e3);
  $1 = current_line;
  current_line++;
}
stmt ELSE
{
  Element e1;
  Element e2;
  e1.type = STRING;
  e2.type = LABEL;
  sprintf(e1.data.s, "%s ", "JUMP");
  e2.data.l = label_count;
  label_count++;
  insert_element(buffer, current_line, 0, e1);
  insert_element(buffer, current_line, 1, e2);
  $7 = current_line;
  current_line++;

  Element e3;
  e3.type = LABEL;
  e3.data.l = current_line;
  set_element(buffer, $1, 1, e3);
}
stmt
{
  Element e;
  e.type = LABEL;
  e.data.l = current_line;
  set_element(buffer, $7, 1, e);
}

while_stmt:		WHILE '(' boolexpr ')'
{
  Element e1;
  Element e2;
  Element e3;
  e1.type = STRING;
  e2.type = LABEL;
  e3.type = STRING;
  sprintf(e1.data.s, "%s ", "JMPZ");
  e2.data.l = label_count;
  label_count++;
  sprintf(e3.data.s, " %s", $3);
  insert_element(buffer, current_line, 0, e1);
  insert_element(buffer, current_line, 1, e2);
  insert_element(buffer, current_line, 2, e3);
  $1 = current_line;
  current_line++;
}
stmt
{
  char* line_string;
  sprintf(line_string, "%s %d", "JUMP", $1);
  insert_line(buffer, current_line, line_string);
  current_line++;

  Element e;
  e.type = LABEL;
  e.data.l = current_line;
  set_element(buffer, $1, 1, e);

  g_list_foreach(($6).break_lines_list, fix_break_lines, GINT_TO_POINTER(current_line));
  g_list_free(($6).break_lines_list);
  $$.break_lines_list = NULL;
}

switch_stmt:	SWITCH '(' expression ')' '{' 
{
  $<caselist_struct>$.type = ($3).type;
  $<caselist_struct>$.cltext = ($3).etext;
}
caselist
DEFAULT ':' stmtlist '}' 
{
  g_list_foreach(($<caselist_struct>$).break_lines_list, fix_break_lines, GINT_TO_POINTER(current_line));
  g_list_free(($<caselist_struct>$).break_lines_list);
  $$.break_lines_list = NULL;
}

caselist:	caselist CASE NUM ':'
{
  char* temp_var_text;
  sprintf(temp_var_text, "_t%d", temp_var_count);
  temp_var_count++;
  if(($<caselist_struct>0).type == INTEGER_TYPE) {
    char* line_string;
    sprintf(line_string, "%s %s %s %s", "IEQL", temp_var_text, ($<caselist_struct>0).cltext, $3);
    insert_line(buffer, current_line++, line_string);
  }
  else if(($<caselist_struct>0).type == FLOAT_TYPE) {
    char* line_string;
    sprintf(line_string, "%s %s %s %s", "REQL", temp_var_text, ($<caselist_struct>0).cltext, $3);
    insert_line(buffer, current_line++, line_string);
  }

  Element e1;
  Element e2;
  Element e3;
  e1.type = STRING;
  e2.type = LABEL;
  e3.type = STRING;
  sprintf(e1.data.s, "%s ", "JMPZ");
  e2.data.l = label_count;
  label_count++;
  sprintf(e3.data.s, " %s", temp_var_text);
  insert_element(buffer, current_line, 0, e1);
  insert_element(buffer, current_line, 1, e2);
  insert_element(buffer, current_line, 2, e3);
  $2 = current_line;
  current_line++;
}

stmtlist

{
  Element e;
  e.type = LABEL;
  e.data.l = current_line;
  set_element(buffer, $2, 1, e);

  ($<caselist_struct>0).break_lines_list = g_list_concat(($<caselist_struct>$).break_lines_list, ($6).break_lines_list);
}

caselist: ""
{
  ($<caselist_struct>0).break_lines_list = NULL;
}

break_stmt:		BREAK ';'
{
  Element e1;
  Element e2;
  e1.type = STRING;
  e2.type = LABEL;
  sprintf(e1.data.s, "%s ", "JUMP");
  e2.data.l = label_count;
  label_count++;
  insert_element(buffer, current_line, 0, e1);
  insert_element(buffer, current_line, 1, e2);
  int* current_line_p = (int*) malloc(sizeof(int));
  *current_line_p = current_line;
  $$.break_lines_list = g_list_prepend($$.break_lines_list, GINT_TO_POINTER(*current_line_p));
  current_line++;
}

stmt_block:		'{' stmtlist '}'
{
  $$.break_lines_list = g_list_copy(($2).break_lines_list);
}

stmtlist:	stmtlist stmt
{
  $$.break_lines_list = g_list_concat(($1).break_lines_list, ($2).break_lines_list);
}

stmtlist: ""
{
  $$.break_lines_list = NULL;
}

boolexpr:	boolexpr OR boolterm {
  sprintf($$, "_t%d", temp_var_count);
  temp_var_count++;
  char* line_string;
  sprintf(line_string, "%s %s %s %s", "IADD", $$, $1, $3);
  insert_line(buffer, current_line++, line_string);
}

boolexpr: boolterm {
  $$ = $1;
}

boolterm:	boolterm AND boolfactor {
  sprintf($$, "_t%d", temp_var_count);
  temp_var_count++;
  char* line_string;
  sprintf(line_string, "%s %s %s %s", "IMLT", $$, $1, $3);
  insert_line(buffer, current_line++, line_string);
}

boolterm: boolfactor {
  $$ = $1;
}

boolfactor:		NOT '(' boolexpr ')' {
  sprintf($$, "_t%d", temp_var_count);
  temp_var_count++;
  char* line_string;
  sprintf(line_string, "%s %s %s %s", "ILSS", $$, $3, "1");
  insert_line(buffer, current_line++, line_string);
}

boolfactor: expression RELOP expression {
  sprintf($$, "_t%d", temp_var_count);
  temp_var_count++;
  char* line_string;
  char* line_string1;
  char* line_string2;
  char* line_string3;
  char* temp1;
  char* temp2;
  char* string_op1;
  char* string_op2;
  double op1;
  double op2;
  char first_char1;
  char first_char2;
  if(($1).type == INTEGER_TYPE && ($3).type == INTEGER_TYPE) {
      switch ($2) {
        case LT_TYPE:
            
            sprintf(line_string, "%s %s %s %s", "ILSS", $$, ($1).etext, ($3).etext);
            insert_line(buffer, current_line++, line_string);
            break;
        case GT_TYPE:
            sprintf(line_string, "%s %s %s %s", "IGRT", $$, ($1).etext, ($3).etext);
            insert_line(buffer, current_line++, line_string);
            break;
        case LE_TYPE:
            /*
                this case adds 3 lines.
                first checks lesser than condition
                second checks equal condition
                third calculates the sum of the results of the 2 preceding lines,
                if the result is 0 then the lesser than or equal condition result is 0
                else then the result of the lesser than or equal contidion is 1 or 2
            */
            sprintf(temp1, "_t%d", temp_var_count++);
            sprintf(temp2, "_t%d", temp_var_count++);
            sprintf(line_string1, "%s %s %s %s", "ILSS", temp1, ($1).etext, ($3).etext);
            sprintf(line_string2, "%s %s %s %s", "IEQL", temp2, ($1).etext, ($3).etext);
            sprintf(line_string3, "%s %s %s %s", "IADD", $$, temp1, temp2);
            insert_line(buffer, current_line++, line_string1);
            insert_line(buffer, current_line++, line_string2);
            insert_line(buffer, current_line++, line_string3);
            break;
        case GE_TYPE:
            /*
                this case adds 3 lines.
                first checks greater than condition
                second checks equal condition
                third calculates the sum of the results of the 2 preceding lines,
                if the result is 0 then the greater than or equal condition result is 0
                else then the result of the greater than or equal contidion is 1 or 2
            */
            sprintf(temp1, "_t%d", temp_var_count++);
            sprintf(temp2, "_t%d", temp_var_count++);
            sprintf(line_string1, "%s %s %s %s", "IGRT", temp1, ($1).etext, ($3).etext);
            sprintf(line_string2, "%s %s %s %s", "IEQL", temp2, ($1).etext, ($3).etext);
            sprintf(line_string3, "%s %s %s %s", "IADD", $$, temp1, temp2);
            insert_line(buffer, current_line++, line_string1);
            insert_line(buffer, current_line++, line_string2);
            insert_line(buffer, current_line++, line_string3);
            break;
        case NEQ_TYPE:
            sprintf(line_string, "%s %s %s %s", "INQL", $$, ($1).etext, ($3).etext);
            insert_line(buffer, current_line++, line_string);
            break;
        case EQ_TYPE:
            sprintf(line_string, "%s %s %s %s", "IEQL", $$, ($1).etext, ($3).etext);
            insert_line(buffer, current_line++, line_string);
            break;
        default:
            //TODO: print error properly
            printf("Invalid RELOP");
      }
    }
    else {
      if(($1).type == FLOAT_TYPE && ($3).type == FLOAT_TYPE) {
        op1 =($1).value.fval;
        op2 = ($3).value.fval;
      }
      else if(($1).type == FLOAT_TYPE && ($3).type == INTEGER_TYPE) {
        op1 =($1).value.fval;
        op2 = (double)(($3).value.ival);
      }
      else if(($1).type == INTEGER_TYPE && ($3).type == FLOAT_TYPE) {
        op1 = (double)(($1).value.ival);
        op2 = ($3).value.fval;
      }
      //check if the expression are not variables
      first_char1 = ($1).etext[0];
      first_char2 = ($3).etext[0];
      if(first_char1 == '0' || first_char1 == '1' || first_char1 == '2' || first_char1 == '3'
          || first_char1 == '4' || first_char1 == '5' || first_char1 == '6'
          || first_char1 == '7' || first_char1 == '8' || first_char1 == '9') {
            sprintf(string_op1, "%.3f", op1);
          }
      else {
        string_op1 = ($1).etext;
      }
      if(first_char2 == '0' || first_char2 == '1' || first_char2 == '2' || first_char2 == '3'
          || first_char2 == '4' || first_char2 == '5' || first_char2 == '6'
          || first_char2 == '7' || first_char2 == '8' || first_char2 == '9') {
            sprintf(string_op2, "%.3f", op2);
          }
      else {
        string_op2 = ($3).etext;
      }
      switch ($2) {
        case LT_TYPE:
            sprintf(line_string, "%s %s %s %s", "ILSS", $$, string_op1, string_op2);
            insert_line(buffer, current_line++, line_string);
            break;
        case GT_TYPE:
            sprintf(line_string, "%s %s %s %s", "IGRT", $$, string_op1, string_op2);
            insert_line(buffer, current_line++, line_string);
            break;
        case LE_TYPE:
            /*
                this case adds 3 lines.
                first checks lesser than condition
                second checks equal condition
                third calculates the sum of the results of the 2 preceding lines,
                if the result is 0 then the lesser than or equal condition result is 0
                else then the result of the lesser than or equal contidion is 1 or 2
            */
            sprintf(temp1, "_t%d", temp_var_count++);
            sprintf(temp2, "_t%d", temp_var_count++);
            sprintf(line_string1, "%s %s %s %s", "ILSS", temp1, string_op1, string_op2);
            sprintf(line_string2, "%s %s %s %s", "IEQL", temp2, string_op1, string_op2);
            sprintf(line_string3, "%s %s %s %s", "IADD", $$, temp1, temp2);
            insert_line(buffer, current_line++, line_string1);
            insert_line(buffer, current_line++, line_string2);
            insert_line(buffer, current_line++, line_string3);
            break;
        case GE_TYPE:
            /*
                this case adds 3 lines.
                first checks greater than condition
                second checks equal condition
                third calculates the sum of the results of the 2 preceding lines,
                if the result is 0 then the greater than or equal condition result is 0
                else then the result of the greater than or equal contidion is 1 or 2
            */
            sprintf(temp1, "_t%d", temp_var_count++);
            sprintf(temp2, "_t%d", temp_var_count++);
            sprintf(line_string1, "%s %s %s %s", "IGRT", temp1, string_op1, string_op2);
            sprintf(line_string2, "%s %s %s %s", "IEQL", temp2, string_op1, string_op2);
            sprintf(line_string3, "%s %s %s %s", "IADD", $$, temp1, temp2);
            insert_line(buffer, current_line++, line_string1);
            insert_line(buffer, current_line++, line_string2);
            insert_line(buffer, current_line++, line_string3);
            break;
        case NEQ_TYPE:
            sprintf(line_string, "%s %s %s %s", "INQL", $$, string_op1, string_op2);
            insert_line(buffer, current_line++, line_string);
            break;
        case EQ_TYPE:
            sprintf(line_string, "%s %s %s %s", "IEQL", $$, string_op1, string_op2);
            insert_line(buffer, current_line++, line_string);
            break;
        default:
            //TODO: print error properly
            printf("Invalid RELOP");
      }
    }
  }


expression:		expression ADDOP term {
  sprintf($$.etext, "_t%d", temp_var_count);
  temp_var_count++;
  if($2 == ADD_TYPE) {
    //determine type
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
    //generate output
    //case IADD
    if(($1).type == INTEGER_TYPE && ($3).type == INTEGER_TYPE) {
      char* line_string;
      sprintf(line_string, "%s %s %s %s", "IADD", $$.etext, ($1).etext, ($3).ttext);
      insert_line(buffer, current_line++, line_string);
    }
    //case RADD
    else {
      char* line_string;
      sprintf(line_string, "%s %s %s %s", "RADD", $$.etext, ($1).etext, ($3).ttext);
      insert_line(buffer, current_line++, line_string);
    }
  }
  else {
    //determine type
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
    //generate output
    //case ISUB
    if(($1).type == INTEGER_TYPE && ($3).type == INTEGER_TYPE) {
      char* line_string;
      sprintf(line_string, "%s %s %s %s", "ISUB", $$.etext, ($1).etext, ($3).ttext);
      insert_line(buffer, current_line++, line_string);
    }
    //case RSUB
    else {
      char* line_string;
      sprintf(line_string, "%s %s %s %s", "RSUB", $$.etext, ($1).etext, ($3).ttext);
      insert_line(buffer, current_line++, line_string);
    }
  }
}

expression:   term {
  $$.etext = ($1).ttext;
  if(($1).type == INTEGER_TYPE) {
    $$.type = INTEGER_TYPE;
    $$.value.ival = ($1).value.ival;
  }
  else if(($1).type == FLOAT_TYPE) {
    $$.type = FLOAT_TYPE;
    $$.value.fval = ($1).value.fval;
  }
}

term:	term MULOP factor {
  sprintf($$.ttext, "_t%d", temp_var_count);
  temp_var_count++;
  if($2 == MUL_TYPE) {
    //determine type
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
    //generate output
    //case IMLT
    if(($1).type == INTEGER_TYPE && ($3).type == INTEGER_TYPE) {
      char* line_string;
      sprintf(line_string, "%s %s %s %s", "IMLT", $$.ttext, ($1).ttext, ($3).ftext);
      insert_line(buffer, current_line++, line_string);
    }
    //case RMLT
    else {
      char* line_string;
      sprintf(line_string, "%s %s %s %s", "RMLT", $$.ttext, ($1).ttext, ($3).ftext);
      insert_line(buffer, current_line++, line_string);
    }
  }
  else {
    //determine type
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
    //generate output
    //case IDIV
    if(($1).type == INTEGER_TYPE && ($3).type == INTEGER_TYPE) {
      char* line_string;
      sprintf(line_string, "%s %s %s %s", "IDIV", $$.ttext, ($1).ttext, ($3).ftext);
      insert_line(buffer, current_line++, line_string);
    }
    //case RDIV
    else {
      char* line_string;
      sprintf(line_string, "%s %s %s %s", "RDIV", $$.ttext, ($1).ttext, ($3).ftext);
      insert_line(buffer, current_line++, line_string);
    }
  }
}

term: factor {
  $$.ttext = ($1).ftext;
  if(($1).type == INTEGER_TYPE) {
    $$.type = INTEGER_TYPE;
    $$.value.ival = ($1).value.ival;
  }
  else if(($1).type == FLOAT_TYPE) {
    $$.type = FLOAT_TYPE;
    $$.value.fval = ($1).value.fval;
  }
}

factor:		'(' expression ')' {
  //TODO: check this later
  $$.ftext = ($2).etext;
  if(($2).type == INTEGER_TYPE) {
    $$.type = INTEGER_TYPE;
    $$.value.ival = ($2).value.ival;
  }
  else if(($2).type == FLOAT_TYPE) {
    $$.type = FLOAT_TYPE;
    $$.value.fval = ($2).value.fval;
  }
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
    insert_line(buffer, current_line++, line_string);
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

  symbol_table = g_hash_table_new(g_str_hash, g_str_equal);
  buffer = create_buffer();
  sprintf(input_file_name, "%s", argv[0]);

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



