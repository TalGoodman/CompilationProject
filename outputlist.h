#ifndef BUFFER_H
#define BUFFER_H

#include <glib.h>
#include <stdlib.h>
#include <stdio.h>

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
} Elem;



Line* create_buffer();
void insert_elem(Line* buffer, int line, int col, Elem e);
void insert_line(Line* buffer, int line, const char* text);
void delete_elem(Line* buffer, int line, int col);
void delete_line(Line* buffer, int line);
void iterate_buffer(Line* buffer);

#endif /* BUFFER_H */
