class A {
  int a;
}

class C {
  int c;
  class A d;
  class A getA() {
    return this.d;
  }
}

int main() {
  class C c;
  c = newC();
  c.d.a = 0;
  c.getA().a = 1;
  return 0;
}
