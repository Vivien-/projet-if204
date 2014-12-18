#include <stdlib.h>
#include "name_space.h"

name_space_stack_t *newNameSpaceStack() {
  name_space_stack_t *nsp = malloc(sizeof (name_space_stack_t));
  TAILQ_INIT(nsp);
  name_space_t *ns = malloc(sizeof (name_space_t));
  ns->htab = malloc(sizeof (ns->htab));
  hcreate_r(HSIZE, ns->htab);
  TAILQ_INSERT_HEAD(nsp, ns, pointers);
  return nsp;
}

void stackNewNameSpace(name_space_stack_t *nsp) {
  name_space_t *ns = malloc(sizeof (name_space_t));
  ns->htab = malloc(sizeof (ns->htab));
  hcreate_r(HSIZE, ns->htab);
  TAILQ_INSERT_HEAD(nsp, ns, pointers);
}

void popNameSpace(name_space_stack_t *nsp) {
  name_space_t *ns = TAILQ_FIRST(nsp);
  hdestroy_r(ns->htab);
  free(ns->htab);
  TAILQ_REMOVE(nsp, ns, pointers);
  free(ns);
}

void insert(char *name, variable_type_t *type, name_space_stack_t *nsp) {
  name_space_t *ns = TAILQ_FIRST(nsp);
  ENTRY e, *rv;
  e.key = name;
  e.data = type;
  hsearch_r(e, ENTER, &rv, ns->htab);
}

int isRoot(name_space_stack_t *nsp) {
  name_space_t *ns = TAILQ_FIRST(nsp);
  return ns->pointers.tqe_next == NULL;
}

variable_type_t *find(char *name, name_space_stack_t *nsp) {
  name_space_t *ns;
  variable_type_t *res;
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

void freeNameSpaceStack(name_space_stack_t *nsp) {
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
