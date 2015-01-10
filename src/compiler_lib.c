#include <stdlib.h>
#include <stdio.h>

int fct_extern(int a) {
  return a;
}

int *malloc_int(int size) {
  return malloc(sizeof (int) * size);
}

void print_int(int x) {
  printf("%d\n", x);
}

void print_float(float x) {
  printf("%f\n", x);
}
