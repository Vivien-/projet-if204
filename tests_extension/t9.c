class C {
	int a;
}

class C my_newC(int a) {
	class C c;
	c = newC();
	c.a = a;
	return c;
}

int main() {
	class C c;
	c = my_newC(0);
	return 0;
}