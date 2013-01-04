ifneq ($(origin CC),environment)
CC := gcc
endif

cflags = -ansi -g -O0 -Wall -Wextra -DDEBUG
ifneq ($(origin CFLAGS),environment)
CFLAGS := $(cflags)
else
CFLAGS := $(cflags) $(CFLAGS)
endif

ldflags = -llua5.2
ifneq ($(origin LDFLAGS),environment)
LDFLAGS := $(ldflags)
else
LDFLAGS := $(ldflags) $(LDFLAGS)
endif

INCLUDES ?= -I/usr/include/lua5.2

all: ldbcore.so

ldbcore.o: ldbcore.c ldbcore.h
	$(CC) -fPIC -o $@ $< $(CFLAGS) $(INCLUDES) -c

ldbcore.so: ldbcore.o
	$(CC) -shared -fPIC -o $@ $<

tests.o: tests.c ldbcore.h
	$(CC) -o $@ $< $(CFLAGS) $(INCLUDES) -c

tests: tests.o
	$(CC) -o $@ $^ $(LDFLAGS)

clean:
	rm -f *.o
