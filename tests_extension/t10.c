class C {}

int main() {
	class C c1, c2;
	c1 = newC();
	c2 = newC();
	c1 = c2;
	return 0;
}