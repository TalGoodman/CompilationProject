#ifndef BUFFER_H
#define BUFFER_H

#include <glib.h>
#include <stdlib.h>
#include <stdio.h>

typedef GList GListLine;
typedef GList GListElement;
typedef GListElement* Line;

int error_exists;      //an indicatorfor error existence



Line* create_buffer();
Line* insert_element(Line* buffer, int line, int col, GString* s);
Line* insert_line(Line* buffer, int line, const GString* text);
void set_element(Line* buffer, int line, int col, GString* e);
void delete_elem(Line* buffer, int line, int col);
void delete_line(Line* buffer, int line);
void delete_buffer(Line* buffer);
void create_qud_file(Line* buffer, GString* file_name);

#endif /* BUFFER_H */
