#include <stdio.h>
#include <stdlib.h>

#include "../src/name_space.h"

#define ASSERT(X) if(!(#X)) { printf("Assert error: #X\n"); } else { cpt++; printf(".\n"); };

int main() {
  int cpt = 0;
  printf("Tests name_space.c\n");

  name_space_t *nsp = new_name_space();

  ASSERT(nsp != NULL);

  ASSERT(is_defined("a", nsp) == NULL);

  ASSERT(nsp->size == 0);

  variable_type_t t;

  insert_in_name_space("a", new_variable(t, 0), nsp);

  ASSERT(is_defined("a", nsp) != NULL);

  ASSERT(nsp->size == 4);

  ASSERT(is_defined("a", nsp) != NULL);

  free_name_space(nsp);

  class_name_space_t *cnp = new_class_name_space();
  
  class_definition_t c;
  c.class_name = "C";

  insert_in_class_name_space("C", &c, cnp);

  ASSERT(find_in_class_name_space("C", cnp) != NULL);

  free_class_name_space(cnp);

  printf("\033[0;32mOK\033[0m (%d)\n", cpt);
  return 0;
}
