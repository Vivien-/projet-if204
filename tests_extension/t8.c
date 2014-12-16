class C {
	int a;
}

int f(class C c) {
	return c.a;
}

int main() {
	class C c;
	int b;
	c = newC();
	c.a = 1;
	b = f(c);
	return 0;
}