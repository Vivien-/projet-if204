#define _GNU_SOURCE

#include <stdlib.h>
#include <stdio.h>
#include "name_space.h"

name_space_t *new_name_space() {
  name_space_t *ns = malloc(sizeof (name_space_t));
  ns->size = 0;
  ns->htab = calloc(1, sizeof (struct hsearch_data));
  hcreate_r(HSIZE, ns->htab);
  return ns;
}

void free_name_space(name_space_t *ns) {
  if (ns != NULL) {
    hdestroy_r(ns->htab);
    free(ns->htab);
    free(ns);
  }
}

void insert_in_name_space(char *name, variable_t *var, name_space_t *ns) {
  ENTRY e, *rv;
  e.key = name;
  e.data = var;
  hsearch_r(e, ENTER, &rv, ns->htab);
  ns->size += get_size(&(var->type));
}

variable_t *is_defined(char *name, name_space_t *ns_glob, name_space_t *ns_loc) {
  variable_t *res;
  ENTRY e, *rv;
  e.key = name;
  if (ns_glob && hsearch_r(e, FIND, &rv, ns_glob->htab)) {
    res = rv->data;
    return res;
  }
  if (ns_loc && hsearch_r(e, FIND, &rv, ns_loc->htab)) {
    res = rv->data;
    return res;
  }
  return NULL;
}

class_name_space_t *new_class_name_space() {
  class_name_space_t *cnp = calloc(1, sizeof (struct hsearch_data));
  hcreate_r(HSIZE, cnp);
  return cnp;
}

void insert_in_class_name_space(char *name, class_definition_t *class, class_name_space_t *cnp) {
  ENTRY e, *rv;
  e.key = name;
  e.data = class;
  hsearch_r(e, ENTER, &rv, cnp);
}

class_definition_t *find_in_class_name_space(char *name, class_name_space_t *cnp) {
  class_definition_t *res;
  ENTRY e, *rv;
  e.key = name;
  if (hsearch_r(e, FIND, &rv, cnp)) {
    res = rv->data;
    return res;
  }
  return NULL;
}

void free_class_name_space(class_name_space_t *cnp) {
  hdestroy_r(cnp);
  free(cnp);
}
