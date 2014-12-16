// Error
int f(int a,float b) {
  return a;
}
int main() {
  int a;
  float b;
  a=3;
  b=1.2;
  a=f(b,a);
  return 0;
}
