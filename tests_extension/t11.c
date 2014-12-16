class C {
	int a;
}

int main() {
	class C c[10];
	int i;
	for (i = 0; i < 10; i ++) {
		c[i] = newC();
		c[i].a = i;
	}
	return 0;
}