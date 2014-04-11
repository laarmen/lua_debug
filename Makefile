ifneq ($(origin CC),environment)
CC := gcc
endif

cflags = -ansi -g -O0 -Wall -Wextra -DDEBUG
ifneq ($(origin CFLAGS),environment)
CFLAGS := $(cflags)
else
CFLAGS := $(cflags) $(CFLAGS)
endif

ifneq ($(origin PREFIX),environment)
PREFIX := /usr/local
else
PREFIX := $(shell readlink -m $(PREFIX))
endif

ifneq ($(origin CPPFLAGS),environment)
CPPFLAGS := "-DPREFIX=\"$(PREFIX)\""
else
CPPFLAGS := "-DPREFIX=\"$(PREFIX)\"" $(CPPFLAGS)
endif

ldflags = -llua5.2
ifneq ($(origin LDFLAGS),environment)
LDFLAGS := $(ldflags)
else
LDFLAGS := $(ldflags) $(LDFLAGS)
endif

INCLUDES ?= -I/usr/include/lua5.2

all: libldbcore.so

install: all
	mkdir -p $(PREFIX)/lib $(PREFIX)/share/ldb $(PREFIX)/include
	install -m 644 libldbcore.so $(PREFIX)/lib/
	install -m 644 ldbcore.h $(PREFIX)/include/
	install -m 644 ldb.lua $(PREFIX)/share/ldb/
	install -m 755 ldb.py $(PREFIX)/share/ldb/

ldbcore.o: ldbcore.c ldbcore.h
	$(CC) -fPIC -o $@ $< $(CPPFLAGS) $(CFLAGS) $(INCLUDES) -c

libldbcore.so: ldbcore.o
	$(CC) -shared -fPIC -o $@ $<

tests.o: tests.c ldbcore.h libldbcore.so
	$(CC) -o $@ $< $(CFLAGS) $(INCLUDES) -c

tests: tests.o
	$(CC) -o $@ $^ -L. -lldbcore $(LDFLAGS) -Wl,-rpath .

clean:
	rm -f *.o
