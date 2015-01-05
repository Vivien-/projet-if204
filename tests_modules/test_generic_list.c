#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "../src/generic_list.h"

#define ASSERT(X) if(!(#X)) { printf("Assert error: #X\n"); } else { cpt++; printf(".\n"); };

int main() {
  int cpt = 0;
  printf("Tests generic_list.c\n");

  char *str = "a";
  generic_list_t *list = new_list();
  insert(list, str, strlen(str));
  generic_element_t *e = TAILQ_FIRST(list);
  char *res = (char *)(e->data);
  ASSERT(strcmp(res, "a") == 0);
  printf("%s\n", res);
  free_list(list, free);
  printf("OK (%d)\n", cpt);
  return 0;
}
