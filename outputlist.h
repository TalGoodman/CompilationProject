#ifndef BUFFER_H
#define BUFFER_H

#include <glib.h>
#include <stdlib.h>
#include <stdio.h>

typedef GList GListLine;
typedef GList GListElement;
typedef GListElement* Line;
typedef int Label;

typedef struct {
    enum { STRING, LABEL } type;
    union {
        char* s;
        Label l;
    } data;
} Element;



Line* create_buffer();
void insert_element(Line* buffer, int line, int col, Element e);
void insert_line(Line* buffer, int line, const char* text);
void set_element(Line* buffer, int line, int col, Element e);
void delete_elem(Line* buffer, int line, int col);
void delete_line(Line* buffer, int line);
void delete_buffer(Line* buffer);
void create_qud_file(Line* buffer, GString* file_name);

#endif /* BUFFER_H */
