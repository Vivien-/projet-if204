class C {
	int a;
	int m() {
		return 0;
	}
}

int main() {
	class C c;
	int b;
	c = newC();
	c.a = 1;
	b = c.a + c.m();
	return 0;
}