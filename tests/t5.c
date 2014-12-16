int *malloc_int(int x);
int main() {
  int *a;
  a = malloc_int(1000);
  a[10]=3;
  return 0;
}
