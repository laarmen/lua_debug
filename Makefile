ifneq ($(origin CC),environment)
CC := gcc
endif

cflags = -ansi -g -O0 -Wall -Wextra
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

all: tests

lua_debug.o: lua_debug.c lua_debug.h
	$(CC) -o $@ $< $(CFLAGS) $(INCLUDES) -c

tests.o: tests.c lua_debug.h
	$(CC) -o $@ $< $(CFLAGS) $(INCLUDES) -c

tests: tests.o lua_debug.o
	$(CC) -o $@ $^ $(LDFLAGS)

clean:
	rm -f *.o
