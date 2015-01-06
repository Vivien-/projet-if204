#include <stdio.h>
#include <stdlib.h>

#include "../src/name_space.h"

#define ASSERT(X) if(!(#X)) { printf("Assert error: #X\n"); } else { cpt++; printf(".\n"); };

int main() {
  int cpt = 0;
  printf("Tests name_space.c\n");

  name_space_stack_t *nsp = new_name_space_stack();

  ASSERT(current_name_space_is_root(nsp));

  ASSERT(is_defined("a", nsp) == NULL);

  ASSERT(get_top_stack_size(nsp) == 0);

  stack_new_name_space(nsp);

  ASSERT(!current_name_space_is_root(nsp));

  variable_type_t t;

  insert_in_current_name_space("a", new_variable(t, 0), nsp);

  ASSERT(is_defined("a", nsp) != NULL);

  ASSERT(get_top_stack_size(nsp) == 4);

  stack_new_name_space(nsp);

  ASSERT(is_defined("a", nsp) != NULL);

  ASSERT(get_top_stack_size(nsp) == 0);
  
  pop_name_space(nsp);
  pop_name_space(nsp);
  
  ASSERT(current_name_space_is_root(nsp));

  ASSERT(is_defined("a", nsp) == NULL);

  free_name_space_stack(nsp);

  class_name_space_t *cnp = new_class_name_space();
  
  class_definition_t c;
  c.class_name = "C";

  insert_in_class_name_space("C", &c, cnp);

  ASSERT(find_in_class_name_space("C", cnp) != NULL);

  free_class_name_space(cnp);

  printf("\033[0;32mOK\033[0m (%d)\n", cpt);
  return 0;
}
