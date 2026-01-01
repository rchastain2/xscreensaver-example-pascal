
CC = gcc
CFLAGS = -Wall
CLIBS = -lX11 -lm -lcairo
PROGRAM := ball

default: $(PROGRAM)

%: %.c vroot.h
	$(CC) $(CFLAGS) -o $@ $< $(CLIBS)

.PHONY: clean run

clean:
	rm $(PROGRAM)

run: $(PROGRAM)
	./$(PROGRAM) --debug
