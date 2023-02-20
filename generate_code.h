#ifndef GENERATE_CODE_H
#define GENERATE_CODE_H

#include <glib.h>

typedef GList GListLine;
typedef GList GListElem;
typedef GListElem* Line;
typedef int Label;

typedef struct {
    enum { CHAR, LABEL } type;
    union {
        char* c;
        Label* l;
    } data;
} Element;

void insert_element(Line* buffer, int col, Element e);
void insert_char(Line* buffer, char c);
void insert_label(Line* buffer, Label l);
void delete_element(Line* buffer, int col);
void delete_buffer(Line* buffer);
void create_qud_file(Line* buffer, char* file_name);

#endif