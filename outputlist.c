#include "outputlist.h"


// Define a function to create a new buffer
Line* create_buffer() {
    Line* buffer = g_new(Line, 1);
    *buffer = NULL;
    return buffer;
}

// Define a function to insert an element into the buffer
void insert_elem(Line* buffer, int line, int col, Elem e) {
    GListLine* line_list = g_list_nth(*buffer, line);
    GListElem* elem_list = g_list_nth(line_list->data, col);
    Elem* elem = g_new(Elem, 1);
    *elem = e;
    elem_list->data = elem;
}

// Define a function to insert a line into the buffer
void insert_line(Line* buffer, int line, const char* text) {
    GListLine* line_list = g_list_nth(*buffer, line);
    GListElem* elem_list = NULL;
    for (int i = 0; i < strlen(text); i++) {
        Elem* elem = g_new(Elem, 1);
        elem->type = CHAR;
        elem->data.c = g_new(char, 1);
        *(elem->data.c) = text[i];
        elem_list = g_list_append(elem_list, elem);
    }
    *buffer = g_list_insert(*buffer, elem_list, line);
}

// Define a function to delete an element from the buffer
void delete_elem(Line* buffer, int line, int col) {
    GListLine* line_list = g_list_nth(*buffer, line);
    GListElem* elem_list = g_list_nth(line_list->data, col);
    g_free(elem_list->data);
    line_list->data = g_list_delete_link(line_list->data, elem_list);
}

// Define a function to delete a line from the buffer
void delete_line(Line* buffer, int line) {
    GListLine* line_list = g_list_nth(*buffer, line);
    for (GListElem* elem_list = line_list->data; elem_list != NULL; elem_list = elem_list->next) {
        Elem* elem = elem_list->data;
        if (elem->type == CHAR) {
            g_free(elem->data.c);
        } else {
            g_free(elem->data.l);
        }
        g_free(elem);
    }
    *buffer = g_list_delete_link(*buffer, line_list);
}

// Define a function to iterate over the buffer
void iterate_buffer(Line* buffer) {
    for (GListLine* line_list = *buffer; line_list != NULL; line_list = line_list->next) {
        for (GListElem* elem_list = line_list->data; elem_list != NULL; elem_list = elem_list->next) {
            if (elem_list->data != NULL) {
                Elem* elem = elem_list->data;
                if (elem->type == CHAR) {
                    // element is a character
                    printf("Character: %c\n", *(elem->data.c));
                } else {
                    // element is a Label
                    printf("Label: %d\n", *(elem->data.l));
                }
            }
        }
    }
}


