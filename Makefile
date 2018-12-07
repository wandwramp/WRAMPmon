AS = wasm
LD = wlink
RM = rm -f
CC = wcc
TRIM = trim

OBJS = main.o termio.o clib.o stdio.o utils.o flih.o token.o instructions.o commands.o cli.o disassemble.o interrupts.o lenval.o micro.o ports.o gameSelect.O breakout.O rocks.O

all:	monitor.mem monitor.srec

.S.o:	$<
	$(AS) $<

.s.o:	$<
	$(AS) $<

.c.s:	$<
	$(CC) -S $<

monitor.mem:	monitor.srec
	$(TRIM) -o $@ $<

monitor.srec: $(OBJS)
	$(LD) -v -Ttext 0x80000 -Ebss 0x04000 -o $@ $(OBJS)

.PHONY: clean clobber
clean:
	$(RM) *.o *.s *~

clobber: clean
	$(RM) monitor.mem monitor.srec
