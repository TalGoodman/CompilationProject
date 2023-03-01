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
        g_list_free(line_list->data);
        g_list_free(line_list);
        temp_list = g_list_insert(temp_list, element, col);
        *buffer = g_list_insert(*buffer, temp_list, line);
    }
    return buffer;
}

// Define a function to insert a line into the buffer
Line* insert_line(Line* buffer, int line, const GString* text) {
    if(error_exists == 1) {
        return buffer;
    }
    GListLine* line_list = g_list_nth(*buffer, line);
    GString* elem;
    elem = g_string_new(text->str);
    line_list = g_list_insert(line_list, elem, 0);
    *buffer = g_list_insert(*buffer, line_list, line);
    return buffer;
}

void set_element(Line* buffer, int line, int col, GString* e) {
    if(error_exists == 1) {
        return;
    }
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
}

void delete_buffer_aux1(GString* string) {
    g_string_free(string, TRUE);
}

void delete_buffer_aux2(GList* list) {
    g_list_free_full(g_steal_pointer (&list), (GDestroyNotify)delete_buffer_aux1);
}

//Delete buffer
void delete_buffer(Line* buffer) {
    for (GListLine* line_list = *buffer; line_list != NULL; line_list = line_list->next) {
        for (GListElement* element_list = line_list->data; element_list != NULL; element_list = element_list->next) {
            if (element_list->data != NULL) {
                GString* element = element_list->data;
                g_string_free(element, TRUE);
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
    g_string_truncate(file_name, file_name->len - 3);
    g_string_append(file_name, ".qud");
    FILE* file = fopen(file_name->str, "w");
    if (file == NULL) {
        fprintf(stderr, "Failed to create file.\n");
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


