#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "../src/generic_list.h"

#define ASSERT(X) if(!(#X)) { printf("Assert error: #X\n"); } else { cpt++; printf(".\n"); };

int main() {
  int cpt = 0;
  printf("Tests generic_list.c\n");

  char *str = "ab";
  generic_list_t *list = new_list();
  insert(list, str, strlen(str));
  generic_element_t *e = TAILQ_FIRST(list);
  char *res = (char *)(e->data);
  ASSERT(strcmp(res, "ab") == 0);
  free_list(list, free);
  printf("\033[0;32mOK\033[0m (%d)\n", cpt);
  return 0;
}
