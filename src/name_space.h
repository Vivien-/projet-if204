#ifndef NAME_SPACE_H
#define NAME_SPACE_H

#include <search.h>
#include <sys/queue.h>

#include "variable_type.h"

#define HSIZE 50 /* limité à 50 variables par espace de nommage */

/*
 * Ce module définie un espace de nommage pour pouvoir stocker les types des variables définies
 */

typedef struct name_space_s name_space_t;
typedef struct hsearch_data class_name_space_t;


struct name_space_s {
  struct hsearch_data *htab;
  int size;
};

int hcreate_r(size_t nel, struct hsearch_data *htab);
int hsearch_r(ENTRY item, ACTION action, ENTRY **retval, struct hsearch_data *htab);
void hdestroy_r(struct hsearch_data *htab);

name_space_t *new_name_space();

void free_name_space(name_space_t *ns);

void insert_in_name_space(char *name, variable_t *var, name_space_t *ns);

variable_t *is_defined(char *name, name_space_t *ns_glob, name_space_t *ns_loc);

int get_stack_size(name_space_t *ns);

class_name_space_t *new_class_name_space();

void insert_in_class_name_space(char *name, class_definition_t *class, class_name_space_t *cnp);

class_definition_t *find_in_class_name_space(char *name, class_name_space_t *cnp);

void free_class_name_space(class_name_space_t *cnp);

#endif
