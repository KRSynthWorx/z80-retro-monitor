# Makefile for building the Z80-Retro! monitor - retromon.asm
# and a simple stack test routine - stack_test.asm

retromon: retromon.bin
stack_test: stack_test.bin
retromon.sym: retromon.bin

retromon.bin: retromon.asm
	z80asm -i retromon.asm -o retromon.bin --list=retromon.lst --label=retromon.sym
	
stack_test.bin: stack_test.asm retromon.sym
	z80asm -i stack_test.asm -o stack_test.bin --list=stack_test.lst --label=stack_test.sym
	srec_cat stack_test.bin -binary -offset 0x1000 -o stack_test.hex -intel

flash: retromon.bin
	flash < retromon.bin

clean:
	rm -f *.lst *.sym *.bin *.hex
