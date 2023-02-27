#include "outputlist.h"

// Define a function to create a new buffer
Line* create_buffer() {
    Line* buffer = g_new(Line, 1);
    *buffer = NULL;
    return buffer;
}

// Define a function to insert an element into the buffer
Line* insert_element(Line* buffer, int line, int col, GString* e) {
    if(error_exists == 1) {
        return buffer;
    }
    GString* element = g_string_new(e->str);
    GListLine* line_list = g_list_nth(*buffer, line);
    //GListElement* element_list;
    if(line_list == NULL){
        line_list = g_list_insert(line_list, element, 0);
        *buffer = g_list_insert(*buffer, line_list, line);
    }
    else {
        GListLine* temp_list = NULL;
        for(GListElement* l = line_list->data; l != NULL; l = l->next){
            GString* temp_gstring = l->data;
            GString* e = g_string_new(temp_gstring->str);
            temp_list = g_list_append(temp_list, e);
            g_string_free(temp_gstring, TRUE);
        }
        *buffer = g_list_remove_link(*buffer, line_list);
        //g_list_free_full(line_list, (GDestroyNotify)g_string_free);
        g_list_free(line_list->data);
        g_list_free(line_list);
        temp_list = g_list_insert(temp_list, element, col);
        *buffer = g_list_insert(*buffer, temp_list, line);
    }
    //GListElement* element_list = g_list_nth(line_list->data, col);
    //element_list->data = element;
    return buffer;
}

// Define a function to insert a line into the buffer
Line* insert_line(Line* buffer, int line, const GString* text) {
    if(error_exists == 1) {
        return buffer;
    }
    GListLine* line_list = g_list_nth(*buffer, line);
    //GListElement* elem_list = NULL;
    GString* elem;
    elem = g_string_new(text->str);
    line_list = g_list_insert(line_list, elem, 0);
    //elem_list = g_list_append(elem_list, elem);
    *buffer = g_list_insert(*buffer, line_list, line);
    return buffer;
}

void set_element(Line* buffer, int line, int col, GString* e) {
    if(error_exists == 1) {
        return;
    }
    //insert_element(buffer, line, col, e);
    //GListLine* line_list = g_list_nth(*buffer, line);
    int line_counter = 0;
    for (GListLine* line_list = *buffer; line_list != NULL && line_counter <= line; line_list = line_list->next) {
        if(line_counter == line){
            int counter = 0;
            for (GListElement* element_list = line_list->data; element_list != NULL && counter <= col; element_list = element_list->next) {
                if(counter == col) {
                    if (element_list != NULL && element_list->data != NULL) {
                        //free string
                        g_string_free(element_list->data, TRUE);
                        element_list->data = g_string_new(e->str);
                        
                    }
                }
                counter++;
            }
        }
        line_counter++;
    }
    //GListElement* nth = g_list_nth(line_list->data, col);
    //Element* first_element_p = nth->data;
    //void* temp_pointer = (void*) nth_data;
    //Element* first_element_p = (Element*) temp_pointer;
    //Element *first_element_p = (Element *) GSIZE_TO_POINTER(GPOINTER_TO_SIZE(nth_data));
    //Element* first_element_p = (Element*) G_STRUCT_MEMBER_P(nth_data, 0);
    //first_element_p->data.l = e.data.l;
    //fprintf(stderr, "element type: %d\n", first_element_p->type);
    //fprintf(stderr, "element type: %d\n", e.type);
    /*
    GListLine* line_list = g_list_nth(*buffer, line);
    GListElement* elem_list = g_list_nth(line_list->data, col);
    if (elem_list->data != NULL) {
        g_free(elem_list->data);
    }
    Element* elem = g_new(Element, 1);
    *elem = e;
    elem_list->data = elem;*/
}

// Define a function to delete an element from the buffer
/*
void delete_elem(Line* buffer, int line, int col) {
    GListLine* line_list = g_list_nth(*buffer, line);
    GListElement* elem_list = g_list_nth(line_list->data, col);
    g_free(elem_list->data);
    line_list->data = g_list_delete_link(line_list->data, elem_list);
}
*/
// Define a function to delete a line from the buffer
/*
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
}*/

void delete_buffer_aux1(GString* string) {
    g_string_free(string, TRUE);
}

void delete_buffer_aux2(GList* list) {
    g_list_free_full(g_steal_pointer (&list), (GDestroyNotify)delete_buffer_aux1);
}

//Delete buffer
void delete_buffer(Line* buffer) {
    /*
    for (GListLine* line_list = *buffer; line_list != NULL; line_list = line_list->next) {
        g_list_free_full(line_list->data, (GDestroyNotify)g_string_free);
    }*/
    //g_list_free_full(g_steal_pointer(buffer), (GDestroyNotify)delete_buffer_aux2);
    //g_free(buffer);
    
    for (GListLine* line_list = *buffer; line_list != NULL; line_list = line_list->next) {
        for (GListElement* element_list = line_list->data; element_list != NULL; element_list = element_list->next) {
            if (element_list->data != NULL) {
                GString* element = element_list->data;
                g_string_free(element, TRUE);
                //element_list->data = GINT_TO_POINTER(1);
            }
        }
    }
    for (GListLine* line_list = *buffer; line_list != NULL; line_list = line_list->next) {
        g_list_free(line_list->data);
    }
    g_list_free(*buffer);
    g_free(buffer);
}

void create_qud_file(Line* buffer, GString* file_name) {
    //TODO: change to g_string_truncate(input_file_name, input_file_name->len - 3);
    g_string_truncate(file_name, file_name->len - 3);
    g_string_append(file_name, ".qud");
    //fprintf(stderr, "%s", file_name->str);
    FILE* file = fopen(file_name->str, "w");
    if (file == NULL) {
        //TODO: print to stdr
        printf("Failed to create file.\n");
        return;
    }
    for (GListLine* line_list = *buffer; line_list != NULL; line_list = line_list->next) {
        for (GListElement* element_list = line_list->data; element_list != NULL; element_list = element_list->next) {
            if (element_list != NULL && element_list->data != NULL) {
                GString* element = element_list->data;
                fprintf(file, "%s", element->str);
                if(element_list->next == NULL && line_list->next != NULL) {
                    fprintf(file, "\n");
                }
            }
        }
    }
    fclose(file);
}


