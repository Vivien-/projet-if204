int f(int n) {
  if (n>1) return f(n-1)+f(n-2);
  return 1;
}
int main() {
  printint(f(10));
  return 0;
}
