LEX=lex
YACC=bison
CFLAGS=-Wall
CC=gcc
SRC=
OUT=compiler

all: parser

parser: parser.c scanner.c $(SRC)
	$(CC) $(CFLAGS) -o $(OUT) $^

parser.c: parser.y
	$(YACC) -o $@ --defines=parser.tab.h $^

%.c:%.l
	$(LEX) -o $@ $^

tests:
	$(MAKE) parser
	for i in `ls ../tests/*.c`; do echo $$i; ./$(OUT) $$i; done
	for i in `ls ../tests_extension/*.c`; do echo $$i; ./$(OUT) $$i; done

clean:
	rm -f $(OUT) parser.c parser.tab.h parser.tab.c scanner.c *~
