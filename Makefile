ifeq ($(PREFIX),)
$(error variable PREFIX not defined)
endif

PERL6 := $(PREFIX)/bin/perl6
NQP   := $(PREFIX)/bin/nqp

INC := $(PREFIX)/include
LIB := $(PREFIX)/bin

API_H := $(PREFIX)/include/moar/api.h
MOARLIB := $(PREFIX)/bin/libmoar.dll.a

# RAKUDOBUG!
export MVM_SPESH_DISABLE = 1

nqp: nqp.c libnqp.a  $(MOARLIB)
	gcc -O3 -o $@ $^

bc:
	perl bc.pl nqp $(PREFIX)/share/nqp/lib

prelude: MoarASM.moarvm
	$(PERL6) prelude.p6 nqpbc.index

MoarASM.moarvm: %.moarvm: %.nqp
	$(NQP) --target=mbc --output=$@ $<

libnqp.a: libnqp.o nqpbc.o
	ar rcs $@ $^

libnqp.o: nqpbc.h nqpprelude.h $(API_H)
libnqp.o nqpbc.o: %.o: %.c
	gcc -c -O3 $(INC:%=-I%) -o $@ $<
