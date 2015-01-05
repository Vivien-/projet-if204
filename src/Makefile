LEX=lex
YACC=bison
CFLAGS=-Wall
CC=gcc
SRC=generic_list.c variable_type.c name_space.c
OUT=compiler

all: parser

parser: parser.c scanner.c $(SRC)
	@$(CC) -g $(CFLAGS) -o $(OUT) $^

parser.c: parser.y
	@$(YACC) -o $@ --defines=parser.tab.h $^

scanner.c: scanner.l
	@$(LEX) -o $@ $^

tests:
	@$(CC) -g $(CFLAGS) -o test_generic_list ../tests_modules/test_generic_list.c generic_list.c && ./test_generic_list
	@$(CC) -g $(CFLAGS) -o test_variable_type ../tests_modules/test_variable_type.c generic_list.c variable_type.c && ./test_variable_type
	@$(CC) -g $(CFLAGS) -o test_name_space ../tests_modules/test_name_space.c generic_list.c variable_type.c name_space.c && ./test_name_space
	@$(MAKE) parser
	for i in `ls ../tests/*.c`; do echo $$i; ./$(OUT) $$i && $(CC) $${i%.*}.s && ./a.out; if [ $$? -eq 0 ]; then echo -e "\033[0;32mOK\033[0m ( valeur de retour :" $$? ")"; else echo -e "\033[0;31mFailed\033[0m"; fi; echo -ne "\n"; done
	for i in `ls ../tests_extension/*.c`; do echo $$i; ./$(OUT) $$i && $(CC) $${i%.*}.s && ./a.out; if [ $$? -eq 0 ]; then echo -e "\033[0;32mOK\033[0m ( valeur de retour :" $$? ")"; else echo -e "\033[0;31mFailed\033[0m"; fi; echo -ne "\n"; done

clean:
	rm -f $(OUT) test_variable_type test_name_space parser.c parser.tab.h parser.tab.c scanner.c *~
