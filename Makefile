AS = wasm
LD = wlink
RM = rm -f
CC = wcc

OBJS = main.o termio.o clib.o stdio.o utils.o flih.o token.o instructions.o commands.o cli.o disassemble.o interrupts.o lenval.o micro.o ports.o

.S.o:	$<
	$(AS) $<

.s.o:	$<
	$(AS) $<

.c.s:	$<
	$(CC) -S $<

all:	monitor.srec

monitor.srec: $(OBJS)
	$(LD) -v -Ttext 0x80000 -Ebss 0x20000 -o $@ $(OBJS)

clean:
	$(RM) monitor.srec *.o *~