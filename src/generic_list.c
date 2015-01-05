#include <stdlib.h>
#include <string.h>

#include "generic_list.h"

generic_list_t *new_list() {
  generic_list_t *list = malloc(sizeof (generic_list_t));
  TAILQ_INIT(list);
  return list;
}

void insert(generic_list_t *list, void *data, int size) {
  generic_element_t *element = malloc(sizeof (generic_element_t));
  element->data = malloc(size);
  memcpy(element->data, data, size);
  TAILQ_INSERT_HEAD(list, element, pointers);
}

void free_list(generic_list_t *list, void(free_method)(void*)) {
  generic_element_t *e;
  while(!TAILQ_EMPTY(list)) {
    e = TAILQ_FIRST(list);
    if (free_method != NULL) {
      free_method(e->data);
    }
    TAILQ_REMOVE(list, e, pointers);
    free(e);
  }
  free(list);
}
