#include <stdlib.h>
#include <stdio.h>

#include "../src/variable_type.h"

#define ASSERT(X) if(!(#X)) { printf("Assert error : #X\n"); } else { cpt++; printf(".\n"); };

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

  t1 = getTypeFunction(getTypeVoid(), 1, getTypeInt());
  t2 = getTypeFunction(getTypeVoid(), 1, getTypeInt());
  ASSERT(areSameType(t1, t2));
  freeVariableType(t1);
  freeVariableType(t2);
  
  t1 = getTypeFunction(getTypeVoid(), 0);
  t2 = getTypeFunction(getTypeVoid(), 1, getTypeInt());
  ASSERT(!areSameType(t1, t2));
  freeVariableType(t1);
  freeVariableType(t2);

  class_definition_t *c = getClassDefinition("C", 2, getTypeInt(), getTypeFunction(getTypeVoid(), 1, getTypeFloatP()));
  freeClassDefinition(c);

  printf("OK (%d)\n", cpt);
  return 0;
}
