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
  type->params = malloc(sizeof (param_list_t));
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
  type->params = malloc(sizeof (param_list_t));
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

variable_type_t *getTypeFunction(variable_type_t *return_type, param_list_t *param_list) {
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

int getSize(variable_type_t *t) {
  return 4 * (t->pointer == 1 || t->basic == TYPE_CLASS ? 2 : 1) * (t->array_size == -1 ? 1 : t->array_size);
}

void freeVariableType(variable_type_t *type) {
  if (type == NULL) return;

  if (type->params != NULL) {
    freeParamList(type->params);
  }

  if (type->class_name != NULL) {
    free(type->class_name);
  }

  free(type);
}

class_definition_t *getClassDefinition(char *name, member_list_t *member_list) {
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

void freeClassDefinition(class_definition_t *class) {
  if (class == NULL) return;

  if (class->members != NULL) {
    freeMemberList(class->members);
  }

  if (class->class_name != NULL) {
    free(class->class_name);
  }
  free(class);
}

param_list_t *newParamList() {
  param_list_t *param_list = malloc(sizeof (param_list_t));
  TAILQ_INIT(param_list);
  return param_list;
}

void freeParamList(param_list_t *param_list) {
  param_t *p;
  while(!TAILQ_EMPTY(param_list)) {
    p = TAILQ_FIRST(param_list);
    freeVariableType(p->type);
    TAILQ_REMOVE(param_list, p, pointers);
    free(p);
  }
  free(param_list);
}

void insertNewParam(param_list_t *param_list, variable_type_t *type) {
  param_t *param = malloc(sizeof (param_t));
  param->type = type;
  TAILQ_INSERT_HEAD(param_list, param, pointers);
}

member_list_t *newMemberList() {
  member_list_t *member_list = malloc(sizeof (member_list_t));
  TAILQ_INIT(member_list);
  return member_list;
}

void freeMemberList(member_list_t *member_list) {
  member_t *m;
  while(!TAILQ_EMPTY(member_list)) {
    m = TAILQ_FIRST(member_list);
    freeVariableType(m->type);
    free(m->name);
    TAILQ_REMOVE(member_list, m, pointers);
    free(m);
  }
  free(member_list);
}

void insertNewMember(member_list_t *member_list, char *name, variable_type_t *type) {
  member_t *member = malloc(sizeof (member_t));
  member->name = strdup(name);
  member->type = type;
  TAILQ_INSERT_HEAD(member_list, member, pointers);
}

declaration_list_t *newDeclarationList() {
  declaration_list_t *declaration_list = malloc(sizeof (declaration_list_t));
  TAILQ_INIT(declaration_list);
  return declaration_list;
}

void freeDeclarationList(declaration_list_t *declaration_list) {
  declaration_t *d;
  while(!TAILQ_EMPTY(declaration_list)) {
    d = TAILQ_FIRST(declaration_list);
    free(d->name);
    TAILQ_REMOVE(declaration_list, d, pointers);
    free(d);
  }
  free(declaration_list);
}

void insertDeclaration(declaration_list_t *declaration_list, declaration_t *declaration) {
  declaration_t *new_declaration = malloc(sizeof (declaration_t));
  new_declaration->name = strdup(declaration->name);
  new_declaration->pointer = declaration->pointer;
  new_declaration->array_size = declaration->array_size;
  TAILQ_INSERT_HEAD(declaration_list, new_declaration, pointers);
}

variable_t *newVariable(variable_type_t *type, int addr) {
  variable_t *var = malloc(sizeof (variable_t));
  var->type = type;
  var->addr = addr;
  return var;
}

void freeVariable(variable_t *var) {
  freeVariableType(var->type);
  free(var);
}
