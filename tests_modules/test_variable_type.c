#include <stdlib.h>
#include <stdio.h>

#include "../src/variable_type.h"

#define ASSERT(X) if(!(#X)) { printf("Assert error: #X\n"); } else { cpt++; printf(".\n"); };

int main() {
  int cpt = 0;
  printf("Tests variable_type.c\n");

  variable_type_t *t1 = getTypeVoid();
  variable_type_t *t2 = getTypeVoid();
  ASSERT(areSameType(t1, t2));
  freeVariableType(t1);
  freeVariableType(t2);

  t1 = getTypeVoidArray(4);
  t2 = getTypeVoidArray(5);
  ASSERT(!areSameType(t1, t2));
  freeVariableType(t1);
  freeVariableType(t2);

  t1 = getTypeClass("C");
  t2 = getTypeClass("C");
  ASSERT(areSameType(t1, t2));
  freeVariableType(t1);
  freeVariableType(t2);

  param_list_t *params1 = newParamList();
  insertNewParam(params1, getTypeInt());
  param_list_t *params2 = newParamList();
  insertNewParam(params2, getTypeInt());

  t1 = getTypeFunction(getTypeVoid(), params1);
  t2 = getTypeFunction(getTypeVoid(), params2);
  ASSERT(areSameType(t1, t2));
  freeVariableType(t1);
  freeVariableType(t2);

  params1 = newParamList();
  params2 = newParamList();
  insertNewParam(params2, getTypeInt());
  
  t1 = getTypeFunction(getTypeVoid(), params1);
  t2 = getTypeFunction(getTypeVoid(), params2);
  ASSERT(!areSameType(t1, t2));
  freeVariableType(t1);
  freeVariableType(t2);

  member_list_t *members = newMemberList();
  params1 = newParamList();
  insertNewParam(params1, getTypeFloatP());
  insertNewMember(members, "a", getTypeInt());
  insertNewMember(members, "b", getTypeFunction(getTypeVoid(), params1));

  class_definition_t *c = getClassDefinition("C", members);

  ASSERT(memberOffset(c, "b") == 4);

  freeClassDefinition(c);

  declaration_list_t *declarations = newDeclarationList();
  declaration_t d;
  d.name = "a";

  insertDeclaration(declarations, &d);
  
  freeDeclarationList(declarations);

  printf("OK (%d)\n", cpt);
  return 0;
}
