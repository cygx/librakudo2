ifeq ($(PREFIX),)
$(error variable PREFIX not defined)
endif

PERL6 := $(PREFIX)/bin/perl6

INC := $(PREFIX)/include
LIB := $(PREFIX)/bin

API_H := $(PREFIX)/include/moar/api.h
MOARLIB := $(PREFIX)/bin/libmoar.dll.a

# RAKUDOBUG!
export MVM_SPESH_DISABLE = 1

nqp: nqp.c libnqp.h libnqp.dll.a
	gcc -O3 -o $@ $< -L. -lnqp

bc:
	perl bc.pl nqp $(PREFIX)/share/nqp/lib

prelude:
	$(PERL6) prelude.p6 nqpbc.index

libnqp.dll.a: nqp.dll

nqp.dll: libnqp.o nqpbc.o $(MOARLIB)
	gcc -shared -o $@ $^ $(LIB:%=-L%) -lmoar -Wl,--out-implib,lib$@.a

libnqp.o: nqpbc.h nqpprelude.h $(API_H)
libnqp.o nqpbc.o: %.o: %.c
	gcc -c -O3 $(INC:%=-I%) -o $@ $<
