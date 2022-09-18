;------------------------------------------------------------------------------------------------------------
; stack_test.asm - Breakpoint/Stack/Register test routine for the Z80-Retro! SBC
;------------------------------------------------------------------------------------------------------------
; Insert breakpoints at various locations to view values of memory, registers, flags and stack
;
;	Editor set for tabstops = 4
;	Build - use info:
;	-> supplied Makefile requires srec_cat utility in path to convert .bin to .hex files
;	-> make stack_test
;	-> open resulting .hex file in a text editor and copy all contents
;	-> select [L] 'Hexload' command in monitor
;	-> paste .hex file text in your terminal window
;	-> view the stack_test.lst file to locate addresses for breakpoints. Choose opcode not operand addresses
;	-> select [U] 'Break at' command and type 1000 to set an initial breakpoint at 0x1000
;	-> select [G] 1000 command to begin execution for stack_test routine up to a breakpoint and view results
;	-> enter [LLLL] from the submenu (substitute new desired breakpoint hex address for the LLLL)
;	-> select the [Enter] subcommand to execute the rest of the code without more breakpoints
;	-> select the [Space] subcommand to execute a 'Dump' memory command. You provide desired address ranges
;	-> select the [Esc] subcommand to abort back to main monitor command prompt
;------------------------------------------------------------------------------------------------------------

	include 'retromon.sym'		; Get symbol table from retromon.asm build
	
	ORG		0x1000				; Test routine location

	LD		SP,.LOCAL_STACK		; Setup local stack

	XOR		A					; Set zero flag, even parity flag, A = 0

	ADD   	A,1					; Reset all flags

	SUB		2					; Set carry, sign and half-carry flags

	LD		A,0xAA				; Fill registers with identifying values
	LD		BC,0xBCCB
	LD		DE,0xDEED

	LD		HL,0x1234
	PUSH	HL					; Test stack

	LD		HL,0x5678
	PUSH	HL					; More stack...

	LD		HL,0xFEEF			; More registers ...
	LD		IX,0xA11A
	LD		IY,0xB11B

	EX		AF,AF'				; Swap AF <-> AF'
	EX		AF,AF'				; Swap back

	EXX							; Swap BC DE HL <-> BC' DE' HL'
	EXX							; Swap back

	POP		HL					; Restore local stack
	POP		DE

	CALL	DSPMSG				; Display finished message
	DEFB	CR,LF,'Stack_test finished...',BIT7+' '

	JP		START				; Back to command loop in monitor
								; Monitor restores it's own stack
								;	so no need to here

	DEFS	32					; Local stack area
	.LOCAL_STACK:

	END
	