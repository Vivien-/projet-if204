#include <stdlib.h>
#include <string.h>

#include "variable_type.h"

variable_type_t *getTypeVoid() {
  variable_type_t *type = malloc(sizeof (variable_type_t));
  type->basic = VOID;
  type->array_size = -1;
  type->nb_param = -1;
  type->params = malloc(sizeof (param_list_t));
  TAILQ_INIT(type->params);
  type->class_name = NULL;
  return type;
}

variable_type_t *getTypeVoidP() {
  variable_type_t *type = getTypeVoid();
  type->basic = VOIDP;
  return type;
}

variable_type_t *getTypeInt() {
  variable_type_t *type = getTypeVoid();
  type->basic = INT;
  return type;
}

variable_type_t *getTypeFloat() {
  variable_type_t *type = getTypeVoid();
  type->basic = FLOAT;
  return type;
}

variable_type_t *getTypeIntP() {
  variable_type_t *type = getTypeVoid();
  type->basic = INTP;
  return type;
}

variable_type_t *getTypeFloatP() {
  variable_type_t *type = getTypeVoid();
  type->basic = FLOATP;
  return type;
}

variable_type_t *getTypeVoidArray(int size) {
  variable_type_t *type = getTypeVoid();
  type->basic = VOIDP;
  type->array_size = size;
  return type;
}

variable_type_t *getTypeVoidPArray(int size) {
  variable_type_t *type = getTypeVoid();
  type->basic = VOIDP;
  type->array_size = size;
  return type;
}

variable_type_t *getTypeIntArray(int size) {
  variable_type_t *type = getTypeVoid();
  type->basic = INT;
  type->array_size = size;
  return type;
}

variable_type_t *getTypeFloatArray(int size) {
  variable_type_t *type = getTypeVoid();
  type->basic = FLOAT;
  type->array_size = size;
  return type;
}

variable_type_t *getTypeIntPArray(int size) {
  variable_type_t *type = getTypeVoid();
  type->basic = INTP;
  type->array_size = size;
  return type;
}

variable_type_t *getTypeFLoatPArray(int size) {
  variable_type_t *type = getTypeVoid();
  type->basic = FLOATP;
  type->array_size = size;
  return type;
}

variable_type_t *getTypeClass(char *name) {
  variable_type_t *type = getTypeVoid();
  type->basic = CLASS;
  type->class_name = malloc(strlen(name) + 1);
  memcpy(type->class_name, name, strlen(name));
  return type;
}

variable_type_t *getTypeClassArray(int size, char *name) {
  variable_type_t *type = getTypeVoid();
  type->class_name = malloc(strlen(name) + 1);
  memcpy(type->class_name, name, strlen(name));
  type->basic = CLASS;
  type->array_size = size;
  return type;
}

variable_type_t *getTypeFunction(variable_type_t *return_type, int nb_param, ...) {
  variable_type_t *type = return_type;
  va_list ap;
  int i;

  if (type->array_size != -1) {
    //error
  }

  type->nb_param = nb_param;

  va_start(ap, nb_param);
  for (i = 0; i < nb_param; i++) {
    param_t *param = malloc(sizeof (param_t));
    param->type = va_arg(ap, variable_type_t*);

    if (param->type->array_size != -1 || param->type->nb_param != -1) {
      //error
    }

    TAILQ_INSERT_HEAD(type->params, param, pointers);
  }
  va_end(ap);

  return type;
}

int areSameType(variable_type_t *t1, variable_type_t *t2) {
  int res = t1->basic == t2->basic &&  t1->array_size == t2->array_size && t1->nb_param == t2->nb_param && !strcmp(t1->class_name, t2->class_name);

  param_t *p11, *p12, *p21, *p22;
  p11 = TAILQ_FIRST(t1->params);
  p21 = TAILQ_FIRST(t2->params);
  while(res && p11 != NULL && p12 != NULL) {
    p12 = TAILQ_NEXT(p11, pointers);
    p22 = TAILQ_NEXT(p21, pointers);
    res = p11->type->basic == p21->type->basic && !strcmp(p11->type->class_name, p21->type->class_name);
    p11 = p12;
    p21 = p22;
  }

  return res;
}

void freeVariableType(variable_type_t *type) {
  if (type->params != NULL) {
    param_t *p;

    while(!TAILQ_EMPTY(type->params)) {
      p = TAILQ_FIRST(type->params);
      TAILQ_REMOVE(type->params, p, pointers);
      free(p);
    }
    free(type->params);
  }

  if (type->class_name != NULL) {
    free(type->class_name);
  }

  free(type);
}

class_definition_t *getClassDefinition(char *name, int nb_member, ...) {
  va_list ap;
  int i;
  class_definition_t *class = malloc(sizeof (class_definition_t));

  class->nb_member = nb_member;
  class->class_name = malloc(strlen(name) + 1);
  memcpy(class->class_name, name, strlen(name));

  class->members = malloc(sizeof (member_list_t));
  TAILQ_INIT(class->members);

  va_start(ap, nb_member);
  for (i = 0; i < nb_member; i++) {
    member_t *member = malloc(sizeof member);
    member->type = va_arg(ap, variable_type_t*);
    TAILQ_INSERT_HEAD(class->members, member, pointers);
  }
  va_end(ap);

  return class;
}

void freeClassDefinition(class_definition_t *class) {
  if (class->members != NULL) {
    member_t *p1, *p2;
    p1 = TAILQ_FIRST(class->members);
    while(p1 != NULL) {
      p2 = TAILQ_NEXT(p1, pointers);
      free(p1);
      p1 = p2;
    }
  }
  if (class->class_name != NULL) {
    free(class->class_name);
  }
  free(class);
}
