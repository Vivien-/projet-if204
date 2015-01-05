#include <stdio.h>
#include <stdlib.h>

#include "../src/name_space.h"

#define ASSERT(X) if(!(#X)) { printf("Assert error: #X\n"); } else { cpt++; printf(".\n"); };

int main() {
  int cpt = 0;
  printf("Tests name_space.c\n");

  name_space_stack_t *nsp = newNameSpaceStack();

  ASSERT(isRoot(nsp));

  ASSERT(findInNameSpace("a", nsp) == NULL);

  stackNewNameSpace(nsp);

  ASSERT(!isRoot(nsp));

  insertInCurrentNameSpace("a", newVariable(getTypeInt(), 0), nsp);

  ASSERT(findInNameSpace("a", nsp) != NULL);

  stackNewNameSpace(nsp);

  ASSERT(findInNameSpace("a", nsp) != NULL);

  popNameSpace(nsp);
  popNameSpace(nsp);
  
  ASSERT(isCurrentNameSpaceRoot(nsp));

  ASSERT(findInNameSpace("a", nsp) == NULL);

  freeNameSpaceStack(nsp);

  class_name_space_t *cnp = newClassNameSpace();
  
  insertInClassNameSpace("C", getClassDefinition("C", new_list()), cnp);

  ASSERT(findInClassNameSpace("C", cnp) != NULL);

  freeClassNameSpace(cnp);

  printf("OK (%d)\n", cpt);
  return 0;
}
