class C {
	int a;
	int m(int b) {
		return this.a + b;
	}
}

int main() {
	class C c;
	int d;
	c = newC();
	c.a = 1;
	d = c.m(1);
	return 0;
}