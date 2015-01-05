#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#include "variable_type.h"

int are_same_type(variable_type_t *t1, variable_type_t *t2) {
  int res = t1->basic == t2->basic
    && t1->array_size == t2->array_size
    && t1->nb_param == t2->nb_param
    && t1->pointer == t2->pointer
    && !strcmp(t1->class_name, t2->class_name);
  /*
  param_t *p11, *p12, *p21, *p22;
  p11 = (param_t*)(TAILQ_FIRST(t1->params)->data);
  p21 = (param_t*)(TAILQ_FIRST(t2->params)->data);
  while(res && p11 != NULL && p12 != NULL) {
    p12 = (param_t*)(TAILQ_NEXT(p11, pointers)->data);
    p22 = (param_t*)(TAILQ_NEXT(p21, pointers)->data);
    res = p11->type->basic == p21->type->basic && !strcmp(p11->type->class_name, p21->type->class_name);
    p11 = p12;
    p21 = p22;
  }
  */

  return res;
}

int get_size(variable_type_t *t) {
  return 4 * (t->pointer == 1 || t->basic == TYPE_CLASS ? 2 : 1) * (t->array_size == -1 ? 1 : t->array_size);
}

void free_variable_type(void *t) {
  variable_type_t* type = (variable_type_t*)t;
  if (type == NULL) return;

  if (type->class_name != NULL) {
    free(type->class_name);
  }

  free(type);
}

int member_offset(class_definition_t *class, char *member_name) {
  int offset = 0;
  generic_element_t *e;
  declarator_t *member;
  
  TAILQ_FOREACH(e, &(class->members), pointers) {
    member = (declarator_t*)(e->data);
    if (strcmp(member_name, member->name) == 0) {
      return offset;
    }
    offset += get_size(&(member->type));
  }

  return -1;
}

int get_class_size(class_definition_t *class) {
  int size = 0;
  generic_element_t *e;
  declarator_t *m;

  TAILQ_FOREACH(e, &(class->members), pointers) {
    m = (declarator_t*)(e->data);
    if (m->type.nb_param == -1) {
      size += get_size(&(m->type));
    }
  }
  return size;
}

void free_class_definition(void *c) {
  class_definition_t *class = (class_definition_t*) c;
  if (class == NULL) return;

  if (class->class_name != NULL) {
    free(class->class_name);
  }
  free(class);
}

variable_t *new_variable(variable_type_t type, int addr) {
  variable_t *var = malloc(sizeof (variable_t));
  var->type = type;
  var->addr = addr;
  return var;
}

void free_variable(void *v) {
  variable_t *var = (variable_t*) v;
  free(var);
}

int is_function(variable_type_t *type) {
  return type->nb_param != -1;
}
