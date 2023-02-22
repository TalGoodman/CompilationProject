#include "outputlist.h"


// Define a function to create a new buffer
Line* create_buffer() {
    Line* buffer = g_new(Line, 1);
    *buffer = NULL;
    return buffer;
}

// Define a function to insert an element into the buffer
void insert_element(Line* buffer, int line, int col, Element e) {
    GListLine* line_list = g_list_nth(*buffer, line);
    GListElement* elem_list = g_list_nth(line_list->data, col);
    Element* elem = g_new(Element, 1);
    *elem = e;
    elem_list->data = elem;
}

// Define a function to insert a line into the buffer
void insert_line(Line* buffer, int line, const GString* text) {
    GListLine* line_list = g_list_nth(*buffer, line);
    GListElement* elem_list = NULL;
    Element* elem = g_new(Element, 1);
    elem->type = STRING;
    elem->data.s = g_string_new(text->str);
    elem_list = g_list_append(elem_list, elem);
    *buffer = g_list_insert(*buffer, elem_list, line);
}

void set_element(Line* buffer, int line, int col, Element e) {
    GListLine* line_list = g_list_nth(*buffer, line);
    GListElement* elem_list = g_list_nth(line_list->data, col);
    if (elem_list->data != NULL) {
        g_free(elem_list->data);
    }
    Element* elem = g_new(Element, 1);
    *elem = e;
    elem_list->data = elem;
}

// Define a function to delete an element from the buffer
void delete_elem(Line* buffer, int line, int col) {
    GListLine* line_list = g_list_nth(*buffer, line);
    GListElement* elem_list = g_list_nth(line_list->data, col);
    g_free(elem_list->data);
    line_list->data = g_list_delete_link(line_list->data, elem_list);
}

// Define a function to delete a line from the buffer
void delete_line(Line* buffer, int line) {
    GListLine* line_list = g_list_nth(*buffer, line);
    for (GListElement* elem_list = line_list->data; elem_list != NULL; elem_list = elem_list->next) {
        Element* elem = elem_list->data;
        if (elem->type == STRING) {
            g_free(elem->data.s);
        }
        g_free(elem);
    }
    *buffer = g_list_delete_link(*buffer, line_list);
}

//Delete buffer
void delete_buffer(Line* buffer) {
    for (GListLine* line_list = *buffer; line_list != NULL; line_list = line_list->next) {
        for (GListElement* element_list = line_list->data; element_list != NULL; element_list = element_list->next) {
            if (element_list->data != NULL) {
                Element* element = element_list->data;
                if (element->type == STRING) {
                    // element is a string
                    g_free(element->data.s);
                }
                g_free(element);
            }
        }
    }
}

void create_qud_file(Line* buffer, GString* file_name) {
    FILE* file = fopen(file_name->str, "w");
    if (file == NULL) {
        //TODO: print to stdr
        printf("Failed to create file.\n");
        return;
    }

    for (GListLine* line_list = *buffer; line_list != NULL; line_list = line_list->next) {
        for (GListElement* element_list = line_list->data; element_list != NULL; element_list = element_list->next) {
            if (element_list->data != NULL) {
                Element* element = element_list->data;
                if (element->type == STRING) {
                    // element is a string
                    fprintf(file, "%s", element->data.s->str);
                } else {
                    // element is a Label
                    fprintf(file, "%d", element->data.l);
                }
                if(element_list->next == NULL) {
                    fprintf(file, "\n");
                }
            }
        }
    }
    fclose(file);
}


