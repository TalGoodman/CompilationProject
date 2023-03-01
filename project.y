%code {
#include <stdio.h>
#include <glib.h>
#include "outputlist.h"


GHashTable *symbol_table = NULL;  //holds the symbols and their types

Line* buffer = NULL;  //holds the strings of the generated code
GList *symbols = NULL;  //a temporary list for the symbols
GList* current_break_lines_list;   //saves pointer to break_lines_list in order to allow memory free in case of an error

int current_line = 0;   //the current line of the generated code
int temp_var_count = 0;
int label_count = 0;

GString* input_file_name;


void fix_break_lines(gpointer data, gpointer user_data) {
  int line = GPOINTER_TO_INT(user_data);
  int break_line = GPOINTER_TO_INT(data);

  GString* e;
  e = g_string_new(NULL);
  g_string_append_printf(e, "%d", line);
  set_element(buffer, break_line, 1, e);
  g_string_free(e, TRUE);
}

int get_symbol_type(char* id){
  gconstpointer id_gconstpointer = (gconstpointer)id;
  gint* symbol_type_ptr = g_hash_table_lookup(symbol_table, id_gconstpointer);
  if(symbol_type_ptr == NULL) {
    return NO_TYPE;
  }
  int symbol_type = GPOINTER_TO_INT(symbol_type_ptr);
  return symbol_type;
}


}

%code requires {
  #include "outputlist.h"

  enum {
    INTEGER_TYPE = 1,
    FLOAT_TYPE = 2,
    NO_TYPE = 3
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
   GString* gsval;
   struct TextType {
    int type;
    GString* vtext;
   } textype_struct;
   struct Stmt {
    GList* break_lines_list;
   } stmt_struct;
   struct CaseList{
       int type;
       GString* cltext;
       //GList* break_lines_list;
   } caselist_struct;
   struct WhileStruct{
       int jmpz;
       int jump;
   } while_struct;
}


%token BREAK CASE DEFAULT ELSE FLOAT IF INPUT INT OUTPUT SWITCH WHILE

%token <sval> NUM
%token <sval> ID
%token <sval> LEXICAL_ERROR

%token <ival> ADDOP
%token <ival> MULOP
%token <ival> RELOP
%token <ival> CAST

%token '(' /* character literal */
%token ')' /* character literal */
%token '{' /* character literal */
%token '}' /* character literal */
%token ',' /* character literal */
%token ';' /* character literal */
%token ':' /* character literal */
%token '=' /* character literal */
%token '!' /* character literal */
%token '*' /* character literal */
%token '/' /* character literal */
%token '+' /* character literal */
%token '-' /* character literal */


%token NOT
%token OR
%token AND



%nterm declarations
%nterm declaration

%type <textype_struct> factor
%type <textype_struct> term
%type <textype_struct> expression
%type <ival> type
%type <ival> IF
%type <ival> ELSE
%type <while_struct> WHILE
%type <ival> CASE
%type <stmt_struct> stmt assignment_stmt input_stmt output_stmt if_stmt while_stmt switch_stmt break_stmt stmt_block stmtlist caselist
%type <gsval> boolfactor
%type <gsval> boolterm
%type <gsval> boolexpr



 
%define parse.error verbose
/* %error-verbose */

%%
program:	declarations stmt_block {
  GString* line_string = g_string_new(NULL);
  g_string_append_printf(line_string, "%s", "HALT");
  insert_line(buffer, current_line++, line_string);
  GString* sign_string = g_string_new("TAL GOODMAN");
  insert_line(buffer, current_line++, sign_string);
  g_string_free(line_string, TRUE);
  g_string_free(sign_string, TRUE);

  if(error_exists == 0){
    create_qud_file(buffer, input_file_name);
  }
  delete_buffer(buffer);
};

declarations:	declarations declaration ;

declarations: ;

declaration:	idlist ':' type ';' {
  int type_val;
  type_val = $3;
	GList *list = symbols;
	while (list != NULL) {
    char* current = strdup(list->data);
		g_hash_table_insert(symbol_table, current, GINT_TO_POINTER(type_val));
		list = g_list_next(list);
	}
  g_list_free_full(symbols, free);
	symbols = NULL;
};

type:	INT { $$ = INTEGER_TYPE; }; | FLOAT { $$ = FLOAT_TYPE; };

idlist:		idlist ',' ID {
    symbols = g_list_prepend(symbols, strdup($3));
    free($3);
  };

idlist:		ID {
    symbols = g_list_prepend(symbols, strdup($1));
    free($1);
  };

stmt:	assignment_stmt
{
  $$.break_lines_list = NULL;
  current_break_lines_list = $$.break_lines_list;
};

stmt:	input_stmt
{
  $$.break_lines_list = NULL;
  current_break_lines_list = $$.break_lines_list;
};

stmt:	output_stmt
{
  $$.break_lines_list = NULL;
  current_break_lines_list = $$.break_lines_list;
};

stmt:	if_stmt
{
  $$.break_lines_list = ($1).break_lines_list;
  current_break_lines_list = $$.break_lines_list;
};

stmt:	while_stmt
{
  $$.break_lines_list = ($1).break_lines_list;
  current_break_lines_list = $$.break_lines_list;
};

stmt:	switch_stmt
{
  $$.break_lines_list = ($1).break_lines_list;
  current_break_lines_list = $$.break_lines_list;
};

stmt:	break_stmt
{
  $$.break_lines_list = ($1).break_lines_list;
  current_break_lines_list = $$.break_lines_list;
};

stmt:	stmt_block
{
  $$.break_lines_list = ($1).break_lines_list;
  current_break_lines_list = $$.break_lines_list;
};

assignment_stmt:	ID '=' expression ';' 
{
  int symbol_type = get_symbol_type($1);
  if (symbol_type == NO_TYPE) {
    extern int yylineno;
    fprintf(stderr, "error. line %d: semantic error, undeclared variable %s\n", yylineno, $1);
    error_exists = 1;
  }
  if(symbol_type == FLOAT_TYPE && ($3).type == FLOAT_TYPE) {
      GString* line_string = g_string_new(NULL);
      g_string_append_printf(line_string, "%s %s %s", "RASN", $1, ($3).vtext->str);
      insert_line(buffer, current_line++, line_string);
      g_string_free(line_string, TRUE);
  }
  else if(symbol_type == FLOAT_TYPE && ($3).type == INTEGER_TYPE) {
      GString* t = g_string_new(NULL);
      g_string_append_printf(t, "_t%d", temp_var_count++);
      GString* line_string1 = g_string_new(NULL);
      g_string_append_printf(line_string1, "%s %s %s", "ITOR", t->str, ($3).vtext->str);
      insert_line(buffer, current_line++, line_string1);
      GString* line_string2 = g_string_new(NULL);
      g_string_append_printf(line_string2, "%s %s %s", "RASN", $1, t->str);
      insert_line(buffer, current_line++, line_string2);
      g_string_free(line_string1, TRUE);
      g_string_free(line_string2, TRUE);
      g_string_free(t, TRUE);
  }
  else if(symbol_type == INTEGER_TYPE && ($3).type == FLOAT_TYPE) {
    extern int yylineno;
    fprintf(stderr, "error. line %d: types int and float are not compatible\n", yylineno);
    error_exists = 1;
  }
  else if(symbol_type == INTEGER_TYPE && ($3).type == INTEGER_TYPE) {
      GString* line_string = g_string_new(NULL);
      g_string_append_printf(line_string, "%s %s %s", "IASN", $1, ($3).vtext->str);
      insert_line(buffer, current_line++, line_string);
      g_string_free(line_string, TRUE);
  }

  g_string_free(($3).vtext, TRUE);
  free($1);
};

input_stmt:		INPUT '(' ID ')' ';' {
    int symbol_type = get_symbol_type($3);
    if(symbol_type == INTEGER_TYPE) {
      GString* line_string = g_string_new(NULL);
      g_string_append_printf(line_string, "%s%s", "IINP ", $3);
      insert_line(buffer, current_line, line_string);
      g_string_free(line_string, TRUE);
    }
    else if(symbol_type == FLOAT_TYPE) {
      GString* line_string = g_string_new(NULL);
      g_string_append_printf(line_string, "%s%s", "RINP ", $3);
      insert_line(buffer, current_line, line_string);
      g_string_free(line_string, TRUE);
    }
    else {
      extern int yylineno;
      fprintf(stderr, "error. line %d: semantic error, undeclared variable %s\n", yylineno, $3);
      error_exists = 1;
    }
    current_line++;
    free($3);
};

output_stmt:	OUTPUT '(' expression ')' ';' {
    if(($3).type == INTEGER_TYPE) {
      GString* line_string = g_string_new(NULL);
      g_string_append_printf(line_string, "%s%s", "IPRT ", ($3).vtext->str);
      buffer = insert_line(buffer, current_line, line_string);
      g_string_free(line_string, TRUE);
    }
    else {
      GString* line_string = g_string_new(NULL);
      g_string_append_printf(line_string, "%s%s", "RPRT ", ($3).vtext->str);
      buffer = insert_line(buffer, current_line, line_string);
      g_string_free(line_string, TRUE);
    }
    current_line++;

    g_string_free(($3).vtext, TRUE);
};

if_stmt:	IF '(' boolexpr ')'
{
  GString* e1;
  GString* e2;
  GString* e3;
  e1 = g_string_new(NULL);
  e2 = g_string_new(NULL);
  e3 = g_string_new(NULL);
  g_string_append_printf(e1, "%s ", "JMPZ");
  g_string_append_printf(e2, "%d ", label_count);
  label_count++;
  g_string_append_printf(e3, "%s", $3->str);
  buffer = insert_element(buffer, current_line, 0, e1);
  buffer = insert_element(buffer, current_line, 1, e2);
  buffer = insert_element(buffer, current_line, 2, e3);
  g_string_free(e1, TRUE);
  g_string_free(e2, TRUE);
  g_string_free(e3, TRUE);
  g_string_free($3, TRUE);
  $1 = current_line;
  current_line++;
}
stmt ELSE
{
  GString* e1;
  GString* e2;
  e1 = g_string_new(NULL);
  e2 = g_string_new(NULL);
  g_string_append_printf(e1, "%s ", "JUMP");
  g_string_append_printf(e2, "%d ", label_count);
  label_count++;
  buffer = insert_element(buffer, current_line, 0, e1);
  buffer = insert_element(buffer, current_line, 1, e2);
  g_string_free(e1, TRUE);
  g_string_free(e2, TRUE);
  $7 = current_line;
  current_line++;

  GString* e3;
  e3 = g_string_new(NULL);
  g_string_append_printf(e3, "%d ", current_line + 1);
  set_element(buffer, $1, 1, e3);
  g_string_free(e3, TRUE);
}
stmt
{
  GString* e;
  e = g_string_new(NULL);
  g_string_append_printf(e, "%d ", current_line + 1);
  set_element(buffer, $7, 1, e);
  g_string_free(e, TRUE);

  $$.break_lines_list = g_list_concat(($6).break_lines_list, ($9).break_lines_list);
  current_break_lines_list = $$.break_lines_list;
};

while_stmt:   WHILE { ($1).jump = current_line + 1; } '(' boolexpr ')'
{
  GString* e1;
  GString* e2;
  GString* e3;
  e1 = g_string_new(NULL);
  e2 = g_string_new(NULL);
  e3 = g_string_new(NULL);
  g_string_append_printf(e1, "%s ", "JMPZ");
  g_string_append_printf(e2, "%d ", label_count);
  label_count++;
  g_string_append_printf(e3, "%s", $4->str);
  insert_element(buffer, current_line, 0, e1);
  insert_element(buffer, current_line, 1, e2);
  insert_element(buffer, current_line, 2, e3);
  ($1).jmpz = current_line;
  g_string_free(e1, TRUE);
  g_string_free(e2, TRUE);
  g_string_free(e3, TRUE);
  current_line++;
  g_string_free($4, TRUE);
}
stmt
{
  GString* line_string = g_string_new(NULL);
  g_string_append_printf(line_string, "%s %d", "JUMP", ($1).jump);
  insert_line(buffer, current_line, line_string);
  g_string_free(line_string, TRUE);
  current_line++;

  GString* e;
  e = g_string_new(NULL);
  g_string_append_printf(e, "%d ", current_line + 1);
  set_element(buffer, ($1).jmpz, 1, e);
  g_string_free(e, TRUE);

  g_list_foreach(($7).break_lines_list, fix_break_lines, GINT_TO_POINTER(current_line + 1));
  g_list_free(($7).break_lines_list);
  $$.break_lines_list = NULL;
  current_break_lines_list = $$.break_lines_list;
};

switch_stmt:	SWITCH '(' expression ')' '{' 
{
  $<caselist_struct>$.type = ($3).type;
  $<caselist_struct>$.cltext = g_string_new(($3).vtext->str);
  g_string_free(($3).vtext, TRUE);
}
caselist
DEFAULT ':' stmtlist '}' 
{
  GList* temp_break_lines_list = g_list_concat(($7).break_lines_list, ($10).break_lines_list);
  g_list_foreach(temp_break_lines_list, fix_break_lines, GINT_TO_POINTER(current_line + 1));
  g_list_free(temp_break_lines_list);
  $$.break_lines_list = NULL;
  current_break_lines_list = $$.break_lines_list;
};

caselist:	caselist CASE NUM ':'
{
  GString* temp_var_text = g_string_new(NULL);
  g_string_append_printf(temp_var_text, "_t%d", temp_var_count);
  temp_var_count++;
  if(($<caselist_struct>0).type == INTEGER_TYPE) {
    GString* line_string = g_string_new(NULL);
    g_string_append_printf(line_string, "%s %s %s %s", "IEQL", temp_var_text->str, ($<caselist_struct>0).cltext->str, $3);
    insert_line(buffer, current_line++, line_string);
    g_string_free(line_string, TRUE);
  }
  else if(($<caselist_struct>0).type == FLOAT_TYPE) {
    GString* line_string = g_string_new(NULL);
    g_string_append_printf(line_string, "%s %s %s %s", "REQL", temp_var_text->str, ($<caselist_struct>0).cltext->str, $3);
    insert_line(buffer, current_line++, line_string);
    g_string_free(line_string, TRUE);
  }

  g_string_free(($<caselist_struct>0).cltext, TRUE);
  GString* e1;
  GString* e2;
  GString* e3;
  e1 = g_string_new(NULL);
  e2 = g_string_new(NULL);
  e3 = g_string_new(NULL);
  g_string_append_printf(e1, "%s ", "JMPZ");
  g_string_append_printf(e2, "%d ", label_count);
  label_count++;
  g_string_append_printf(e3, "%s", temp_var_text->str);
  insert_element(buffer, current_line, 0, e1);
  insert_element(buffer, current_line, 1, e2);
  insert_element(buffer, current_line, 2, e3);
  g_string_free(e1, TRUE);
  g_string_free(e2, TRUE);
  g_string_free(e3, TRUE);
  g_string_free(temp_var_text, TRUE);
  $2 = current_line;
  current_line++;
}

stmtlist

{
  GString* e;
  e = g_string_new(NULL);
  g_string_append_printf(e, "%d ", current_line + 1);
  set_element(buffer, $2, 1, e);
  g_string_free(e, TRUE);

  ($$).break_lines_list = g_list_concat(($1).break_lines_list, ($6).break_lines_list);
  current_break_lines_list = $$.break_lines_list;
  free($3);
};

caselist: 
{
  ($$).break_lines_list = NULL;
  current_break_lines_list = $$.break_lines_list;
};

break_stmt:		BREAK ';'
{
  GString* e1;
  GString* e2;
  e1 = g_string_new(NULL);
  e2 = g_string_new(NULL);
  g_string_append_printf(e1, "%s ", "JUMP");
  g_string_append_printf(e2, "%d ", label_count);
  label_count++;
  insert_element(buffer, current_line, 0, e1);
  insert_element(buffer, current_line, 1, e2);
  $$.break_lines_list = NULL;
  $$.break_lines_list = g_list_prepend($$.break_lines_list, GINT_TO_POINTER(current_line));
  current_break_lines_list = $$.break_lines_list;
  current_line++;
  g_string_free(e1, TRUE);
  g_string_free(e2, TRUE);
};

stmt_block:		'{' stmtlist '}'
{
  $$.break_lines_list = ($2).break_lines_list;
  current_break_lines_list = $$.break_lines_list;
};

stmtlist:	stmtlist stmt
{
  $$.break_lines_list = g_list_concat(($1).break_lines_list, ($2).break_lines_list);
  current_break_lines_list = $$.break_lines_list;
};

stmtlist: 
{
  $$.break_lines_list = NULL;
  current_break_lines_list = $$.break_lines_list;
};

boolexpr:	boolexpr OR boolterm {
  $$ = g_string_new(NULL);
  g_string_append_printf($$, "_t%d", temp_var_count);
  temp_var_count++;
  GString* line_string = g_string_new(NULL);
  g_string_append_printf(line_string, "%s %s %s %s", "IADD", $$->str, $1->str, $3->str);
  insert_line(buffer, current_line++, line_string);
  g_string_free(line_string, TRUE);
  g_string_free($1, TRUE);
  g_string_free($3, TRUE);
};

boolexpr: boolterm {
  $$ = $1;
};

boolterm:	boolterm AND boolfactor {
  $$ = g_string_new(NULL);
  g_string_append_printf($$, "_t%d", temp_var_count);
  temp_var_count++;
  GString* line_string = g_string_new(NULL);
  g_string_append_printf(line_string, "%s %s %s %s", "IMLT", $$->str, $1->str, $3->str);
  insert_line(buffer, current_line, line_string);
  current_line++;
  g_string_free(line_string, TRUE);
  g_string_free($1, TRUE);
  g_string_free($3, TRUE);
};

boolterm: boolfactor {
  $$ = $1;
};

boolfactor:		NOT '(' boolexpr ')' {
  $$ = g_string_new(NULL);
  g_string_append_printf($$, "_t%d", temp_var_count);
  temp_var_count++;
  GString* line_string = g_string_new(NULL);
  g_string_append_printf(line_string, "%s %s %s %s", "ILSS", $$->str, "1", $3->str);
  insert_line(buffer, current_line, line_string);
  current_line++;
  g_string_free(line_string, TRUE);
  g_string_free($3, TRUE);
};

boolfactor: expression RELOP expression {
  $$ = g_string_new(NULL);
  g_string_append_printf($$, "_t%d", temp_var_count);
  temp_var_count++;
  GString* line_string = g_string_new(NULL);
  GString* line_string1 = g_string_new(NULL);
  GString* line_string2 = g_string_new(NULL);
  GString* line_string3 = g_string_new(NULL);
  GString* temp1 = g_string_new(NULL);
  GString* temp2 = g_string_new(NULL);
  GString* string_op1 = g_string_new(NULL);
  GString* string_op2 = g_string_new(NULL);
  if(($1).type == INTEGER_TYPE && ($3).type == INTEGER_TYPE) {
      switch ($2) {
        case LT_TYPE:
            
            g_string_append_printf(line_string, "%s %s %s %s", "ILSS", $$->str, ($1).vtext->str, ($3).vtext->str);
            insert_line(buffer, current_line, line_string);
            current_line++;
            break;
        case GT_TYPE:
            g_string_append_printf(line_string, "%s %s %s %s", "IGRT", $$->str, ($1).vtext->str, ($3).vtext->str);
            insert_line(buffer, current_line, line_string);
            current_line++;
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
            g_string_append_printf(temp1, "_t%d", temp_var_count++);
            g_string_append_printf(temp2, "_t%d", temp_var_count++);
            g_string_append_printf(line_string1, "%s %s %s %s", "ILSS", temp1->str, ($1).vtext->str, ($3).vtext->str);
            g_string_append_printf(line_string2, "%s %s %s %s", "IEQL", temp2->str, ($1).vtext->str, ($3).vtext->str);
            g_string_append_printf(line_string3, "%s %s %s %s", "IADD", $$->str, temp1->str, temp2->str);
            insert_line(buffer, current_line, line_string1);
            current_line++;
            insert_line(buffer, current_line, line_string2);
            current_line++;
            insert_line(buffer, current_line, line_string3);
            current_line++;
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
            g_string_append_printf(temp1, "_t%d", temp_var_count++);
            g_string_append_printf(temp2, "_t%d", temp_var_count++);
            g_string_append_printf(line_string1, "%s %s %s %s", "IGRT", temp1->str, ($1).vtext->str, ($3).vtext->str);
            g_string_append_printf(line_string2, "%s %s %s %s", "IEQL", temp2->str, ($1).vtext->str, ($3).vtext->str);
            g_string_append_printf(line_string3, "%s %s %s %s", "IADD", $$->str, temp1->str, temp2->str);
            insert_line(buffer, current_line, line_string1);
            current_line++;
            insert_line(buffer, current_line, line_string2);
            current_line++;
            insert_line(buffer, current_line, line_string3);
            current_line++;
            break;
        case NEQ_TYPE:
            g_string_append_printf(line_string, "%s %s %s %s", "INQL", $$->str, ($1).vtext->str, ($3).vtext->str);
            insert_line(buffer, current_line, line_string);
            current_line++;
            break;
        case EQ_TYPE:
            g_string_append_printf(line_string, "%s %s %s %s", "IEQL", $$->str, ($1).vtext->str, ($3).vtext->str);
            insert_line(buffer, current_line, line_string);
            current_line++;
            break;
        default:
            yyerror("Invalid RELOP");
      }
    }
    else {
      if(($1).type == FLOAT_TYPE && ($3).type == FLOAT_TYPE) {
        g_string_append_printf(string_op1, "%s", ($1).vtext->str);
        g_string_append_printf(string_op2, "%s", ($3).vtext->str);
      } 
      else if(($1).type == INTEGER_TYPE && ($3).type == FLOAT_TYPE) {
        g_string_append_printf(string_op2, "%s", ($3).vtext->str);
        GString* t = g_string_new(NULL);
        g_string_append_printf(t, "_t%d", temp_var_count++);
        GString* s = g_string_new(NULL);
        g_string_append_printf(s, "%s %s %s", "ITOR", t->str, ($1).vtext->str);
        insert_line(buffer, current_line++, s);
        g_string_append_printf(string_op1, "%s", t->str);
        g_string_free(t, TRUE);
        g_string_free(s, TRUE);
      }
      else if(($1).type == FLOAT_TYPE && ($3).type == INTEGER_TYPE) {
        g_string_append_printf(string_op1, "%s", ($1).vtext->str);
        GString* t = g_string_new(NULL);
        g_string_append_printf(t, "_t%d", temp_var_count++);
        GString* s = g_string_new(NULL);
        g_string_append_printf(s, "%s %s %s", "ITOR", t->str, ($3).vtext->str);
        insert_line(buffer, current_line++, s);
        g_string_append_printf(string_op2, "%s", t->str);
        g_string_free(t, TRUE);
        g_string_free(s, TRUE);
      }
      switch ($2) {
        case LT_TYPE:
            g_string_append_printf(line_string, "%s %s %s %s", "RLSS", $$->str, string_op1->str, string_op2->str);
            insert_line(buffer, current_line, line_string);
            current_line++;
            break;
        case GT_TYPE:
            g_string_append_printf(line_string, "%s %s %s %s", "RGRT", $$->str, string_op1->str, string_op2->str);
            insert_line(buffer, current_line, line_string);
            current_line++;
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
            g_string_append_printf(temp1, "_t%d", temp_var_count++);
            g_string_append_printf(temp2, "_t%d", temp_var_count++);
            g_string_append_printf(line_string1, "%s %s %s %s", "RLSS", temp1->str, string_op1->str, string_op2->str);
            g_string_append_printf(line_string2, "%s %s %s %s", "REQL", temp2->str, string_op1->str, string_op2->str);
            g_string_append_printf(line_string3, "%s %s %s %s", "RADD", $$->str, temp1->str, temp2->str);
            insert_line(buffer, current_line, line_string1);
            current_line++;
            insert_line(buffer, current_line, line_string2);
            current_line++;
            insert_line(buffer, current_line, line_string3);
            current_line++;
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
            g_string_append_printf(temp1, "_t%d", temp_var_count++);
            g_string_append_printf(temp2, "_t%d", temp_var_count++);
            g_string_append_printf(line_string1, "%s %s %s %s", "RGRT", temp1->str, string_op1->str, string_op2->str);
            g_string_append_printf(line_string2, "%s %s %s %s", "REQL", temp2->str, string_op1->str, string_op2->str);
            g_string_append_printf(line_string3, "%s %s %s %s", "RADD", $$->str, temp1->str, temp2->str);
            insert_line(buffer, current_line, line_string1);
            current_line++;
            insert_line(buffer, current_line, line_string2);
            current_line++;
            insert_line(buffer, current_line, line_string3);
            current_line++;
            break;
        case NEQ_TYPE:
            g_string_append_printf(line_string, "%s %s %s %s", "RNQL", $$->str, string_op1->str, string_op2->str);
            insert_line(buffer, current_line, line_string);
            current_line++;
            break;
        case EQ_TYPE:
            g_string_append_printf(line_string, "%s %s %s %s", "REQL", $$->str, string_op1->str, string_op2->str);
            insert_line(buffer, current_line, line_string);
            current_line++;
            break;
        default:
            yyerror("Invalid RELOP");
      }
    }
    g_string_free(temp1, TRUE);
    g_string_free(temp2, TRUE);
    g_string_free(line_string, TRUE);
    g_string_free(line_string1, TRUE);
    g_string_free(line_string2, TRUE);
    g_string_free(line_string3, TRUE);
    g_string_free(string_op1, TRUE);
    g_string_free(string_op2, TRUE);
    g_string_free(($1).vtext, TRUE);
    g_string_free(($3).vtext, TRUE);
  };


expression:		expression ADDOP term {
  $$.vtext = g_string_new(NULL);
  g_string_append_printf($$.vtext, "_t%d", temp_var_count);
  temp_var_count++;
  if($2 == ADD_TYPE) {
    //determine type
    if(($1).type == FLOAT_TYPE && ($3).type == FLOAT_TYPE) {
      $$.type = FLOAT_TYPE;
    }
    else if(($1).type == FLOAT_TYPE && ($3).type == INTEGER_TYPE) {
      $$.type = FLOAT_TYPE;
    }
    else if(($1).type == INTEGER_TYPE && ($3).type == FLOAT_TYPE) {
      $$.type = FLOAT_TYPE;
    }
    else {
      $$.type = INTEGER_TYPE;
    }
    //generate output
    //case IADD
    if(($1).type == INTEGER_TYPE && ($3).type == INTEGER_TYPE) {
      GString* line_string = g_string_new(NULL);
      g_string_append_printf(line_string, "%s %s %s %s", "IADD", $$.vtext->str, ($1).vtext->str, ($3).vtext->str);
      insert_line(buffer, current_line, line_string);
      current_line++;
      g_string_free(line_string, TRUE);
    }
    //case RADD
    else if(($1).type == FLOAT_TYPE && ($3).type == FLOAT_TYPE) {
      GString* line_string = g_string_new(NULL);
      g_string_append_printf(line_string, "%s %s %s %s", "RADD", $$.vtext->str, ($1).vtext->str, ($3).vtext->str);
      insert_line(buffer, current_line, line_string);
      current_line++;
      g_string_free(line_string, TRUE);
    }
    else if(($1).type == INTEGER_TYPE && ($3).type == FLOAT_TYPE) {
      GString* t = g_string_new(NULL);
      g_string_append_printf(t, "_t%d", temp_var_count++);
      GString* line_string2 = g_string_new(NULL);
      g_string_append_printf(line_string2, "%s %s %s", "ITOR", t->str, ($1).vtext->str);
      insert_line(buffer, current_line++, line_string2);
      GString* line_string = g_string_new(NULL);
      g_string_append_printf(line_string, "%s %s %s %s", "RADD", $$.vtext->str, t->str, ($3).vtext->str);
      insert_line(buffer, current_line, line_string);
      current_line++;
      g_string_free(line_string, TRUE);
      g_string_free(line_string2, TRUE);
      g_string_free(t, TRUE);
    }
    else if(($1).type == FLOAT_TYPE && ($3).type == INTEGER_TYPE) {
      GString* t = g_string_new(NULL);
      g_string_append_printf(t, "_t%d", temp_var_count++);
      GString* line_string2 = g_string_new(NULL);
      g_string_append_printf(line_string2, "%s %s %s", "ITOR", t->str, ($3).vtext->str);
      insert_line(buffer, current_line++, line_string2);
      GString* line_string = g_string_new(NULL);
      g_string_append_printf(line_string, "%s %s %s %s", "RADD", $$.vtext->str, ($1).vtext->str, t->str);
      insert_line(buffer, current_line, line_string);
      current_line++;
      g_string_free(line_string, TRUE);
      g_string_free(line_string2, TRUE);
      g_string_free(t, TRUE);
    }
  }
  else {
    //determine type
    if(($1).type == FLOAT_TYPE && ($3).type == FLOAT_TYPE) {
      $$.type = FLOAT_TYPE;
    }
    else if(($1).type == FLOAT_TYPE && ($3).type == INTEGER_TYPE) {
      $$.type = FLOAT_TYPE;
    }
    else if(($1).type == INTEGER_TYPE && ($3).type == FLOAT_TYPE) {
      $$.type = FLOAT_TYPE;
    }
    else {
      $$.type = INTEGER_TYPE;
    }
    //generate output
    //case ISUB
    if(($1).type == INTEGER_TYPE && ($3).type == INTEGER_TYPE) {
      GString* line_string = g_string_new(NULL);
      g_string_append_printf(line_string, "%s %s %s %s", "ISUB", $$.vtext->str, ($1).vtext->str, ($3).vtext->str);
      insert_line(buffer, current_line, line_string);
      current_line++;
      g_string_free(line_string, TRUE);
    }
    //case RSUB
    else if(($1).type == FLOAT_TYPE && ($3).type == FLOAT_TYPE) {
      GString* line_string = g_string_new(NULL);
      g_string_append_printf(line_string, "%s %s %s %s", "RSUB", $$.vtext->str, ($1).vtext->str, ($3).vtext->str);
      insert_line(buffer, current_line, line_string);
      current_line++;
      g_string_free(line_string, TRUE);
    }
    else if(($1).type == INTEGER_TYPE && ($3).type == FLOAT_TYPE) {
      GString* t = g_string_new(NULL);
      g_string_append_printf(t, "_t%d", temp_var_count++);
      GString* line_string2 = g_string_new(NULL);
      g_string_append_printf(line_string2, "%s %s %s", "ITOR", t->str, ($1).vtext->str);
      insert_line(buffer, current_line++, line_string2);
      GString* line_string = g_string_new(NULL);
      g_string_append_printf(line_string, "%s %s %s %s", "RSUB", $$.vtext->str, t->str, ($3).vtext->str);
      insert_line(buffer, current_line, line_string);
      current_line++;
      g_string_free(line_string, TRUE);
      g_string_free(line_string2, TRUE);
      g_string_free(t, TRUE);
    }
    else if(($1).type == FLOAT_TYPE && ($3).type == INTEGER_TYPE) {
      GString* t = g_string_new(NULL);
      g_string_append_printf(t, "_t%d", temp_var_count++);
      GString* line_string2 = g_string_new(NULL);
      g_string_append_printf(line_string2, "%s %s %s", "ITOR", t->str, ($3).vtext->str);
      insert_line(buffer, current_line++, line_string2);
      GString* line_string = g_string_new(NULL);
      g_string_append_printf(line_string, "%s %s %s %s", "RSUB", $$.vtext->str, ($1).vtext->str, t->str);
      insert_line(buffer, current_line, line_string);
      current_line++;
      g_string_free(line_string, TRUE);
      g_string_free(line_string2, TRUE);
      g_string_free(t, TRUE);
    }
  }
  g_string_free(($1).vtext, TRUE);
  g_string_free(($3).vtext, TRUE);
};

expression:   term {
  $$.vtext = ($1).vtext;
  if(($1).type == INTEGER_TYPE) {
    $$.type = INTEGER_TYPE;
  }
  else if(($1).type == FLOAT_TYPE) {
    $$.type = FLOAT_TYPE;
  }
};

term:	term MULOP factor {
  $$.vtext = g_string_new(NULL);
  g_string_append_printf($$.vtext, "_t%d", temp_var_count);
  temp_var_count++;
  if($2 == MUL_TYPE) {
    //determine type
    if(($1).type == FLOAT_TYPE && ($3).type == FLOAT_TYPE) {
      $$.type = FLOAT_TYPE;
    }
    else if(($1).type == FLOAT_TYPE && ($3).type == INTEGER_TYPE) {
      $$.type = FLOAT_TYPE;
    }
    else if(($1).type == INTEGER_TYPE && ($3).type == FLOAT_TYPE) {
      $$.type = FLOAT_TYPE;
    }
    else {
      $$.type = INTEGER_TYPE;
    }
    //generate output
    //case IMLT
    if(($1).type == INTEGER_TYPE && ($3).type == INTEGER_TYPE) {
      GString* line_string = g_string_new(NULL);
      g_string_append_printf(line_string, "%s %s %s %s", "IMLT", $$.vtext->str, ($1).vtext->str, ($3).vtext->str);
      insert_line(buffer, current_line, line_string);
      current_line++;
      g_string_free(line_string, TRUE);
    }
    //case RMLT
    else if(($1).type == FLOAT_TYPE && ($3).type == FLOAT_TYPE) {
      GString* line_string = g_string_new(NULL);
      g_string_append_printf(line_string, "%s %s %s %s", "RMLT", $$.vtext->str, ($1).vtext->str, ($3).vtext->str);
      insert_line(buffer, current_line, line_string);
      current_line++;
      g_string_free(line_string, TRUE);
    }
    else if(($1).type == INTEGER_TYPE && ($3).type == FLOAT_TYPE) {
      GString* t = g_string_new(NULL);
      g_string_append_printf(t, "_t%d", temp_var_count++);
      GString* line_string2 = g_string_new(NULL);
      g_string_append_printf(line_string2, "%s %s %s", "ITOR", t->str, ($1).vtext->str);
      insert_line(buffer, current_line++, line_string2);
      GString* line_string = g_string_new(NULL);
      g_string_append_printf(line_string, "%s %s %s %s", "RMLT", $$.vtext->str, t->str, ($3).vtext->str);
      insert_line(buffer, current_line, line_string);
      current_line++;
      g_string_free(line_string, TRUE);
      g_string_free(line_string2, TRUE);
      g_string_free(t, TRUE);
    }
    else if(($1).type == FLOAT_TYPE && ($3).type == INTEGER_TYPE) {
      GString* t = g_string_new(NULL);
      g_string_append_printf(t, "_t%d", temp_var_count++);
      GString* line_string2 = g_string_new(NULL);
      g_string_append_printf(line_string2, "%s %s %s", "ITOR", t->str, ($3).vtext->str);
      insert_line(buffer, current_line++, line_string2);
      GString* line_string = g_string_new(NULL);
      g_string_append_printf(line_string, "%s %s %s %s", "RMLT", $$.vtext->str, ($1).vtext->str, t->str);
      insert_line(buffer, current_line, line_string);
      current_line++;
      g_string_free(line_string, TRUE);
      g_string_free(line_string2, TRUE);
      g_string_free(t, TRUE);
    }
  }
  else {
    //determine type
    if(($1).type == FLOAT_TYPE && ($3).type == FLOAT_TYPE) {
      $$.type = FLOAT_TYPE;
    }
    else if(($1).type == FLOAT_TYPE && ($3).type == INTEGER_TYPE) {
      $$.type = FLOAT_TYPE;
    }
    else if(($1).type == INTEGER_TYPE && ($3).type == FLOAT_TYPE) {
      $$.type = FLOAT_TYPE;
    }
    else {
      $$.type = INTEGER_TYPE;
    }
    //generate output
    //case IDIV
    if(($1).type == INTEGER_TYPE && ($3).type == INTEGER_TYPE) {
      GString* line_string = g_string_new(NULL);
      g_string_append_printf(line_string, "%s %s %s %s", "IDIV", $$.vtext->str, ($1).vtext->str, ($3).vtext->str);
      insert_line(buffer, current_line, line_string);
      current_line++;
      g_string_free(line_string, TRUE);
    }
    //case RDIV
    else if(($1).type == FLOAT_TYPE && ($3).type == FLOAT_TYPE) {
      GString* line_string = g_string_new(NULL);
      g_string_append_printf(line_string, "%s %s %s %s", "RDIV", $$.vtext->str, ($1).vtext->str, ($3).vtext->str);
      insert_line(buffer, current_line, line_string);
      current_line++;
      g_string_free(line_string, TRUE);
    }
    else if(($1).type == INTEGER_TYPE && ($3).type == FLOAT_TYPE) {
      GString* t = g_string_new(NULL);
      g_string_append_printf(t, "_t%d", temp_var_count++);
      GString* line_string2 = g_string_new(NULL);
      g_string_append_printf(line_string2, "%s %s %s", "ITOR", t->str, ($1).vtext->str);
      insert_line(buffer, current_line++, line_string2);
      GString* line_string = g_string_new(NULL);
      g_string_append_printf(line_string, "%s %s %s %s", "RDIV", $$.vtext->str, t->str, ($3).vtext->str);
      insert_line(buffer, current_line, line_string);
      current_line++;
      g_string_free(line_string, TRUE);
      g_string_free(line_string2, TRUE);
      g_string_free(t, TRUE);
    }
    else if(($1).type == FLOAT_TYPE && ($3).type == INTEGER_TYPE) {
      GString* t = g_string_new(NULL);
      g_string_append_printf(t, "_t%d", temp_var_count++);
      GString* line_string2 = g_string_new(NULL);
      g_string_append_printf(line_string2, "%s %s %s", "ITOR", t->str, ($3).vtext->str);
      insert_line(buffer, current_line++, line_string2);
      GString* line_string = g_string_new(NULL);
      g_string_append_printf(line_string, "%s %s %s %s", "RDIV", $$.vtext->str, ($1).vtext->str, t->str);
      insert_line(buffer, current_line, line_string);
      current_line++;
      g_string_free(line_string, TRUE);
      g_string_free(line_string2, TRUE);
      g_string_free(t, TRUE);
    }
  }
  g_string_free(($1).vtext, TRUE);
  g_string_free(($3).vtext, TRUE);
};

term: factor {
  $$.vtext = ($1).vtext;
  if(($1).type == INTEGER_TYPE) {
    $$.type = INTEGER_TYPE;
  }
  else if(($1).type == FLOAT_TYPE) {
    $$.type = FLOAT_TYPE;
  }
};

factor:		'(' expression ')' {
  $$.vtext = ($2).vtext;
  if(($2).type == INTEGER_TYPE) {
    $$.type = INTEGER_TYPE;
  }
  else if(($2).type == FLOAT_TYPE) {
    $$.type = FLOAT_TYPE;
  }
};

factor:		CAST '(' expression ')' {
  $$.vtext = g_string_new(NULL);
  GString* line_string = g_string_new(NULL);
  if($1 == CAST_INT_TYPE && ($3).type == FLOAT_TYPE) {
    g_string_append_printf($$.vtext, "_t%d", temp_var_count);
    temp_var_count++;
    $$.type = INTEGER_TYPE;
    g_string_append_printf(line_string, "%s %s %s", "RTOI", $$.vtext->str, ($3).vtext->str);
    insert_line(buffer, current_line++, line_string);
  }
  //TODO: add ITOR
  else if($1 == CAST_FLOAT_TYPE && ($3).type == INTEGER_TYPE) {
    g_string_append_printf($$.vtext, "_t%d", temp_var_count);
    temp_var_count++;
    $$.type = FLOAT_TYPE;
    g_string_append_printf(line_string, "%s %s %s", "ITOR", $$.vtext->str, ($3).vtext->str);
    insert_line(buffer, current_line++, line_string);
  }
  else if(($3).type == NO_TYPE) {
    extern int yylineno;
    fprintf(stderr, "error. line %d: semantic error, cast type illegal\n", yylineno);
    error_exists = 1;
    $$.type = NO_TYPE;
    g_string_append_printf($$.vtext, "%s", ($3).vtext->str);
  }
  else {
    $$.type = ($3).type;
    g_string_append_printf($$.vtext, "%s", ($3).vtext->str);
  }
  g_string_free(line_string, TRUE);
  g_string_free(($3).vtext, TRUE);
};

factor:		ID {
  int symbol_type = get_symbol_type($1);
  if(symbol_type == NO_TYPE) {
    extern int yylineno;
    fprintf(stderr, "error. line %d: semantic error, undeclared variable %s\n", yylineno, $1);
    error_exists = 1;
    $$.vtext = g_string_new($1);
  }
  else {
    if(symbol_type == INTEGER_TYPE) {
      $$.type = INTEGER_TYPE;
    }
    else if(symbol_type == FLOAT_TYPE) {
      $$.type = FLOAT_TYPE;
    }
    $$.vtext = g_string_new($1);
  }
  free($1);
};

factor:		NUM {
  char* endptr;
  long int_value = strtol($1, &endptr, 10);
  if (*endptr == '\0') {
    /* NUM is an integer */
    $$.type = INTEGER_TYPE;
  } else {
    double float_value = strtod($1, &endptr);
    if (*endptr == '\0') {
      /* NUM is a float */
      $$.type = FLOAT_TYPE;
    } else {
      /* NUM is not a valid integer or float */
      yyerror("Invalid number");
    }
  }
  $$.vtext = g_string_new($1);
  free($1);
};


		   
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
  error_exists = 0;

  symbol_table = g_hash_table_new_full(g_str_hash, g_str_equal, (GDestroyNotify)free, NULL);
  buffer = create_buffer();
  input_file_name = g_string_new(argv[1]);


#if 0

#ifdef YYDEBUG
   yydebug = 1;
#endif
#endif
  yyparse ();
  
  g_string_free(input_file_name, TRUE);
  g_hash_table_destroy(symbol_table);
  
  fclose (yyin);
  return 0;
}

/*
  printf error to stderr and close the program
  some errors don't call this function in order
  to allow the compiler to recover and keep compiling
*/
void yyerror (const char *s)
{
  extern int yylineno;
  error_exists = 1;
  
  fprintf (stderr, "error. line %d:%s\n", yylineno,s);
  if(current_break_lines_list != NULL) {
    g_list_free(current_break_lines_list);
  }
  delete_buffer(buffer);
}



