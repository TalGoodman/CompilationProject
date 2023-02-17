#include "generate_code.h"

// Define a function to insert an element into the buffer
void insert_element(Line* buffer, int col, Element e) {
    GListElem* elem_list = g_list_nth(*buffer, col);
    Element* elem = g_new(Element, 1);
    *elem = e;
    elem_list->data = elem;
}

// Define a function to insert a character into the buffer
void insert_char(Line* buffer, char c) {
    Element e;
    e.type = CHAR;
    e.data.c = g_new(char, 1);
    *(e.data.c) = c;
    *buffer = g_list_append(*buffer, &e);
}

// Define a function to insert a label into the buffer
void insert_label(Line* buffer, Label l) {
    Element e;
    e.type = LABEL;
    e.data.l = g_new(Label, 1);
    *(e.data.l) = l;
    *buffer = g_list_append(*buffer, &e);
}

// Define a function to delete an element from the buffer
void delete_element(Line* buffer, int col) {
    GListElem* elem_list = g_list_nth(*buffer, col);
    g_free(elem_list->data);
    *buffer = g_list_delete_link(*buffer, elem_list);
}

// Define a function to iterate over the buffer
void iterate_buffer(Line* buffer) {
    for (GListElem* elem_list = *buffer; elem_list != NULL; elem_list = elem_list->next) {
        if (elem_list->data != NULL) {
            Element* elem = elem_list->data;
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