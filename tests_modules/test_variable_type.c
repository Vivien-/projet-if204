#include <stdlib.h>
#include <stdio.h>

#include "../src/generic_list.h"
#include "../src/variable_type.h"

#define ASSERT(X) if(!(#X)) { printf("Assert error: #X\n"); } else { cpt++; printf(".\n"); };

int main() {
  int cpt = 0;
  printf("Tests variable_type.c\n");

  variable_type_t t1;
  variable_type_t t2;
  t1.basic = t2.basic = TYPE_VOID;
  t1.pointer = t2.pointer = 0;
  t1.nb_param = t2.nb_param = -1;
  t1.array_size = t2.array_size = -1;
  ASSERT(areSameType(t1, t2));

  t1.array_size = 3;
  t2.array_size = 4;
  ASSERT(!areSameType(t1, t2));

  /*generic_list_t *params1 = new_list();
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
  
  t1 = getTypeFunction(getT  ASSERT(areSameType(t1, t2));
ypeVoid(), params1);
  t2 = getTypeFunction(getTypeVoid(), params2);
  ASSERT(!areSameType(t1, t2));
  freeVariableType(t1);
  freeVariableType(t2);*/

  generic_list_t members;
  TAILQ_INIT(&members);
  declarator_t member1;
  member1.name = "a";
  member1.type.basic = TYPE_INT;
  member1.type.array_size = 1;
  member1.type.pointer = 0;
  declarator_t member2;
  member2.name = "b";
  member2.type.basic = TYPE_FLOAT;
  member2.type.array_size = 1;
  member2.type.pointer = 0;
  insert(&members, &member1, sizeof(declarator_t));
  insert(&members, &member2, sizeof(declarator_t));

  class_definition_t c;
  c.class_name = "C";
  c.members = members;

  ASSERT(member_offset(&c, "b") == 4);

  printf("\033[0;32mOK\033[0m (%d)\n", cpt);
  return 0;
}
