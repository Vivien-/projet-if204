#include <stdlib.h>
#include <stdio.h>

#include "../src/generic_list.h"
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

  generic_list_t *params1 = new_list();
  insert(params1, getTypeInt(), sizeof(variable_type_t));
  generic_list_t *params2 = new_list();
  insert(params2, getTypeInt(), sizeof(variable_type_t));

  t1 = getTypeFunction(getTypeVoid(), params1);
  t2 = getTypeFunction(getTypeVoid(), params2);
  ASSERT(areSameType(t1, t2));
  freeVariableType(t1);
  freeVariableType(t2);

  params1 = new_list();
  params2 = new_list();
  insert(params2, getTypeInt(), sizeof(variable_type_t));
  
  t1 = getTypeFunction(getTypeVoid(), params1);
  t2 = getTypeFunction(getTypeVoid(), params2);
  ASSERT(!areSameType(t1, t2));
  freeVariableType(t1);
  freeVariableType(t2);

  generic_list_t *members = new_list();
  params1 = new_list();
  insert(params1, getTypeFloatP(), sizeof(variable_type_t));
  member_t member1;
  member1.name = "a";
  member1.type = getTypeInt();
  member_t member2;
  member2.name = "b";
  member2.type = getTypeFunction(getTypeVoid(), params1);
  insert(members, &member1, sizeof(member_t));
  insert(members, &member2, sizeof(member_t));

  class_definition_t *c = getClassDefinition("C", members);

  ASSERT(memberOffset(c, "b") == 4);

  freeClassDefinition(c);

  printf("\033[0;32mOK\033[0m (%d)\n", cpt);
  return 0;
}
