#define _GNU_SOURCE

#include <stdlib.h>
#include "name_space.h"

name_space_stack_t *new_name_space_stack() {
  name_space_stack_t *nsp = malloc(sizeof (name_space_stack_t));
  TAILQ_INIT(nsp);
  name_space_t *ns = malloc(sizeof (name_space_t));
  ns->htab = calloc(1, sizeof (struct hsearch_data));
  hcreate_r(HSIZE, ns->htab);
  TAILQ_INSERT_HEAD(nsp, ns, pointers);
  return nsp;
}

void stack_new_name_space(name_space_stack_t *nsp) {
  name_space_t *ns = malloc(sizeof (name_space_t));
  ns->htab = calloc(1, sizeof (struct hsearch_data));
  hcreate_r(HSIZE, ns->htab);
  TAILQ_INSERT_HEAD(nsp, ns, pointers);
}

void pop_name_space(name_space_stack_t *nsp) {
  name_space_t *ns = TAILQ_FIRST(nsp);
  hdestroy_r(ns->htab);
  free(ns->htab);
  TAILQ_REMOVE(nsp, ns, pointers);
  free(ns);
}

void insert_in_current_name_space(char *name, variable_t *type, name_space_stack_t *nsp) {
  name_space_t *ns = TAILQ_FIRST(nsp);
  ENTRY e, *rv;
  e.key = name;
  e.data = type;
  hsearch_r(e, ENTER, &rv, ns->htab);
}

int current_name_space_is_root(name_space_stack_t *nsp) {
  name_space_t *ns = TAILQ_FIRST(nsp);
  return ns->pointers.tqe_next == NULL;
}

variable_t *is_defined(char *name, name_space_stack_t *nsp) {
  name_space_t *ns;
  variable_t *res;
  ENTRY e, *rv;
  e.key = name;
  TAILQ_FOREACH(ns, nsp, pointers) {
    if (hsearch_r(e, FIND, &rv, ns->htab)) {
      res = rv->data;
      return res;
    }
  }
  return NULL;
}

void free_name_space_stack(name_space_stack_t *nsp) {
  if (nsp == NULL) return;
  
  name_space_t *ns;
  while(!TAILQ_EMPTY(nsp)) {
    ns = TAILQ_FIRST(nsp);
    hdestroy_r(ns->htab);
    free(ns->htab);
    TAILQ_REMOVE(nsp, ns, pointers);
    free(ns);
  }

  free(nsp);
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
