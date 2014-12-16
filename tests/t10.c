int main() {
  int a;
  int b;
  a=4;
  {
    int c;
    c=5;
    {
      int d;
      d=c+a;
    }
    c=c+4;
  }
  a=a+1;
  return 0;
}
