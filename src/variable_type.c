#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#include "variable_type.h"

variable_type_t *getType(enum BASIC_TYPE basic, declaration_t *declaration){
  variable_type_t *type = malloc(sizeof (variable_type_t));
  type->basic = basic;
  type->array_size = declaration->array_size;
  type->pointer = declaration->pointer;
  type->nb_param = -1;
  type->nb_param = -1;
  type->params = malloc(sizeof (generic_list_t));
  TAILQ_INIT(type->params);
  type->class_name = NULL;
  return type;
}

variable_type_t *getTypeVoid() {
  variable_type_t *type = malloc(sizeof (variable_type_t));
  type->basic = TYPE_VOID;
  type->array_size = -1;
  type->nb_param = -1;
  type->pointer = 0;
  type->params = malloc(sizeof (generic_list_t));
  TAILQ_INIT(type->params);
  type->class_name = NULL;
  return type;
}

variable_type_t *getTypeVoidP() {
  variable_type_t *type = getTypeVoid();
  type->basic = TYPE_VOID;
  type->pointer = 1;
  return type;
}

variable_type_t *getTypeInt() {
  variable_type_t *type = getTypeVoid();
  type->basic = TYPE_INT;
  return type;
}

variable_type_t *getTypeFloat() {
  variable_type_t *type = getTypeVoid();
  type->basic = TYPE_FLOAT;
  return type;
}

variable_type_t *getTypeIntP() {
  variable_type_t *type = getTypeVoid();
  type->basic = TYPE_INT;
  type->pointer = 1;
  return type;
}

variable_type_t *getTypeFloatP() {
  variable_type_t *type = getTypeVoid();
  type->basic = TYPE_FLOAT;
  type->pointer = 1;
  return type;
}

variable_type_t *getTypeVoidArray(int size) {
  variable_type_t *type = getTypeVoid();
  type->basic = TYPE_VOID;
  type->array_size = size;
  return type;
}

variable_type_t *getTypeVoidPArray(int size) {
  variable_type_t *type = getTypeVoid();
  type->basic = TYPE_VOID;
  type->array_size = size;
  type->pointer = 1;
  return type;
}

variable_type_t *getTypeIntArray(int size) {
  variable_type_t *type = getTypeVoid();
  type->basic = TYPE_INT;
  type->array_size = size;
  return type;
}

variable_type_t *getTypeFloatArray(int size) {
  variable_type_t *type = getTypeVoid();
  type->basic = TYPE_FLOAT;
  type->array_size = size;
  return type;
}

variable_type_t *getTypeIntPArray(int size) {
  variable_type_t *type = getTypeVoid();
  type->basic = TYPE_INT;
  type->array_size = size;
  type->pointer = 1;
  return type;
}

variable_type_t *getTypeFLoatPArray(int size) {
  variable_type_t *type = getTypeVoid();
  type->basic = TYPE_FLOAT;
  type->array_size = size;
  type->pointer = 1;
  return type;
}

variable_type_t *getTypeClass(char *name) {
  variable_type_t *type = getTypeVoid();
  type->basic = TYPE_CLASS;
  type->class_name = malloc(strlen(name) + 1);
  memcpy(type->class_name, name, strlen(name));
  return type;
}

variable_type_t *getTypeClassArray(int size, char *name) {
  variable_type_t *type = getTypeVoid();
  type->class_name = malloc(strlen(name) + 1);
  memcpy(type->class_name, name, strlen(name));
  type->basic = TYPE_CLASS;
  type->array_size = size;
  return type;
}

variable_type_t *getTypeFunction(variable_type_t *return_type, generic_list_t *param_list) {
  variable_type_t *type = return_type;
  param_t *param;

  if (type->array_size != -1) {
    //error
  }

  type->nb_param = 0;
  TAILQ_FOREACH(param, param_list, pointers) {
    type->nb_param++;
  }
  type->params = param_list;

  return type;
}

int areSameType(variable_type_t *t1, variable_type_t *t2) {
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

int getSize(variable_type_t *t) {
  return 4 * (t->pointer == 1 || t->basic == TYPE_CLASS ? 2 : 1) * (t->array_size == -1 ? 1 : t->array_size);
}

void freeVariableType(void *t) {
  variable_type_t* type = (variable_type_t*)t;
  if (type == NULL) return;

  if (type->params != NULL) {
    free_list(type->params, free);
  }

  if (type->class_name != NULL) {
    free(type->class_name);
  }

  free(type);
}

class_definition_t *getClassDefinition(char *name, generic_list_t *member_list) {
  class_definition_t *class = malloc(sizeof (class_definition_t));

  class->class_name = strdup(name);
  class->members = member_list;
  return class;
}

int memberOffset(class_definition_t *class, char *member_name) {
  int offset = 0;
  member_t *member;
  
  TAILQ_FOREACH(member, class->members, pointers) {
    if (strcmp(member_name, member->name) == 0) {
      return offset;
    }
    offset += getSize(member->type);
  }

  return -1;
}

int getClassSize(class_definition_t *class) {
  int size = 0;
  member_t *m;
  TAILQ_FOREACH(m, class->members, pointers) {
    if (m->type->nb_param == -1) {
      size += getSize(m->type);
    }
  }
  return size;
}

void freeClassDefinition(void *c) {
  class_definition_t *class = (class_definition_t*) c;
  if (class == NULL) return;

  if (class->members != NULL) {
    free_list(class->members, free);
  }

  if (class->class_name != NULL) {
    free(class->class_name);
  }
  free(class);
}

variable_t *newVariable(variable_type_t *type, int addr) {
  variable_t *var = malloc(sizeof (variable_t));
  var->type = type;
  var->addr = addr;
  return var;
}

void freeVariable(void *v) {
  variable_t *var = (variable_t*) v;
  freeVariableType(var->type);
  free(var);
}
