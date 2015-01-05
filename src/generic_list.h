#ifndef GENERIC_LIST_H
#define GENERIC_LIST_H

#include <sys/queue.h>

typedef struct generic_list_s generic_list_t;
typedef struct generic_element_s generic_element_t; 

struct generic_element_s {
  void *data;
  TAILQ_ENTRY(generic_element_s) pointers;
};

TAILQ_HEAD(generic_list_s, generic_element_s);

generic_list_t *new_list();

void insert(generic_list_t *list, void *data, int size);

int nb_element(generic_list_t *list);

void free_list(generic_list_t *list, void(free_method)(void*));

#endif
