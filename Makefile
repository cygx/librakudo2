INC := ../dev/p6/fork/include
LIB := ../dev/p6/fork/bin

nqp: nqp.c libnqp.h libnqp.dll.a
	gcc -O3 -o $@ $< -L. -lnqp

libnqp.dll.a: nqp.dll

nqp.dll: libnqp.o nqpbc.o
	gcc -shared -o $@ $^ $(LIB:%=-L%) -lmoar -Wl,--out-implib,lib$@.a

libnqp.o: nqpbc.h nqpprelude.h
libnqp.o nqpbc.o: %.o: %.c
	gcc -c -O3 $(INC:%=-I%) -o $@ $<
