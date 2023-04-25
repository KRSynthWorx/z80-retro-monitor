;**************************************************************************
;
;			Z 8 0 - R E T R O !  U T I L I T Y  M O N I T O R
;
;**************************************************************************
;	retromon.asm v1.8 - a monitor for the <jb> Z80-Retro! SBC
;	Kenny Maytum - KRSynthWorx - April 25th, 2023
;**************************************************************************

;**************************************************************************
;							L I C E N S E S
;**************************************************************************
;
;	This utility monitor...
;
;	Copyright (C) 2022,2023 Kenny Maytum
;	https://github.com/KRSynthWorx/z80-retro-monitor 
;
;	This library is free software; you can redistribute it and/or
;	modify it under the terms of the GNU Lesser General Public
;	License as published by the Free Software Foundation; either
;	version 2.1 of the License, or (at your option) any later version.
;
;	This library is distributed in the hope that it will be useful,
;	but WITHOUT ANY WARRANTY; without even the implied warranty of
;	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;	Lesser General Public License for more details.
;
;	You should have received a copy of the GNU Lesser General Public
;	License along with this library; if not, write to the Free Software
;	Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
;	02110-1301 USA
;
;	https://www.gnu.org/licenses/old-licenses/lgpl-2.1.html
;
;--------------------------------------------------------------------------
;
;	The SPI/SD Card library algorithms provided by John Winans...
;
;	Copyright (C) 2021,2022 John Winans
;	https://github.com/Z80-Retro/2063-Z80-cpm
;
;	This library is free software; you can redistribute it and/or
;	modify it under the terms of the GNU Lesser General Public
;	License as published by the Free Software Foundation; either
;	version 2.1 of the License, or (at your option) any later version.
;
;	This library is distributed in the hope that it will be useful,
;	but WITHOUT ANY WARRANTY; without even the implied warranty of
;	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;	Lesser General Public License for more details.
;
;	You should have received a copy of the GNU Lesser General Public
;	License along with this library; if not, write to the Free Software
;	Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
;	02110-1301 USA
;
;	https://www.gnu.org/licenses/old-licenses/lgpl-2.1.html
;
;**************************************************************************

;**************************************************************************
;						A C K N O W L E D G E M E N T S
;**************************************************************************
;
;	This monitor utility is inspired by and based on the 8080 assembler
;	1977-1979 versions of the Vector Graphic Inc. monitors by R. S. Harp.
;
;	Additional modifications, additions, improvements, and inspiration from
;	ideas and works by:
;	Mike Douglas:		https://deramp.com
;	Martin Eberhard:	https://en.wikipedia.org/wiki/Martin_Eberhard
;
;	Z80-Retro! SBC, FLASH programmer hardware, SPI and SD card library
;	routines closely based on work by John Winans.
;
;	Z80-Retro! project:	https://github.com/Z80-Retro/2063-Z80
;	FLASH programmer:	https://github.com/Z80-Retro/2065-Z80-programmer
;	CP/M BIOS project:	https://github.com/Z80-Retro/2063-Z80-cpm
;
;	John's Basement <jb> YouTube Channel:
;	https://www.youtube.com/c/JohnsBasement
;
;--------------------------------------------------------------------------
;
;	Many thanks to the above listed people that have made this
;	project possible!
;
;	Kenny Maytum
;	KRSynthWorx
;	https://github.com/KRSynthWorx/z80-retro-monitor
;
;**************************************************************************

;--------------------------------------------------------------------------
;			Build Commands | Command Summary | Using Retromon
;--------------------------------------------------------------------------
;
;	Set editor for tabstops = 4
;	You can also set Github tabstops to 4 permanently from the upper right
;	hand corner->profile icon dropdown->Settings->Appearance->
;	Tab size preference
;
;	Build using z80asm v1.8 running on a Raspberry Pi:
;		Source available at https://www.nongnu.org/z80asm
;		or install binary via command line: sudo apt-get install z80asm
;
;	Flash programmer running on a Rasberry Pi:
;		https://github.com/Z80-Retro/2065-Z80-programmer
;
;	***********************************************************************
;	***********************************************************************
;	* NOTE: Before building, set the SRAM size in the EQU at line 313     *
;	* The default configuration (EQU 0) is for a 512K SRAM chip installed *
;	*                                                                     *
;	* NOTE: Enable/Disable SD card partition 1 auto boot at line 314      *
;	* The default configuration (EQU 1) is auto boot enable               *
;	***********************************************************************
;	***********************************************************************
;
;	Build using the included Makefile (assumes flash utility is in your PATH)
;	make			; Build retromon.bin only
;	make flash		; Build retromon.bin and execute flash utility
;	make stack_test	; Build a program to test breakpoint/stack display
;	make clean		; Remove all built items
;
;	-Command Summary-
;
;	A -> D select low 32k RAM bank
;	B -> D boot SD partition
;	C -> SSSS FFFF DDDD compare blocks
;	D -> SSSS FFFF dump hex and ASCII
;	E -> SSSS FFFF DDDD exchange block
;	F -> SSSS FFFF DD DD two byte search
;	G -> LLLL go to and execute
;	H -> Command help
;	I -> PP input from I/O port
;	J -> SSSS FFFF dump Intel hex file
;	K -> SSSS FFFF DD fill with constant
;	L -> Load Intel hex file
;	M -> SSSS FFFF DDDD copy block
;	N -> Non-destructive memory test
;	O -> PP DD output to port
;	P -> LLLL program memory
;	Q -> SSSS FFFF compute checksum
;	R -> BBBB BBBB DDDD read SD block (512 bytes)
;	S -> SSSS FFFF DD one byte search
;	T -> SSSS FFFF destructive memory test
;	U -> LLLL set breakpoint
;	V -> Clear breakpoint
;	W -> LLLL BBBB BBBB write SD block (512 bytes)
;	X -> Reboot monitor
;	Y -> DDDD CCCC load binary file
;	Z -> LLLL CCCC dump binary file
;
;	<SSSS>Start Address <FFFF>Finish Address
;	<DDDD>Destination Address <D/DD>Data <PP>Port
;	<BBBB BBBB>32-bit SD Block <LLLL>Location Address
;	<CCCC>Size <Esc/Ctrl-c>Abort <Space>Pause
;
;	Using Retromon:
;
;	OK, please bear with me on this...
;
;	This monitor runs entirely in a 4096 byte page of SRAM on the Z80-Retro!
;	The stack is located at the end of this page. The device initialization
;	code is first copied from FLASH to SRAM low bank 0 (or E if a 128K SRAM
;	is installed instead of a 512K SRAM) beginning at 0x0000 on every boot.
;	Next, the monitor code is copied from the FLASH to its final location in
;	SRAM high bank F. The FLASH is then disabled which remaps the SRAM into
;	the FLASH address space. Execution continues in the SRAM low bank to
;	finish device initialization. The code then jumps and begins execution
;	in the upper bank and the low bank is now available for any use.
;
;	Whew... ok, all this trouble saves some SRAM as the device
;	initialization code only needs to execute once on boot and can be
;	discarded. Additionally we need the low SRAM to use CP/M.
;
;	When auto boot is enabled (see note above) and during the initialization
;	process, the following occurs. A startup message is displayed along with
;	a 5 second message and progress dots allowing you to press any key and
;	skip the auto boot from partition 1 of an SD card. If no SD card is
;	installed or there is an SD card error, an SD card error message is
;	displayed followed by the monitor asterisk command prompt. When auto boot
;	is disabled, the monitor command prompt is immediately displayed.
;
;	Up to 4 partitions on the SD card are available and information on these
;	partitions is located in the Master Boot Record (MBR) beginning at SD
;	block 0 on the SD card. Partition SD block starting addresses are stored
;	at the following offset locations from the beginning of the MBR:
;		Partition 1 -> 0x1BE+0x08
;		Partition 2 -> 0x1CE+0x08
;		Partition 3 -> 0x1DE+0x08
;		Partition 4 -> 0x1EE+0x08
;	The 32-bit address at these pointer locations indicates the SD card
;	block number of the beginning of the corresponding partition on the SD
;	card. Each SD block is 512 bytes in size. The monitor <B> 'Boot SD partition'
;	command extracts this information from the MBR. It then reads in 32 blocks
;	(16k bytes) and stores this beginning at 0xC000 in SRAM (which is always in
;	SRAM bank F). It then sets the A register to a 1 (indicating we are supplying
;	the partition and starting block information), sets the C register to the
;	partition number 1 - 4, sets the DE register to the high word of the starting
;	block address, and sets the HL register to the low word of the starting block
;	address where the code was read in from. The monitor then jumps to 0xC000
;	and begins execution. Hopefully something is useful there to execute.
;
;	All commands immediately echo a full command name as soon as the
;	first command letter is typed. This makes it easier to identify
;	commands without a list of commands present, although <H> 'Help' will
;	list all available commands for you. Upper or lower case can be used.
;
;	The command prompt is an asterisk. Backspace and DEL are not used.
;	If you make a mistake, type ESC (or ctrl-c) to get back to the prompt
;	and re-enter the command. Most executing commands can be aborted by
;	ESC (or ctrl-c).
;
;	All commands are a single letter. Four hex digits must be typed in
;	for an address. Two hex digits must be typed for a byte. Exceptions to 
;	this are the <A> 'Select Bank' and <B> 'Boot SD partition' command which
;	accept only 1 hex digit. The <H> 'Help' command indicates the number of
;	arguments each command accepts.
;
;	The spaces you see between the parameters are displayed by the monitor,
;	you don't type them. The command executes as soon as the last required
;	value is typed – a RETURN should not be typed.
;
;	Long running displays can be paused/resumed with the space bar.
;
;	The <D> 'Dump' command shows the currently selected lower 32K SRAM
;	bank in the first column of the display, the memory contents requested,
;	and an ASCII representation in additional columns. Bank 0 (or E if a
;	128K SRAM is configured) is selected at every boot and reflects
;	addresses 0x0000-0x7FFF. You can change this low 32K bank with the
;	<A> 'Select Bank' command to any desired bank 0 - E (or C - E if a
;	128K SRAM is configured). Addresses 0x8000-0xFFFF are always in bank F
;	and not switchable. The dump display always shows bank F when viewing
;	memory above 0x7FFF. The breakpoint, register and stack display also
;	indicates the currently selected 32K bank in the first column of the
;	display.
;
;	NOTE: All memory operation commands operate on the memory within
;	the currently selected low 32K bank. Memory operations above 0x7FFF
;	(upper 32K bank F) always affect that bank only regardless of the
;	currently selected low 32K bank. Currently there is no facility to
;	transfer memory between different low banks with this monitor but
;	this can be done in your own programs by accessing the GPIO_OUT
;	port 0x10 bits 4-7. Programs changing the SRAM bank should be
;	executed only from the upper 32K bank beginning at 0x8000 to avoid
;	crashing when the bank switch occurs. Otherwise the switch over code
;	can be duplicated in multiple banks to allow uninterrupted execution
;	between low banks. This monitor is currently located at 0xB000-0xBFFF.
;	Addresses 0xC000-0xFFFF are reserved for the CP/M loader, BDOS, CCP
;	and BIOS, but can still be used if not booting CP/M from the SD card.
;
;	The <N> 'Non-Destructive Test' command takes no parameters and runs
;	through the full 64K of SRAM (currently selected 32K low bank and 32k
;	high bank F). It skips the handful of bytes used in the memory
;	compare/swap routine to prevent crashing. A dot pacifier is displayed
;	at the start of each cycle through the memory test. Use ESC (or ctrl-c)
;	to exit back to the command prompt. Other low 32K SRAM banks can be
;	tested by first selecting another bank with the <A> 'Select Bank'
;	command.
;
;	The <T> 'Destructive Test' command skips the 4096 byte page that the
;	monitor and stack are in to prevent crashing. A dot pacifier is also
;	displayed as in the <N> command. Use ESC (or ctrl-c) to exit back to
;	the command prompt. As above, additional SRAM low banks can be tested
;	by first selecting the <A> 'Select Bank' command.
;
;	The <U> 'Break at' command sets a RST 08 opcode at the address
;	specified. The monitor then displays its asterisk main command prompt.
;	The <V> 'Clear Breakpoint' command can be used to manually remove an
;	unwanted breakpoint. Setting another breakpoint will clear the previous
;	breakpoint and install a new one. Upon execution of the code containing
;	the breakpoint, control is returned to the monitor and a register/stack
;	display is shown. The breakpoint is automatically cleared at this point.
;	A sub command line is presented that allows <Esc> 'Abort' back to
;	the monitor main prompt; <Enter> 'Continue' executing code with no more
;	breakpoints; <Space> 'Dump' a range of memory you specify; and
;	<LLLL> 'New BP' where a new location address can be specified. Execution
;	will immediately resume to the new breakpoint.
;
;	NOTE: Your code listing should be referenced when choosing breakpoint
;	locations if you wish to continue execution or add new breakpoints
;	using the sub command options described above. Breakpoints should be
;	placed on opcode not operand/mid-instruction/data area addresses. The
;	monitor breakpoint code does not keep track of how long each
;	instruction is so the code under test could crash if it is stopped and
;	restarted mid-instruction. If you ESC out to the main command prompt
;	after the FIRST breakpoint then it doesn't matter where you place it.
;
;	Currently configured console port settings are 9600:8N1. See the note
;	below in the .INIT_CTC_1 function to change these settings.
;
;	Semi-Pro Tip... If you include retromon.sym at the beginning of your
;	code, you will have access to all of the Z80-Retro! monitor public
;	subroutines and equate values by name.
;
;--------------------------------------------------------------------------

; Memory location equates
; NOTE: to work properly with CP/M and SRAM bank switching, valid values
;	for .MONSTART are 0x8000, 0x9000, 0xA000, or 0xB000
.MONSTART:	EQU	0xB000				; Beginning of Monitor (4K byte boundary)
.SPTR:		EQU	.MONSTART+0x1000	; Stack pointer (beginning of next 4K page)
.MEMSTART:	EQU	0x0000				; Beginning of RAM/FLASH
.LOAD_BASE:	EQU	0xC000				; SD card boot loader image location
.MEM:		EQU	0x3C				; CP/M memory size configuration
.CPM_BASE:	EQU	(.MEM-7)*1024		; CP/M origin (0xD400 using above values)

; Option equates
;**************************************************************************
.RAM128K:	EQU	0			; SET TO: 1 = 128K SRAM, 0 = 512K SRAM
.AUTOSD_EN:	EQU	1			; SET TO: Auto SD Boot 1 = Enable, 0 = Disable
;**************************************************************************
if .RAM128K
	.BANK:	EQU	0x0E		; Valid SRAM banks C-E
else
	.BANK:	EQU 0x00		; Valid SRAM banks 0-E
endif
; .RAM128K

; Misc equates
CR:			EQU	0x0D		; ASCII carriage return
LF:			EQU	0x0A		; ASCII line feed
CTRLC:		EQU	0x03		; ASCII control-c
ESC:		EQU	0x1B		; ASCII escape
RST1:		EQU	0x0008		; RST1 vector at 0x0008
BIT7:		EQU 0x80		; MSB set for message string terminator
.HXRLEN:	EQU	0x10		; Intel hex record length
.LOAD_BLKS:	EQU	(0x10000-.LOAD_BASE)/512	; SD card number of blocks to load

; Port assignments for GPIO
GPIO_IN:		EQU 0x00	; GP input port
GPIO_OUT:		EQU	0x10	; GP output port
PRN_DAT:		EQU	0x20	; Printer data port
FLASH_DISABLE:	EQU	0x70	; Dummy-read port to disable FLASH

; Port assignments for the Z80 CTC
CTC_0:	EQU	0x40			; CTC port 0
CTC_1:	EQU	0x41			; CTC port 1
CTC_2:	EQU	0x42			; CTC port 2
CTC_3:	EQU	0x43			; CTC port 3

; Port assignments and status for the Z80 SIO
ADTA:	EQU	0x30			; Channel A data
BDTA:	EQU	0x31			; Channel B data
ACTL:	EQU	0x32			; Channel A control
BCTL:	EQU	0x33			; Channel B control

TBE:	EQU	0x04			; Transmit buffer empty
RDA:	EQU	0x01			; Receive data available

; Bit-assignments for the General Purpose I/O ports
GPIO_OUT_SD_MOSI:	EQU	0x01
GPIO_OUT_SD_CLK:	EQU	0x02
GPIO_OUT_SD_SSEL:	EQU	0x04
GPIO_OUT_PRN_STB:	EQU	0x08
GPIO_OUT_A15:		EQU	0x10
GPIO_OUT_A16:		EQU	0x20
GPIO_OUT_A17:		EQU	0x40
GPIO_OUT_A18:		EQU	0x80

GPIO_IN_PRN_ERR:	EQU	0x01
GPIO_IN_PRN_STAT:	EQU	0x02
GPIO_IN_PRN_PAPR:	EQU	0x04
GPIO_IN_PRN_BSY:	EQU	0x08
GPIO_IN_PRN_ACK:	EQU	0x10
GPIO_IN_USER1:		EQU	0x20
GPIO_IN_SD_DET:		EQU	0x40
GPIO_IN_SD_MISO:	EQU	0x80

	ORG	.MEMSTART			; FLASH start location

;--------------------------------------------------------------------------
; THE SRAM IS NOT READABLE AT THIS POINT
;--------------------------------------------------------------------------

; Select SRAM low bank, idle the SD card, idle printer signals
;	zero printer data port
	LD		A,GPIO_OUT_SD_MOSI|GPIO_OUT_SD_SSEL|GPIO_OUT_PRN_STB|(.BANK<<4)
	OUT		(GPIO_OUT),A
	XOR		A				; Zero A
	OUT		(PRN_DAT),A

; Copy the FLASH into the SRAM by reading every byte and
;	writing it back into the same address
	LD		HL,.MEMSTART	; Source address (FLASH)
	LD		DE,.MEMSTART	; Destination address (SRAM low bank)
	LD		BC,.INITEND
	LDIR					; Copy initialization code from the FLASH into
							;	SRAM at the same address

	LD		HL,.INITEND		; Source address (FLASH)
	LD		DE,.MONSTART	; Destination address (SRAM high bank)
	LD		BC,.END-.MONSTART
	LDIR					; Copy monitor code from the FLASH into
							;	SRAM starting at .MONSTART

; Disable the FLASH and run from SRAM only from this point on
	IN		A,(FLASH_DISABLE)	; Dummy-read this port to disable the FLASH

; And then a miracle occurs ...

;--------------------------------------------------------------------------
; STARTING HERE, WE ARE RUNNING FROM SRAM, FLASH IS NO LONGER AVAILABLE
;--------------------------------------------------------------------------

;--------------------------------------------------------------------------
; The following values assume that the SIO has a /16 prescaler initialized
; CTC bit-rate clock divisor table
;    LD      A,1        ; 115200 bps
;    LD      A,2        ; 57600 bps
;    LD      A,3        ; 38400 bps
;    LD      A,4        ; 28800 bps
;    LD      A,6        ; 19200 bps
;    LD      A,8        ; 14400 bps
;    LD      A,12       ; 9600 bps
;    LD      A,24       ; 4800 bps
;    LD      A,48       ; 2400 bps
;    LD      A,96       ; 1200 bps
;    LD      A,192      ; 600 bps
;--------------------------------------------------------------------------

;--------------------------------------------------------------------------
; Init the bit-rate generator for SIO A
;--------------------------------------------------------------------------
.INIT_CTC_1:
	LD		A,01000111B		; TC follows, Counter, Control, Reset
	OUT		(CTC_1),A
	LD		A,12			; 9600 bps
	OUT		(CTC_1),A

;--------------------------------------------------------------------------
; Init the bit-rate generator for SIO B
;--------------------------------------------------------------------------
.INIT_CTC_2:
	LD		A,01000111B		; TC follows, Counter, Control, Reset
	OUT		(CTC_2),A
	LD		A,12			; 9600 bps
	OUT		(CTC_2),A

;--------------------------------------------------------------------------
; Init SIO port A/B
;--------------------------------------------------------------------------
	LD		C,ACTL				; Port to write into (port A control)
	LD		HL,.SIO_INIT_WR		; Point to init string
	LD		B,.SIO_INIT_LEN_WR	; Number of bytes to send
	OTIR						; Write B bytes from (HL) into port in the C reg

	LD		C,BCTL				; Port to write into (port B control)
	LD		HL,.SIO_INIT_WR		; Point to init string
	LD		B,.SIO_INIT_LEN_WR	; Number of bytes to send
	OTIR						; Write B bytes from (HL) into port in the C reg

;--------------------------------------------------------------------------
; Initialization string for the Z80 SIO
;--------------------------------------------------------------------------
.SIO_INIT_WR:
	DEFB	00011000B		; WR0 = reset everything
	DEFB	00000100B		; WR0 = select reg 4
	DEFB	01000100B		; WR4 = /16 N1 (115200 from 1.8432 MHZ clk)
	DEFB	00000011B		; WR0 = select reg 3
	DEFB	11000001B		; WR3 = RX enable, 8 bits/char
	DEFB	00000101B		; WR0 = select reg 5
	DEFB	01101000B		; WR5 = DTR=0, TX enable, 8 bits/char
.SIO_INIT_LEN_WR:	EQU $-.SIO_INIT_WR

	LD		SP,.SPTR		; Initialize stack pointer
	CALL	DSPMSG			; Display welcome banner
	DEFB	CR,LF,'Z80-Retro! Monitor v1.8',CR,LF
	DEFB	'K.R.Maytum,202',BIT7 + '3'

if .AUTOSD_EN
	CALL	SD_DETECT		; Check for physical SD card
	CALL	DSPMSG			; Display SD card auto boot skip message
	DEFB	CR,LF,'Press any key to skip SD card partition 1 auto boo',BIT7+'t'

	LD		D,0x0E			; Outer loop count, ~5 sec delay at 10Mhz clock

.SDSKIP1:
	LD		A,'.'
	CALL	PTCN			; Display progress dots

	LD		BC,0xFFFF		; Inner loop count, ~330msec at 10Mhz clock
	DEC		D
	JR		NZ,.SDSKIP2		; Timeout?

	LD		A,1
	LD		(.PARTITION),A	; Save desired partition number
	JP		DOBOOT_AUTO		; Boot from SD card

.SDSKIP2:
	IN		A,(ACTL)
	AND		RDA				; Character at console?
	JR		NZ,.SKIP_EXIT	; Yes, exit

	DEC		BC
	LD		A,B
	OR		C				; Is BC zero?
	JR		Z,.SDSKIP1		; Yes, back to outer loop
	JR		.SDSKIP2		; Else continue checking console

.SKIP_EXIT:
	IN		A,(ADTA)		; Flush console buffer
endif
; .AUTOSD_EN

	JP		.MONSTART		; Jump to monitor now that initialization is complete

.INITEND:					; End of initialization code

	ORG		.MONSTART		; Final SRAM destination location of monitor

;--------------------------------------------------------------------------
; MONIT <X> - monitor entry point
;--------------------------------------------------------------------------
MONIT:
	CALL	DSPMSG			; Display monitor startup message
	DEFB	CR,LF,LF,'Monitor Ready',CR,LF
	DEFB	'<H> for hel',BIT7+'p'

; START - command processing loop
START:
	LD		SP,.SPTR		; Re-init stack pointer
	LD		HL,START		
	PUSH	HL				; RET's go back to START

	CALL	CRLF			; Start a new line
	LD		A,'*'
	CALL	PTCN			; Display '*' prompt

	CALL	GETCON			; Read command from keyboard to A
	AND		0x5F			; Lower case to upper case
	CP		'A'				; Carry set if A < 'A'
	RET		C
	CP		'Z'+1			; Carry cleared if A > 'Z'
	RET		NC

	LD		HL,.CMDTBL+0x100-2*'A' ; 'A' indexes to start of .CMDTBL
	ADD		A,A				; 2 bytes per entry
	ADD		A,L
	LD		L,A

	LD		E,(HL)			; E = LSB of jump address
	INC		HL
	LD		D,(HL)			; D = MSB of jump address
	EX		DE,HL

	JP		(HL)			; Execute

; Command Table
.CMDTBL:
	DEFW	SBANK			; A -> D select low 32k RAM bank
	DEFW	DOBOOT			; B -> D boot SD partition
	DEFW	COMPR			; C -> SSSS FFFF DDDD compare blocks
	DEFW	DUMP			; D -> SSSS FFFF dump hex and ASCII
	DEFW	EXCHG			; E -> SSSS FFFF DDDD exchange block
	DEFW	SRCH2			; F -> SSSS FFFF DD DD two byte search
	DEFW	EXEC			; G -> LLLL go to and execute
	DEFW	HELP			; H -> Command help
	DEFW	PINPT			; I -> PP input from I/O port
	DEFW	HEXDUMP			; J -> SSSS FFFF dump Intel hex file
	DEFW	FILL			; K -> SSSS FFFF DD fill RAM with constant
	DEFW	HEXLOAD			; L -> Load Intel hex file
	DEFW	MOVEB			; M -> SSSS FFFF DDDD copy block
	DEFW	NDMT			; N -> Non-destructive memory test
	DEFW	POUTP			; O -> PP DD output to port
	DEFW	PGM				; P -> LLLL program memory
	DEFW	CHKSUM			; Q -> SSSS FFFF compute checksum
	DEFW	SDREAD			; R -> BBBB BBBB DDDD read SD block (512 bytes)
	DEFW	SRCH1			; S -> SSSS FFFF DD one byte search
	DEFW	TMEM			; T -> SSSS FFFF destructive memory test
	DEFW	SETBRK			; U -> LLLL set breakpoint
	DEFW	CLRCMD			; V -> Clear breakpoint
	DEFW	SDWRT			; W -> LLLL BBBB BBBB write SD block (512 bytes)
	DEFW	MONIT			; X -> Reboot monitor
	DEFW	BLOAD			; Y -> DDDD CCCC load binary file
	DEFW	BDUMP			; Z -> LLLL CCCC dump binary file

;**************************************************************************
;
;					C O M M A N D  S U B R O U T I N E S
;
;**************************************************************************

;--------------------------------------------------------------------------
; SBANK <A> - select which low 32K RAM bank to use.
;	Valid ranges: 0-E using 512K SRAM, C-E using 128K SRAM
;--------------------------------------------------------------------------
SBANK:
	CALL	DSPMSG
	DEFB	'Select Ban',BIT7+'k'

	LD		C,1				; Read 1 hex digit from command line
	CALL	AHE0			; Desired bank number to E

	LD		A,E

if .RAM128K
	CP		0x0C
	JR		C,.SBANK_ERR	; Error, carry set if < 0x0C
	CP		0x0E+1
	JR		NC,.SBANK_ERR	; Error, carry cleared if > 0x0E
	JR		.SBANK1

.SBANK_ERR:
	CALL	DSPMSG			; Display range error message
	DEFB	'Bank C-E onl',BIT7+'y'
else	
	CP		0x0F
	JR		NZ,.SBANK1		; OK if 0-E selected

	CALL	DSPMSG			; Display range error message
	DEFB	'Bank 0-E onl',BIT7+'y'
endif
; .RAM128K

	RET

.SBANK1:
	LD		(.CBANK),A		; Save current bank number
	ADD		A,A				; Move bank number to upper nibble
	ADD		A,A
	ADD		A,A
	ADD		A,A
	LD		E,A

	LD		A,(GPIO_OUT_CACHE)
	AND		0x0F	
	OR		E				; Leave lower nibble unchanged
	LD		(GPIO_OUT_CACHE),A
	OUT		(GPIO_OUT),A	; Save copy and switch bank
	RET

;--------------------------------------------------------------------------
; DOBOOT <B> - boot SD partition
; DOBOOT_AUTO - autoboot from partition number in .PARTITION
;--------------------------------------------------------------------------
DOBOOT:
	CALL	DSPMSG
	DEFB	'Boot SD partitio',BIT7+'n'
	
	LD		C,1				; Read 1 hex digit from command line
	CALL	AHE0			; Get desired partition in E

	LD		A,E
	CP		1
	JP		C,START			; Carry set if A < 1
	CP		4+1
	JP		NC,START		; Carry cleared if A > 4

	LD		(.PARTITION),A	; Save partition number
	CALL	SD_DETECT		; Check for physical SD card

DOBOOT_AUTO:	
	CALL	SD_BOOT			; Boot SD card for block transfers

; Read the MBR (SD block 0, 512 bytes), store in SRAM beginning at .LOAD_BASE
; Push the starting block number onto the stack in little-endian order
	LD		HL,0			; SD card block number to read
	PUSH	HL				; High half
	PUSH	HL				; Low half
	LD		DE,.LOAD_BASE	; Destination of read sector data
	CALL	SD_CMD17
	POP		HL				; Remove the block number from the stack
	POP		HL

	OR		A				; Check SD_CMD17 return code
	JR		Z,.BOOT_CMD17_OK

	JP		SD_ERROR

; Read the 32 SD blocks of the desired partition
.BOOT_CMD17_OK:
	LD		A,(.PARTITION)	; Get desired partition number
	CP		1
	JR		Z,.PART_1
	CP		2
	JR		Z,.PART_2
	CP		3
	JR		Z,.PART_3

	LD		IX,.LOAD_BASE+0x01EE+0x08
	JR		.DOBOOT1		; Else partition 4

.PART_1:
	LD		IX,.LOAD_BASE+0x01BE+0x08
	JR		.DOBOOT1

.PART_2:
	LD		IX,.LOAD_BASE+0x01CE+0x08
	JR		.DOBOOT1

.PART_3:
	LD		IX,.LOAD_BASE+0x01DE+0x08
	
.DOBOOT1:
	LD		D,(IX+3)
	LD		E,(IX+2)
	PUSH	DE				; DE -> high word of block address to load
	LD		D,(IX+1)
	LD		E,(IX+0)
	PUSH	DE				; DE -> low word of block address to load

	LD		DE,.LOAD_BASE	; Destination of read sector data
	LD		B,.LOAD_BLKS	; Number of blocks to load (should be 32 == 16K)

	CALL	DSPMSG
	DEFB	CR,LF,'Partitio',BIT7+'n'

	LD		A,(.PARTITION)
	CALL	BINL			; Display partition number
	CALL	SPCE

	CALL	READ_BLOCKS
	POP		HL				; HL -> low word of block address loaded
	POP		DE				; DE -> high word of block address loaded

	OR		A				; Check READ_BLOCKS return code
	LD		A,(.PARTITION)
	LD		C,A				; C -> partition number loaded
	LD		A,1				; Boot code version number 1 (for selectable partitions)
	JP		Z,.LOAD_BASE	; If no error, run the code read in from the SD card

	JP		SD_ERROR

;--------------------------------------------------------------------------
; COMPR <C> - compare two blocks of memory
;--------------------------------------------------------------------------
COMPR:
	CALL	DSPMSG
	DEFB	'Compar',BIT7+'e'

	CALL	TAHEX			; Read addresses
	PUSH	HL				; Source start on stack
	CALL	AHEX
	EX		DE,HL			; DE = source end, HL = compare start

.VMLOP:
	LD		A,(HL)			; A = compare byte
	INC		HL
	EX		(SP),HL			; HL -> source byte
	CP		(HL)			; Same?
	LD		B,(HL)			; B = source byte
	CALL	NZ,ERR			; Display the error
	CALL	BMP				; Increment pointers
	EX		(SP),HL			; HL -> compare byte
	JR		NZ,.VMLOP

	POP		HL				; Remove temp pointer from stack
	RET

;--------------------------------------------------------------------------
; DUMP <D> - show current 32K bank & dump memory contents in hex and ASCII
;--------------------------------------------------------------------------
DUMP:
	CALL	DSPMSG
	DEFB	'Dum',BIT7+'p'

	CALL	TAHEX			; HL -> start address, DE -> end address

.DMPLINE:
	PUSH	HL				; Save start address
	CALL	CRLF
	CALL	DSPBANK			; Display current SRAM bank
	CALL	PTAD1			; Display current address
	CALL	SPCE			; Add an extra space
	LD		C,8				; 8 locations per line
	LD		B,2				; Run .DMPHEX twice

; Dump line in hex
.DMPHEX:
	LD		A,(HL)			; A = byte to display
	CALL	PT2				; Display it
	CALL	SPCE
	INC		HL
	DEC		C				; Decrement line byte count
	JR		NZ,.DMPHEX		; Loop until 8 bytes done

	CALL 	SPCE
	LD		C,8				; Do 8 more bytes
	DEC		B
	JR		NZ,.DMPHEX

; Dump line in ASCII
	CALL	SPCE
	POP		HL				; HL -> start of line
	LD		C,16			; 16 locations per line

.DMPASC:
	LD		A,(HL)			; A = byte to display
	CP		0x7F			; Clear carry if >= 0x7F
	JR		NC,.DSPDOT		; Non printable, show '.'

	CP		' '				; Displayable character?
	JR		NC,.DSPASC		; Yes, go display it

.DSPDOT:
	LD		A,'.'			; Display '.' instead

.DSPASC:
	CALL	PTCN			; Display the character
	CALL	BMP				; Increment HL, possibly DE
	DEC		C				; Decrement line byte count
	JR		NZ,.DMPASC		; Loop until 16 bytes done

	CALL	BMP				; Done?
	RET		Z				; Yes
	DEC		HL				; Else undo extra bump of HL
	JR		.DMPLINE		; Do another line

;--------------------------------------------------------------------------
; EXCHG <E> - exchange block of memory
; MOVEB <M> - move (copy only) a block of memory
;--------------------------------------------------------------------------
MOVEB:
	CALL	DSPMSG
	DEFB	'Mov',BIT7+'e'

	XOR		A				; A = 0 means "move" command
	JR		.DOMOVE

EXCHG:
	CALL	DSPMSG
	DEFB	'Exchang',BIT7+'e'
							; A returned <> 0 means "exchange" command

.DOMOVE:
	LD		B,A				; Save move/exchange flag in B
	CALL	TAHEX			; Read addresses
	PUSH	HL
	CALL	AHEX
	EX		DE,HL
	EX		(SP),HL			; HL -> start, DE -> end, stack has destination

.MLOOP:
	LD		C,(HL)			; C = byte from source
	EX		(SP),HL			; HL -> destination

	LD		A,B				; Move or exchange?
	OR		A
	JR		Z,.NEXCH		; 0 means move only

	LD		A,(HL)			; A = from destination
	EX		(SP),HL			; HL -> source
	LD		(HL),A			; Move destination to source
	EX		(SP),HL			; HL -> destination

.NEXCH:
	LD		(HL),C			; Move source to destination
	INC		HL				; Increment destination
	EX		(SP),HL			; HL -> source
	CALL	BMP				; Increment source and compare to end
	JR		NZ,.MLOOP

	POP		HL				; Remove temp pointer from stack
	RET

;--------------------------------------------------------------------------
; EXEC <G> - execute the code at the address
;--------------------------------------------------------------------------
EXEC:
	CALL	DSPMSG
	DEFB	'Got',BIT7+'o'

	CALL	AHEX			; DE -> address to begin execution
	EX		DE,HL

	JP		(HL)			; Execute from HL

;--------------------------------------------------------------------------
; HELP <H> - display command help table
;--------------------------------------------------------------------------
HELP:
	CALL	DSPMSG
	DEFB	CR,LF,'A -> D select low 32k RAM bank',CR,LF
	DEFB	'B -> Boot SD partition',CR,LF
	DEFB	'C -> SSSS FFFF DDDD compare block',CR,LF
	DEFB	'D -> SSSS FFFF dump hex and ASCII',CR,LF
	DEFB	'E -> SSSS FFFF DDDD exchange block',CR,LF
	DEFB	'F -> SSSS FFFF DD DD two byte search',CR,LF
	DEFB	'G -> LLLL go to and execute',CR,LF
	DEFB	'H -> Command help',CR,LF
	DEFB	'I -> PP input from I/O port',CR,LF
	DEFB	'J -> SSSS FFFF dump Intel hex file',CR,LF
	DEFB	'K -> SSSS FFFF DD fill RAM with constant',CR,LF
	DEFB	'L -> Load Intel hex file',CR,LF
	DEFB	'M -> SSSS FFFF DDDD copy block',CR,LF
	DEFB	'N -> Non-destructive memory test',CR,LF
	DEFB	'O -> PP DD output to port',CR,LF
	DEFB	'P -> LLLL program memory',CR,LF
	DEFB	'Q -> SSSS FFFF compute checksum',CR,LF
	DEFB	'R -> BBBB BBBB DDDD read SD block (512 bytes)',CR,LF
	DEFB	'S -> SSSS FFFF DD one byte search',CR,LF
	DEFB	'T -> SSSS FFFF destructive memory test',CR,LF
	DEFB	'U -> LLLL set breakpoint',CR,LF
	DEFB	'V -> Clear breakpoint',CR,LF
	DEFB	'W -> LLLL BBBB BBBB write SD block (512 bytes)',CR,LF
	DEFB	'X -> Reboot monitor',CR,LF
	DEFB	'Y -> DDDD CCCC load binary file',CR,LF
	DEFB	'Z -> LLLL CCCC dump binary file',CR,LF,LF
	DEFB	'<SSSS>Start Address <FFFF>Finish Address',CR,LF
	DEFB	'<DDDD>Destination Address <D/DD>Data <PP>Port',CR,LF
	DEFB	'<BBBB BBBB>32-bit SD Block <LLLL>Location Address',CR,LF
	DEFB	'<CCCC>Size <Esc/Ctrl-c>Abort <Space>Pause',CR,BIT7+LF

	RET

;--------------------------------------------------------------------------
; PINPT <I> - input data from a port
;--------------------------------------------------------------------------
PINPT:
	CALL	DSPMSG
	DEFB	'I',BIT7+'n'

	LD		C,2				; Read 2 hex digits from command line
	CALL	AHE0			; Port number to E

	LD		HL,.PORT_RW+2	; Form IN PP RET in memory at HL
	LD		(HL),0xC9		; RET opcode
	DEC		HL
	LD		(HL),E			; Input port of IN instruction
	DEC		HL
	LD		(HL),0xDB		; IN opcode
	CALL	.PORT_RW		; Call IN PP RET

	JP		PT2				; Tail call exit

;--------------------------------------------------------------------------
; HEXDUMP <J> - dump Intel hex file
;--------------------------------------------------------------------------
HEXDUMP:
	CALL	DSPMSG
	DEFB	'Hexdum',BIT7+'p'

	CALL	TAHEX			; HL -> start address, DE -> end address

	EX		DE,HL
	AND		A				; Clear carry
	SBC		HL,DE			; Get difference
	INC		HL				; Add 1
	EX		DE,HL			; DE = byte count

; Loop to send requested data in .HXRLEN-byte records
; Send record-start
.HXLINE:
	CALL	CRLF			; Send CRLF

	LD		BC,.HXRLEN*256	; BC = bytes/line
							; C = 0 initial checksum
	LD		A,':'			; Record start
	CALL	PTCN

; Compute this record length (B=.HXRLEN here)
	LD		A,E				; Short last line?
	SUB		B				; Normal bytes/line
	LD		A,D				; 16-bit subtract
	SBC		A,C				; C = 0 here
	JR		NC,.HXLIN1		; N:full line
	LD		B,E				; Y:short line

.HXLIN1:
; If byte count is 0 then go finish EOF record
	LD		A,B
	OR		A
	JR		Z,.HXEOF

; Send record byte count = A, checksum = 0 in C here
	CALL	.PAHCSM

; Send the address at the beginning of each line,
; computing the checksum in C
	CALL	.PHLHEX			; HL = address

; Send the record type (00), checksum in C
	XOR		A
	CALL	.PAHCSM

; Send B bytes of hex data on each line, computing the checksum in C
.HXLOOP:
	CALL	.PMHCSM			; Send character

	DEC		DE
	INC		HL
	DEC		B				; Next
	JR		NZ,.HXLOOP

; Compute & send the checksum
	XOR		A
	SUB		C
	INC		B				; Send character
	CALL	.PAHCSM

; Give the user a chance to break in at the end of each line
	CALL	PAUSE
	JR		.HXLINE			; Next record

.HXEOF:
	LD		B,3				; 3 bytes for start of EOF

.HXELUP:
	XOR		A
	CALL	PT2				; Send 0x00 characters
	DEC		B
	JR		NZ,.HXELUP

	LD		A,0x01
	CALL	PT2				; Send 0x01 character, 4th EOF character
	LD		A,0xFF
	CALL	PT2				; Send 0xFF character, 5th EOF character

	JP		CRLF			; Tail call exit

.PHLHEX:
	LD		A,H				; H first
	CALL	.PAHCSM
	LD		A,L				; Then L

	DEFB	0xFE			; CP opcode, skip over .PMHCSM

.PMHCSM:
	LD		A,(HL)			; Get byte to send

.PAHCSM:
	PUSH	AF
	ADD		A,C				; Compute checksum
	LD		C,A
	POP		AF				; Recover and send character
	CALL	PT2
	RET

;--------------------------------------------------------------------------
; FILL <K> - fill memory with a constant
;--------------------------------------------------------------------------
FILL:
	CALL	DSPMSG
	DEFB	'Fil',BIT7+'l'

	CALL	TAHEX			; Read addresses
	PUSH	HL				; Start address on stack
	LD		C,2				; Read 2 hex digits from command line
	CALL	AHE0			; Input fill byte
	EX		DE,HL			; Byte to write from E to L
	EX		(SP),HL			; HL = start address, stack = fill byte
	POP		BC				; C = fill byte from stack

.ZLOOP:
	LD		(HL),C			; Write into memory
	CALL	BMP				; Compare address, increment HL
	RET		Z				; Leave when done

	JR		.ZLOOP

;--------------------------------------------------------------------------
; HEXLOAD <L> - load Intel hex through console port
;--------------------------------------------------------------------------
HEXLOAD:
	CALL	DSPMSG
	DEFB	'Hexload - Paste hex file..',BIT7+'.'

; Receive a hex file line
.RCVLINE:
	CALL	CRLF
	LD		C,0				; Clear echo character flag

.WTMARK:
	CALL	CNTLC			; Read character from console
	SUB		':'				; Record marker?
	JR		NZ,.WTMARK		; No, keep looking

; Have start of new record. Save the byte count and load address
; The load address is echoed to the screen so the user can
;	see the file load progress. Note A is zero here from above SUB ':'
	LD		D,A				; Init checksum in D to zero

	CALL	IBYTE			; Input two hex digits (byte count)
	LD		A,E				; Test for zero byte count
	OR		A
	JR		Z,.FLUSH		; Count of 0 means end

	LD		B,E				; B = byte count on line

	INC		C				; Set echo flag for address bytes
	CALL	IBYTE			; Get MSB of address
	LD		H,E				; H = address MSB
	CALL	IBYTE			; Get LSB of address
	LD		L,E				; L = address LSB
	DEC		C				; Clear echo flag

	CALL	IBYTE			; Ignore/discard record type

; Receive the data bytes of the record and move to memory
.DATA:
	CALL	IBYTE			; Read a data byte (2 hex digits)
	LD		(HL),E			; Store in memory
	INC		HL
	DEC		B
	JR		NZ,.DATA

; Validate checksum
	CALL	IBYTE			; Read and add checksum
	JR		Z,.RCVLINE		; Checksum good, receive next line

	CALL	DSPMSG			; Display error message
	DEFB	' Erro',BIT7+'r'
							; Fall into flush

; Flush rest of file as it comes in until no characters
;	received for about 1/4 second to prevent incoming file
;	data looking like typed monitor commands
;	[n] = number of T states, 51 T states @ 10Mhz = 5.1us
;	250msec ~ 0xBF70 loop cycles
.FLUSH:
	IN		A,(ADTA)		; Clear possible received char
	LD		DE,0xBF70		; 250msec delay

.FLSHLP:
	IN		A,(ACTL)		; [11] Look for character on console
	AND		RDA				; [7]
	JR		NZ,.FLUSH		; [7F/12T] Data received, restart

	DEC		DE				; [6] Decrement timeout
	LD		A,D				; [4]
	OR		E				; [4]
	JR		NZ,.FLSHLP		; [7F/12T] Loop until zero
	RET

;--------------------------------------------------------------------------
; NDMT <N> - non-destructive memory test, skipping compare code below
;--------------------------------------------------------------------------
NDMT:
	CALL	DSPMSG
	DEFB	'Non-Destructive Tes',BIT7+'t'

	LD		HL,.MEMSTART	; Start address

.NDCYCLE:
	LD		A,'.'			; Display '.' before each cycle
	CALL	PTCN
	CALL	PAUSE			; Check for ctrl-c, esc, or space

.NDLOP:
	LD		A,H			
	AND		0xF0			; Upper nibble of H
	CP		.MONSTART>>8	; On monitor 4k page?
	JR		NZ,.DOCMP		; No, ok to compare

	LD		A,L				; Get LSB of current address
	CP		.DOCMP&0xFF		; Address < LSB .DOCMP?
	JR		C,.DOCMP		; Yes, ok to compare

	CP		.NDCONT&0xFF	; Address < LSB .NDCONT?
	JR		C,.NDCONT		; Yes, in compare code so skip memory test

.DOCMP:
	LD		A,(HL)			; Read from address in HL
	LD		B,A				; Save original value in B
	CPL						; Form and write inverted value
	LD		(HL),A
	CP		(HL)			; Read and compare
	LD		(HL),B			; Restore original value
	CALL	NZ,ERR			; Display error if mismatch

.NDCONT:
	INC		HL				; Next address to test
	LD		A,H
	OR		L				; HL wrap around to 0?
	JR		Z,.NDCYCLE		; Then continue from beginning of memory

	JR		.NDLOP			; Else continue test

;--------------------------------------------------------------------------
; POUTP <O> - output data to a port
;--------------------------------------------------------------------------
POUTP:
	CALL	DSPMSG
	DEFB	'Ou',BIT7+'t'

	LD		C,2				; Read 2 hex digits from command line
	CALL	AHE0			; Port number in E

	LD		C,2				; Read 2 hex digits from command line
	CALL	AHE0			; Port to L, data in E

	LD		D,L				; D = port
	LD		HL,.PORT_RW+2	; Form OUT PP RET in memory at HL
	LD		(HL),0xC9		; RET opcode
	DEC		HL
	LD		(HL),D			; Output port for OUT instruction
	DEC		HL
	LD		(HL),0xD3		; OUT opcode
	LD		A,E				; Port data value in A

	JP		(HL)			; Call OUT PP RET

;--------------------------------------------------------------------------
; PGM <P> - program memory
;--------------------------------------------------------------------------
PGM:
	CALL	DSPMSG
	DEFB	'Progra',BIT7+'m'

	CALL	AHEX			; Read address
	EX		DE,HL
	CALL	CRLF

.PGLP:
	LD		A,(HL)			; Read memory
	CALL	PT2				; Display 2 digits
	LD		A,'-'			; Load dash
	CALL	PTCN			; Display dash

.CRIG:
	CALL	RDCN			; Get user input
	CP		' '				; Space
	JR		Z,.CON2			; Skip if space
	CP		CR				; Skip if CR
	JR		NZ,.CON1
	CALL	CRLF			; Display CR,LF
	JR		.CON2			; Continue on new line

.CON1:
	EX		DE,HL
	LD		HL,0			; Get 16 bit zero
	LD		C,2				; Count 2 digits
	CALL	AHEXNR			; Convert to hex (no read)
	LD		(HL),E

.CON2:
	INC		HL				; Next address
	JR		.PGLP

;--------------------------------------------------------------------------
; CHKSUM <Q> - compute checksum
;--------------------------------------------------------------------------
CHKSUM:
	CALL	DSPMSG
	DEFB	'Checksu',BIT7+'m'

	CALL	TAHEX
	LD		B,0				; Start checksum = 0

.CSLOOP:
	LD		A,(HL)			; Get data from memory
	ADD		A,B				; Add to checksum
	LD		B,A
	CALL	BMP
	JR		NZ,.CSLOOP		; Repeat loop

	LD		A,B				; A = checksum
	JP		PT2				; Display checksum and tail call exit

;--------------------------------------------------------------------------
; SDREAD <R> - read one SD block (512 bytes)
;--------------------------------------------------------------------------
SDREAD:
	CALL	DSPMSG
	DEFB	'SD Rea',BIT7+'d'

	CALL	SD_DETECT		; Check for physical SD card
	CALL	SD_BOOT			; Boot SD card for block transfers
	CALL	TAHEX			; HL -> source block MSW, DE -> source block LSW

; Push the 32-bit starting block number onto the stack in little-endian order
	PUSH	HL				; High half in HL
	PUSH	DE				; Low half in DE

	CALL	AHEX			; DE -> destination address
	CALL	SD_CMD17
	POP		HL				; Remove the block number from the stack
	POP		HL

	OR		A
	RET		Z				; Return to command loop if no error

	JP		SD_ERROR

;--------------------------------------------------------------------------
; SRCH1 <S> - search for one byte
; SRCH2 <F> - search for two bytes
;--------------------------------------------------------------------------
SRCH1:
	CALL	DSPMSG
	DEFB	'Find ',BIT7+'1'

	XOR		A				; Zero flag means one byte search
	JR		.DOSRCH

SRCH2:
	CALL	DSPMSG
	DEFB	'Find ',BIT7+'2'
							; A returned <> 0 means two byte search
.DOSRCH:
	PUSH	AF				; Save one/two byte flag on stack
	CALL	TAHEX

	PUSH	HL				; Save HL, getting 1st byte to find
	LD		C,2				; Read 2 hex digits from command line
	CALL	AHE0
	EX		DE,HL			; H = code, D = F
	LD		B,L				; Put code in B
	POP		HL				; Restore HL

	POP		AF				; A = one/two byte flag
	OR		A				; Zero true if one byte search
	PUSH	AF
	JR		Z,.CONT

	PUSH	HL				; Save HL, getting 2nd byte to find
	LD		C,2				; Read 2 hex digits from command line
	CALL	AHE0
	EX		DE,HL
	LD		C,L
	POP		HL

.CONT:
	LD		A,(HL)			; Read memory
	CP		B				; Compare to code
	JR		NZ,.SKP			; Skip if no compare

	POP		AF				; A = one/two byte flag
	OR		A				; Zero true if one byte search
	PUSH	AF
	JR		Z,.OBCP

	INC		HL				; Two byte search
	LD		A,(HL)
	DEC		HL
	CP		C
	JR		NZ,.SKP

.OBCP:
	INC		HL
	LD		A,(HL)			; Read next byte
	DEC		HL				; Decrement address
	CALL	ERR				; Display data found

.SKP:
	CALL	BMP				; Check if done
	JR		NZ,.CONT		; Back for more
	POP		AF				; Remove flag saved on stack
	RET

;--------------------------------------------------------------------------
; TMEM <T> - destructive memory test routine, skipping monitor page
;--------------------------------------------------------------------------
TMEM:
	CALL	DSPMSG
	DEFB	'Destructive Tes',BIT7+'t'

	CALL	TAHEX			; Read addresses
	LD		BC,0x5A5A		; Init BC to 01011010,01011010

.CYCL:
	LD		A,'.'			; Display '.' before each cycle
	CALL	PTCN
	CALL	RNDM
	PUSH	BC				; Keep all registers
	PUSH	HL
	PUSH	DE

.TLOP:
	LD		A,H				; Get MSB of address
	AND		0xF0			; Upper nibble only
	CP		.MONSTART>>8	; Compare to MSB of monitor page
	JR		Z,.SKIPWR		; In monitor, skip write

	CALL	RNDM
	LD		(HL),B			; Write in memory

.SKIPWR:
	CALL	BMP
	JR		NZ,.TLOP		; Repeat loop

	POP		DE				; Restore original values
	POP		HL
	POP		BC
	PUSH	HL
	PUSH	DE

.RLOP:
	LD		A,H				; Get MSB of address
	AND		0xF0			; Upper nibble only
	CP		.MONSTART>>8	; Compare to MSB of monitor page
	JR		Z,.SKIPRD		; In monitor, skip the read

	CALL	RNDM			; Generate new sequence
	LD		A,(HL)			; Read memory
	CP		B				; Compare memory
	CALL	NZ,ERR			; Call error routine

.SKIPRD:
	CALL	BMP
	JR		NZ,.RLOP

	POP		DE
	POP		HL
	CALL	PAUSE			; Check for ctrl-c, esc, or space
	JR		.CYCL			; Cycle again

; This routine generates pseudo-random numbers
RNDM:
	LD		A,B				; Look at B
	AND		10110100B		; Mask bits
	AND		A				; Clear carry
	JP		PE,.PEVE		; Jump if even
	SCF

.PEVE:
	LD		A,C				; Look at C
	RLA						; Rotate carry in
	LD		C,A				; Restore C
	LD		A,B				; Look at B
	RLA						; Rotate carry in
	LD		B,A				; Restore B
	RET						; Return with new BC

;--------------------------------------------------------------------------
; SETBRK <U> - set breakpoint
;--------------------------------------------------------------------------
SETBRK:
	CALL	DSPMSG
	DEFB	'Break a',BIT7+'t'
	CALL	AHEX			; DE = breakpoint address

; Patch RST1 vector
	LD		A,0xC3			; JP opcode
	LD		(RST1),A		; RST1 vector address
	LD		HL,DUMPREGS
	LD		(RST1+1),HL		; Store breakpoint handler address

	LD 		HL,(.BP_TABLE)	; Get breakpoint address
	LD		A,0xCF			; RST 08 opcode
	CP		(HL)			; Check if another breakpoint is already set
	JR		NZ,.SETCODE		; If not, set new breakpoint

	CALL	CLRBRK			; Otherwise clear old breakpoint first

.SETCODE:
	LD		(.BP_TABLE),DE	; Store BP address in table
	LD		A,(DE)			; Retrieve byte at this location
	LD		(.BP_TABLE+2),A	; Store byte
	LD		A,0xCF			; RST 08 opcode
	LD		(DE),A			; Replace user byte with RST 08 opcode
	RET

;--------------------------------------------------------------------------
; CLRCMD <V> - remove breakpoint RST opcode if one is set
;--------------------------------------------------------------------------
CLRCMD:
	LD		HL,(.BP_TABLE)	; Get breakpoint address
	LD		A,0xCF			; RST 08 opcode
	CP		(HL)			; Check if another breakpoint is already set
	JR		Z,.CLRDSP		; If set, display msg and clear breakpoint

	CALL	DSPMSG
	DEFB	'No BP se',BIT7+'t'

	RET

.CLRDSP:
	CALL	DSPMSG
	DEFB	'BP cleare',BIT7+'d'

CLRBRK:
	LD		HL,(.BP_TABLE)	; Get breakpoint address
	LD		A,(.BP_TABLE+2)	; Get original byte
	LD		(HL),A			; Replace original byte
	RET

;--------------------------------------------------------------------------
; SDWRT <W> - write one SD block (512 bytes)
;--------------------------------------------------------------------------
SDWRT:
	CALL	DSPMSG
	DEFB	'SD Writ',BIT7+'e'

	CALL	SD_DETECT		; Check for physical SD card
	CALL	SD_BOOT			; Boot SD card for block transfers

	CALL	AHEX			; DE -> source address
	LD		(.HLTEMP),DE	;	and save it

	CALL	TAHEX			; HL -> destination block MSW, DE -> destination block LSW

; Push the 32-bit starting block number onto the stack in little-endian order
	PUSH	HL				; High half in HL
	PUSH	DE				; Low half in DE
	LD		HL,(.HLTEMP)	; Restore source address
	EX		DE,HL			;	and put in DE
	CALL	SD_CMD24 
	POP		HL				; Remove the block number from the stack
	POP		HL

	OR		A
	RET		Z				; Return to command loop if no error

	JP		SD_ERROR

;--------------------------------------------------------------------------
; BLOAD <Y> - load a binary file
;--------------------------------------------------------------------------
BLOAD:
	CALL	DSPMSG
	DEFB	'Binary Loa',BIT7+'d'

	CALL	TAHEX			; Destination address in HL, size in DE

	PUSH	HL				; Protect HL
	CALL	DSPMSG
	DEFB	CR,LF,'Waiting for file ..',BIT7+'.',CR,LF

	POP		HL

.BLOAD1:
	IN		A,(ACTL)		; Read port status
	AND		RDA				; Data available?
	JR		Z,.BLOAD1		; Loop if not

	IN		A,(ADTA)		; Read byte
	LD		(HL),A			;	and save
	INC		HL				; Address counter

	DEC		DE				; Byte counter
	LD		A,D
	OR		E				; Check if done
	JR		NZ,.BLOAD1

	JP		.FLUSH			; Flush console and tail call exit

;--------------------------------------------------------------------------
; BDUMP <Z> - dump a binary file
;--------------------------------------------------------------------------
BDUMP:
	CALL	DSPMSG
	DEFB	'Binary Dum',BIT7+'p'

	CALL	TAHEX			; Source address in HL, size in DE

	PUSH	HL				; Protect HL
	CALL	DSPMSG
	DEFB	CR,LF,'Any key to begin ..',BIT7+'.',CR,LF

	POP		HL

.BDLOP:
	IN		A,(ACTL)		; Read port status
	AND		RDA				; Data available?
	JR		Z,.BDLOP		; Loop if not

.BDUMP1:
	IN		A,(ACTL)		; Read port status
	AND		TBE				; OK to transmit?
	JR		Z,.BDUMP1		; Loop if not

	LD		A,(HL)			; Get byte
	OUT		(ADTA),A		;	and send
	INC		HL				; Address counter

	DEC		DE				; Byte counter
	LD		A,D
	OR		E				; Check if done
	JR		NZ,.BDUMP1
	RET

;**************************************************************************
;
;		T Y P E  C O N V E R S I O N ,  I N P U T,  O U T P U T
;						S U B R O U T I N E S
;
;**************************************************************************

;--------------------------------------------------------------------------
; TAHEX - read two 16 bit hex addresses. 1st returned in HL, 2nd in DE
; Destroys: A, C
;--------------------------------------------------------------------------
TAHEX:
	CALL	AHEX			; Get first address parameter
							; Fall into AHEX to get 2nd parameter

;--------------------------------------------------------------------------
; AHEX - read 4 hex ASCII digits, convert to binary
; AHE0 - read number in C of ASCII hex digits, convert to binary
; AHEEXNR - verify ASCII hex digit in A, convert to binary
;
; Returns: Display a space, binary value in DE
; Destroys: A, C, HL
;--------------------------------------------------------------------------
AHEX:
	LD		C,4				; Count of 4 digits

AHE0:
	LD		HL,0			; 16 bit zero

.AHE1:
	CALL	RDCN			; Read a byte

; Verify valid hex digit and convert from ASCII to binary and place in HL
AHEXNR:
	CP		'0'
	JP		C,START			; Below '0', abort
	CP		'9'+1
	JR		C,.ALPH			; '9' or above jump else verify valid alpha digit

	AND		0x5F			; Lower to upper case
	CP		'A'
	JP		C,START
	CP		'F'+1
	JP		NC,START		; Below 'A' or above 'F' abort back to START

.ALPH:
	ADD		HL,HL			; HL * 2
	ADD		HL,HL			; HL * 4
	ADD		HL,HL			; HL * 8
	ADD		HL,HL			; HL * 16 (= shift L 4 bits left, one hex digit)

	CALL	ASC2BIN			; Convert A from ASCII to a binary value
	ADD		A,L
	LD		L,A				; Stuff into L
	DEC		C
	JR		NZ,.AHE1		; Keep reading
	EX		DE,HL			; Result in DE
							; Fall through to display a space

;--------------------------------------------------------------------------
; SPCE - display a space
; PTCN - display character passed in A
;--------------------------------------------------------------------------
SPCE:
	LD		A,' '			; Display space

PTCN:
	PUSH	AF

.PTLOP:
	IN		A,(ACTL)		; Wait for OK to transmit character
	AND		TBE
	JR		Z,.PTLOP

	POP		AF				; Recover AF
	AND		0x7F			; Get rid of MSB
	OUT		(ADTA),A		; And display it
	RET

;--------------------------------------------------------------------------
; ASC2BIN - ASCII hex digit to binary conversion. Digit
;	passed in A, returned in A
;--------------------------------------------------------------------------
ASC2BIN:
	SUB		'0'				; '0' to 0 (ASCII bias)
	CP		10				; Digit 0 - 9?
	RET		C

	SUB		7				; 'A-F' to A-F (Alpha bias)
	RET

;--------------------------------------------------------------------------
; BINH - display MSN of byte passed in A
; BINL - display LSN of byte passed in A
;--------------------------------------------------------------------------
BINH:
	RRA						; Move MSN to LSN
	RRA
	RRA
	RRA

BINL:
	AND		0FH				; Low 4 bits
	ADD		A,'0'			; ASCII bias
	CP		0x3A			; Digit 0-9
	JP		C,PTCN			; Display digit, tail call exit
	ADD		A,7				; Alpha digit A-F
	JP		PTCN			; Display alpha, tail call exit

;--------------------------------------------------------------------------
; BMP - binary compare address and increment HL. Return zero flag true if
;	HL = DE. Once HL = DE, then DE is incremented each time
;	so the comparison remains true for subsequent calls
; Destroys: A
;--------------------------------------------------------------------------
BMP:
	LD		A,E				; Compare LSB's of HL,DE
	SUB		L
	JR		NZ,.GO_ON		; Not equal

	LD		A,D				; Compare MSB's of HL,DE
	SBC		A,H				; Gives zero flag true if equal

.GO_ON:
	INC		HL				; Increment HL
	RET		NZ				; Exit if HL <> DE yet

	INC		DE				; Increase DE as well so it will
	RET						;	still be equal next time

;--------------------------------------------------------------------------
; CNTLC - see if a character is at the console. If not, return
;	zero true. If ctrl-c or ESC typed, abort and return to the
;	command loop. Otherwise, return the character in A
; Destroys: A
;--------------------------------------------------------------------------
CNTLC:
	IN		A,(ACTL)		; Character at console?
	AND		RDA
	RET		Z				; No, exit with zero true

	IN		A,(ADTA)		; Get the character
	AND		0x7F			; Strip off MSB

	CP		CTRLC
	JP		Z,START			; Abort with ctrl-c
	CP		ESC
	JP		Z,START			; Or ESC
	RET

;--------------------------------------------------------------------------
; CRLF - display CR/LF
; Destroys: A
;--------------------------------------------------------------------------
CRLF:
	LD		A,CR
	CALL	PTCN
	LD		A,LF
	JP		PTCN			; Tail call exit

;--------------------------------------------------------------------------
; DSPBANK - display the currently selected 32K RAM bank
;	using the address in HL
; Destroys: A
;--------------------------------------------------------------------------
DSPBANK:
	BIT		7,H				; Get bank if address < 0x8000
	JR		Z,.GETBANK
	LD		A,0x0F			; Else force bank display to F
	JR		.DMPBANK

.GETBANK:
	LD 		A,(.CBANK)		; Get current bank

.DMPBANK:
	PUSH	AF				; Protect AF
	CALL	PAUSE			; Check for ctrl-c, esc or space
	POP		AF
	CALL	BINL			; Display low nibble
	CALL	SPCE			; Add a space
	RET

;--------------------------------------------------------------------------
; DSPMSG - display in-line message. String terminated by byte
;	with MSB set. Leaves a trailing space
; Destroys: A, HL
;--------------------------------------------------------------------------
DSPMSG:
	POP		HL				; HL -> string to display from caller

.DSPLOOP:
	LD		A,(HL)			; A = next character to display
	CALL	PTCN			; Display character
	OR		(HL)			; MSB set? (last byte)
	INC		HL				; Point to next character
	JP		P,.DSPLOOP		; No, keep looping

	CALL	SPCE			; Display a trailing space
	JP		(HL)			; Return past the string

;--------------------------------------------------------------------------
; DUMPREGS - dump registers, flags and stack after a previously set
;	breakpoint. Offer option to escape to main command loop, continue
;	execution, do a memory dump or set a new breakpoint and then execute
;--------------------------------------------------------------------------
DUMPREGS:
	LD		(.HLTEMP),HL	; Save HL when breakpoint occurred
	EX		(SP),HL			; Transfer SP contents -> HL (return address after breakpoint)
	DEC		HL				; Adjust back to breakpoint address
	LD		(.PCTEMP),HL	; Save PC when breakpoint occurred
	EX		(SP),HL			; Swap back
	PUSH	AF				; Save AF

	LD		HL,2			; Skip over AF push above
	ADD		HL,SP
	LD		(.SPTEMP),HL	; Save SP when breakpoint occurred

	CALL	DSPMSG			; Display register/flag status header
	DEFB	CR,LF,LF,'BP reached',CR,LF
	DEFB	'Bnk  PC  _Flag_  AF   BC   DE   HL   IX   IY   SP '
	DEFB	'  AF',0x27		; 0x27 = ' character
	DEFB	'  BC',0x27
	DEFB	'  DE',0x27
	DEFB	'  HL',0x27
	DEFB	' @BC @DE @HL @SP',CR,BIT7+LF

	LD		HL,(.PCTEMP)
	CALL	DSPBANK			; Display currently selected 32K RAM bank
	CALL	SPCE
	CALL	PTAD1			; Then display PC

	POP		HL				; Transfer AF -> HL pushed on above
	LD		(.AFTEMP),HL
	LD		(.BCTEMP),BC
	LD		(.DETEMP),DE	; Save AF BC DE when breakpoint occurred

; Display flags from HL (Shown as SZHENC; characters displayed when corresponding flag is set)
	LD		BC,0x8053		; S - sign (0x80 = 10000000, 0x53 = 'S')
	CALL	.MASKFLG
	LD		BC,0x405A		; Z - zero (0x40 = 01000000, 0x5A = 'Z')
	CALL	.MASKFLG
	LD		BC,0x1048		; H - half carry (0x10 = 00010000, 0x48 = 'H')
	CALL	.MASKFLG
	LD		BC,0x0445		; E - even parity (0x04 = 00000100, 0x45 = 'E')
	CALL	.MASKFLG
	LD		BC,0x024E		; N - add/subtract (0x02 = 00000010, 0x4E = 'N')
	CALL	.MASKFLG
	LD		BC,0x0143		; C - carry (0x01 = 00000001, 0x43 = 'C')
	CALL	.MASKFLG

	CALL	SPCE
	CALL	PTAD1			; Display AF from HL

	LD		BC,(.BCTEMP)
	LD		HL,(.HLTEMP)	; Get back BC HL, DE still safe
	CALL	.PTHREE			; Display BC DE HL

	PUSH	IX
	POP		HL				; Transfer IX -> HL
	CALL	PTAD1			; Display IX from HL

	PUSH	IY
	POP		HL				; Transfer IY -> HL
	CALL	PTAD1			; Display IY from HL

	LD		HL,(.SPTEMP)	; Get breakpoint SP
	CALL	PTAD1			; Display SP from HL

	EX		AF,AF'			; Swap AF <-> AF'
	PUSH	AF				; AF' on stack
	EX		AF,AF'			; Restore AF
	POP		HL				; Transfer AF' -> HL
	CALL	PTAD1			; Display AF' from HL

	EXX						; Swap 16-bit register pairs
	CALL	.PTHREE			; Display BC' DE' HL'
	EXX						; Swap back

	LD		BC,(.BCTEMP)	; Restore BC
	LD		A,(BC)
	CALL	.PT2S			; Display contents of BC

	LD		DE,(.DETEMP)	; Restore DE
	LD		A,(DE)
	CALL	.PT2S			; Display contents of DE

	LD		HL,(.HLTEMP)	; Restore HL
	LD		A,(HL)
	CALL	.PT2S			; Display contents of HL

	POP		HL				; Get contents of SP
	DEC		SP
	DEC		SP				; Restore back stack
	CALL	PTAD1			; Display contents of SP

	CALL	DSPMSG
	DEFB	CR,LF,LF,'_Stack Dump_ (SP+15 bytes',BIT7+')'

	CALL	CRLF
	LD		HL,(.SPTEMP)	; Get breakpoint SP
	LD		B,16			; Show last 16 bytes of the stack

.DSTACK:
	CALL	SPCE
	CALL	DSPBANK			; Display current RAM bank from address in HL
	CALL	SPCE
	CALL	PTAD1			; Display current stack address from HL
	CALL	SPCE

	LD		A,(HL)			; A = byte to display
	CALL	PT2				; Display it
	CALL	CRLF

	INC		HL				; Advance stack address pointer
	DEC		B				; Adjust counter
	JR		NZ,.DSTACK		; Continue?

	CALL	CLRCMD			; Clear and display breakpoint cleared
	CALL	CRLF

.SUBMSG:
	CALL	DSPMSG
	DEFB	CR,LF,'<Esc>Abort <Enter>Continue <Space>Dump <LLLL>New BP?-',BIT7+'>'

.SUBCMD:
	LD		C,4				; Count of 4 digits
	LD		HL,0x0000		; 16 bit zero

.AHE2:
	CALL	RDCN			; Read a byte

	CP		ESC
	JP		Z,START			; Esc?, restart @ main command loop

	CP		' '
	JR		Z,.PREDUMP		; Space?, process DUMP command

	CP		CR
	JR		Z,.CONTINUE		; Enter?, continue from breakpoint
							; Else, process new breakpoint address

	CP		'0'
	JR		C,.SUBMSG		; Below '0', abort back to .SUBMSG
	CP		'9'+1
	JR		C,.ALPH2		; '9' or below jump else verify valid alpha digit

	AND		0x5F			; Lower to upper case
	CP		'A'
	JR		C,.SUBMSG
	CP		'F'+1
	JR		NC,.SUBMSG		; Below 'A' or above 'F' abort back to .SUBMSG

.ALPH2:
	ADD		HL,HL			; HL * 2
	ADD		HL,HL			; HL * 4
	ADD		HL,HL			; HL * 8
	ADD		HL,HL			; HL * 16 (= shift L 4 bits left, one hex digit)

	CALL	ASC2BIN			; Convert A from ASCII to a binary value
	ADD		A,L
	LD		L,A				; Stuff into L
	DEC		C				; Adjust counter
	JR		NZ,.AHE2		; Keep reading

	LD		(.BP_TABLE),HL	; Store BP address in table
	LD		A,(HL)			; Retrieve byte at this location
	LD		(.BP_TABLE+2),A	; Store byte
	LD		A,0xCF			; RST 08 opcode
	LD		(HL),A			; Replace user byte with RST 08 opcode

.CONTINUE:					; Put registers back like they were before breakpoint occurred
	CALL	CRLF
	LD		HL,(.AFTEMP)	; Restore AF
	PUSH	HL
	POP		AF

	LD		BC,(.BCTEMP)	
	LD		DE,(.DETEMP)
	LD		HL,(.HLTEMP)	; Restore BC DE HL
							; SP still good at this point
	RET						; Continue where breakpoint left off

.PREDUMP:
	PUSH	AF				; Protect AF BC HL
	PUSH	BC
	PUSH	HL

	CALL	CRLF
	LD		A,'*'
	CALL	PTCN			; Display command prompt for uniformity
	CALL	DUMP			; Execute DUMP, get address range and display
	CALL	CRLF

	POP		HL
	POP		BC
	POP		AF
	JP		.SUBMSG			; Back to .SUBMSG

.PT2S:
	CALL	PT2				; Display 2 characters
	CALL	SPCE			; Display 2 spaces
	JP		SPCE			; Tail call exit

; Display BC DE HL in order
.PTHREE:
	PUSH	HL				; Protect HL
	PUSH	BC
	POP		HL				; Transfer BC -> HL
	CALL	PTAD1			; Display BC
	PUSH	DE
	POP		HL				; Transfer DE -> HL
	CALL	PTAD1			; Display DE
	POP		HL				; Get HL back
	JP		PTAD1			; Display HL and tail call exit

.MASKFLG:
	LD		A,L				; Get flags from L
	AND		B				; Flag mask in B
	LD		A,' '			; Display blank if flag cleared
	JP		Z,PTCN			; Tail call exit
	LD		A,C				; Display flag character from C
	JP		PTCN			; Tail call exit

;--------------------------------------------------------------------------
; ERR - display the address in HL followed by the value in B, then in A
; PT2 - display the value in A	
;--------------------------------------------------------------------------
ERR:
	PUSH	AF				; Protect AF
	CALL	PTAD			; Display address
	LD		A,B				; Display B
	CALL	PT2
	CALL	SPCE
	POP		AF

PT2:						; Display A
	PUSH	AF				; Protect AF
	CALL	BINH			; High 4 bits
	POP		AF
	JP		BINL			; Low 4 bits, tail call exit

;--------------------------------------------------------------------------
; GETCHAR - read a character from the console port into A. The
;	character is also echoed to the console port if the echo
;	flag (C) is set (non-zero)
;--------------------------------------------------------------------------
GETCHAR:
	PUSH	BC				; Protect BC

	CALL	GETCON			; Read character from console
							; Process new character in A
							; Echo to console if C is non-zero
	LD		B,A				; Save character in B
	LD		A,C				; Echo flag (C) set?
	OR		A
	JR		Z,.NOECHO		; No echo

	LD		A,B				; A = character to send
	POP		BC
	JP		PTCN			; Display character and tail call exit

.NOECHO:
	LD		A,B				; A = byte read
	POP		BC
	RET

;--------------------------------------------------------------------------
; IBYTE - read two ASCII hex bytes and return binary value in E, add binary
;   value to running checksum in D
; Destroys: A
;--------------------------------------------------------------------------
IBYTE:
	CALL	GETCHAR			; Get a character
	CALL	ASC2BIN			; ASCII hex digit to binary
	ADD		A,A				; Put in MSN, zero LSN
	ADD		A,A
	ADD		A,A
	ADD		A,A
	LD		E,A				; Save byte with MSN in E

; 2nd byte (LSN)
	CALL	GETCHAR			; Get a character
	CALL	ASC2BIN			; ASCII hex digit to binary
	ADD		A,E				; Combine MSN and LSN
	LD		E,A				; Save in E
	ADD		A,D				; Add character to checksum
	LD		D,A				; Save checksum back in D
	RET

;--------------------------------------------------------------------------
; PAUSE - pause/resume with spacebar. Also look for a ctrl-c
;	or ESC to abort
; Destroys: A
;--------------------------------------------------------------------------
PAUSE:
	CALL	CNTLC			; Look for abort or other character
	CP		' '
	RET		NZ				; Return if not space or abort

.PLOOP:
	CALL	CNTLC			; Loop here until space or abort pressed
	CP		' '
	JR		NZ,.PLOOP
	RET

;--------------------------------------------------------------------------
; PTAD - display CR/LF and the address in HL
; PTAD1 - display the address in HL
; Destroys: A
;--------------------------------------------------------------------------
PTAD:
	CALL	CRLF

PTAD1:
	CALL	PAUSE			; Check for ctrl-c, esc, or space
	LD		A,H
	CALL	PT2				; Display ASCII codes for address
	LD		A,L
	CALL	PT2
	CALL	SPCE
	RET

;--------------------------------------------------------------------------
; RDCN - read from console to A with echo to screen
; GETCON - read from console to A without echo
;--------------------------------------------------------------------------
RDCN:
	CALL	GETCON			; Get character from console
	CP		ESC				; ESC confuses smart terminals
	RET		Z				; 	 so don't echo escape
	JP		PTCN			; Echo onto display and tail call exit

GETCON:
	IN		A,(ACTL)		; Read keyboard status
	AND		RDA				; Data available?
	JR		Z,GETCON

	IN		A,(ADTA)		; Read from keyboard
	AND		0x7F			; Strip off MSB
	RET

;**************************************************************************
;
;					S D  C A R D  S U B R O U T I N E S
;
;**************************************************************************

;--------------------------------------------------------------------------
; SD_ERROR - display SD card error message
; Destroys: HL
;--------------------------------------------------------------------------
SD_ERROR:
	CALL	DSPMSG
	DEFB	'- Error with SD car',BIT7+'d',CR,LF

	JP		MONIT			; Restart monitor

;--------------------------------------------------------------------------
; SD_DETECT- check if physical SD card inserted
; Destroys: A, HL
;--------------------------------------------------------------------------
SD_DETECT:
	IN		A,(GPIO_IN)		
	AND		GPIO_IN_SD_DET
	RET		Z				; RET if card inserted

; Display error and exit if no SD card in slot
	CALL	DSPMSG
	DEFB	'- SD slot empt',BIT7+'y',CR,LF

	JP		MONIT			; Restart monitor

;**************************************************************************
;
; An SD card library suitable for talking to SD cards in SPI mode 0
;
; WARNING: SD cards are 3.3v ONLY!
; Must provide a pull up on MISO to 3.3V
; SD cards operate on SPI mode 0
;
; References:
; - SD Simplified Specifications, Physical Layer Simplified Specification,
;	Version 8.00:	https://www.sdcard.org/downloads/pls/
;
; The details on operating an SD card in SPI mode can be found in
; Section 7 of the SD specification, p242-264
;
; To initialize an SDHC/SDXC card:
; - send at least 74 CLKs
; - send CMD0 & expect reply message = 0x01 (enter SPI mode)
; - send CMD8 (establish that the host uses Version 2.0 SD SPI protocol)
; - send ACMD41 (finish bringing the SD card on line)
; - send CMD58 to verify the card is SDHC/SDXC mode (512-byte block size)
;
; At this point the card is on line and ready to read and write
; memory blocks
;
; - use CMD17 to read one 512-byte block
; - use CMD24 to write one 512-byte block
;
;**************************************************************************

;--------------------------------------------------------------------------
; Read B number of blocks into memory at address DE starting with
; 32-bit little-endian block number on the stack
; Return A = 0 = success!
;--------------------------------------------------------------------------
READ_BLOCKS:
							; +12 = starting block number
							; +10 = return address
	PUSH	BC				; +8
	PUSH	DE				; +6
	PUSH	IY				; +4

	LD		IY,-4
	ADD		IY,SP			; IY = &block_number
	LD		SP,IY

; Copy the first block number
	LD		A,(IY+12)
	LD		(IY+0),A
	LD		A,(IY+13)
	LD		(IY+1),A
	LD		A,(IY+14)
	LD		(IY+2),A
	LD		A,(IY+15)
	LD		(IY+3),A

.READ_BLOCK_N:
	LD		A,'.'
	CALL 	PTCN			; Display loading progress dots ...
	
; SP is currently pointing at the block number
	CALL	SD_CMD17
	OR		A
	JR		NZ,.RB_FAIL

; Count the block
	DEC		B
	JR		Z,.RB_SUCCESS	; Note that A == 0 here = success!

; Increment the target address by 512
	INC		D
	INC		D

; Increment the 32-bit block number
	INC		(IY+0)
	JR		NZ,.READ_BLOCK_N
	INC		(IY+1)
	JR		NZ,.READ_BLOCK_N
	INC		(IY+2)
	JR		NZ,.READ_BLOCK_N
	INC		(IY+3)
	JR		.READ_BLOCK_N

.RB_SUCCESS:
	XOR		A

.RB_FAIL:
	LD		IY,4
	ADD		IY,SP
	LD		SP,IY
	POP		IY
	POP		DE
	POP		BC
	RET

;--------------------------------------------------------------------------
; NOTE: Response message formats in SPI mode are different than in SD mode
;
; Read bytes until we find one with MSB = 0 or bail out retrying
; Return last read byte in A (and a copy also in E)
; Calls SPI_READ8
; Destroys: A, B, DE
;--------------------------------------------------------------------------
.SD_READ_R1:
	LD		B,0xF0			; B = number of retries

.SD_R1_LOOP:
	CALL	SPI_READ8		; Read a byte into A (and a copy in E as well)
	AND		BIT7			; Is the MSB set to 1?
	JR		Z,.SD_R1_DONE	; If MSB == 0 then we are done
	DJNZ	.SD_R1_LOOP		; Else try again until the retry count runs out

.SD_R1_DONE:
	LD		A,E				; Copy the final value into A
	RET

;--------------------------------------------------------------------------
; NOTE: Response message formats in SPI mode are different than in SD mode
;
; Read an R7 message into the 5-byte buffer pointed to by HL
; Destroys: A, B, DE, HL
;--------------------------------------------------------------------------
.SD_READ_R7:
	CALL	.SD_READ_R1		; A = byte #1
	LD		(HL),A			; Save it
	INC		HL				; Advance receive buffer pointer
	CALL	SPI_READ8		; A = byte #2
	LD		(HL),A			; Save it
	INC		HL				; Advance receive buffer pointer
	CALL	SPI_READ8		; A = byte #3
	LD		(HL),A			; Save it
	INC		HL				; Advance receive buffer pointer
	CALL	SPI_READ8		; A = byte #4
	LD		(HL),A			; Save it
	INC		HL				; Advance receive buffer pointer
	CALL	SPI_READ8		; A = byte #5
	LD		(HL),A			; Save it
	RET

;--------------------------------------------------------------------------
; SSEL = HI (de-assert)
; Wait at least 1msec after power up
; Send at least 74 (80) SCLK rising edges
; Destroys: A, B, DE
;--------------------------------------------------------------------------
SD_BOOT:
	LD		B,10			; 10*8 = 80 bits to read

.SD_BOOT1:
	CALL	SPI_READ8		; Read 8 bits (causes 8 CLK x-itions)
	DJNZ	.SD_BOOT1		; If not yet done, do another byte

; The response byte should be 0x01 (idle) from CMD0
	CALL	SD_CMD0
	CP		0x01
	JR		Z,.BOOT_SD_1

	JP		SD_ERROR

.BOOT_SD_1:
	LD		DE,.SD_SCRATCH	; Temporary buffer
	CALL	SD_CMD8			; CMD8 verify v2+ SD card and agree on voltage
							; CMD8 also expands functionality of CMD58 & ACMD41
							
; The response should be: 0x01 0x00 0x00 0x01 0xAA
	LD		A,(.SD_SCRATCH)
	CP		1
	JR		Z,.BOOT_SD_2

	JP		SD_ERROR

.BOOT_SD_2:
.AC41_MAX_RETRY: EQU	0x80	; Limit the number of ACMD41 retries

	LD		B,.AC41_MAX_RETRY

.AC41_LOOP:
	PUSH	BC				; Save BC since B contains the retry count
	LD		DE,.SD_SCRATCH	; Store command response
	CALL	SD_ACMD41		; Ask if the card is ready
	POP		BC				; Restore our retry counter
	OR		A				; Check to see if A is zero
	JR		Z,.AC41_DONE	; If A is zero, then the card is ready

; Card is not ready, waste some time before trying again
	LD		HL,0x1000		; Count to 0x1000 to consume time

.AC41_DLY:
	DEC		HL				; HL = HL-1
	LD		A,H				; Does HL == 0?
	OR		L
	JR		NZ,.AC41_DLY	; If HL != 0 then keep counting

	DJNZ	.AC41_LOOP		; If (--retries != 0) then try again

.AC41_FAIL:
	JP		SD_ERROR

.AC41_DONE:
; Find out the card capacity (HC or XC)
; This status is not valid until after ACMD41
	LD		DE,.SD_SCRATCH
	CALL	SD_CMD58

; Check that CCS == 1 here to indicate that we have an HC/XC card
	LD		A,(.SD_SCRATCH+1)
	AND		0x40			; CCS bit is here (See spec p275)
	RET		NZ				; Good to go

	JP		SD_ERROR

;--------------------------------------------------------------------------
; Send a command and read an R1 response message
; HL = command buffer address
; B = command byte length
; Returns A = reply message byte
; Destroys: A, BC, DE, HL
;
; Modus operandi
; SSEL = LO (assert)
; Send CMD
; Send arg 0
; Send arg 1
; Send arg 2
; Send arg 3
; Send CRC 
; Wait for reply (MSB = 0)
; Read reply
; SSEL = HI
;--------------------------------------------------------------------------
.SD_CMD_R1:
; Assert the SSEL line
	CALL	SPI_SSEL_TRUE

; Write a sequence of bytes representing the CMD message
	CALL	SPI_WRITE_STR	; Write B bytes from HL buffer address

; Read the R1 response message
	CALL	.SD_READ_R1		; A = E = message response byte

; De-assert the SSEL line
	CALL	SPI_SSEL_FALSE

	LD		A,E
	RET

;--------------------------------------------------------------------------
; Send a command and read an R7 response message
; Note that an R3 response is the same size, so can use the same code
; HL = command buffer address
; B = command byte length
; DE = 5-byte response buffer address
; Destroys: A, BC, DE, HL
;--------------------------------------------------------------------------
.SD_CMD_R3:
.SD_CMD_R7:
	CALL	SPI_SSEL_TRUE

	PUSH	DE				; Save the response buffer address
	CALL	SPI_WRITE_STR	; Write cmd buffer from HL, length = B

; Read the response message into buffer address in HL
	POP		HL				; Pop the response buffer address HL
	CALL	.SD_READ_R7

; De-assert the SSEL line
	CALL	SPI_SSEL_FALSE
	RET

;--------------------------------------------------------------------------
; Send a CMD0 (GO_IDLE) message and read an R1 response
;
; CMD0 will
; 1) Establish the card protocol as SPI (if has just powered up)
; 2) Tell the card the voltage at which we are running it
; 3) Enter the IDLE state
;
; Return the response byte in A
; Destroys: A, BC, DE, HL
;--------------------------------------------------------------------------
SD_CMD0:
	LD		HL,.SD_CMD0_BUF	; HL = command buffer
	LD		B,.SD_CMD0_LEN	; B = command buffer length
	CALL	.SD_CMD_R1		; Send CMD0, A = response byte
	RET

.SD_CMD0_BUF:	DEFB	0|0x40,0,0,0,0,0x94|0x01
.SD_CMD0_LEN:	EQU	$-.SD_CMD0_BUF

;--------------------------------------------------------------------------
; Send a CMD8 (SEND_IF_COND) message and read an R7 response
;
; Establish that we are squawking V2.0 of spec & tell the SD
; card the operating voltage is 3.3V.  The reply to CMD8 should
; be to confirm that 3.3V is OK and must echo the 0xAA back as
; an extra confirm that the command has been processed properly
; The 0x01 in the byte before the 0xAA in the command buffer
; below is the flag for 2.7-3.6V operation
;
; Establishing V2.0 of the SD spec enables the HCS bit in
; ACMD41 and CCS bit in CMD58
;
; Return the 5-byte response in the buffer pointed to by DE
; The response should be: 0x01 0x00 0x00 0x01 0xAA
; Destroys: A, BC, DE, HL
;--------------------------------------------------------------------------
SD_CMD8:
	LD		HL,.SD_CMD8_BUF
	LD		B,.SD_CMD8_LEN
	CALL	.SD_CMD_R7
	RET

.SD_CMD8_BUF:	DEFB	8|0x40,0,0,0x01,0xAA,0x86|0x01
.SD_CMD8_LEN:	EQU	$-.SD_CMD8_BUF

;--------------------------------------------------------------------------
; Send a CMD58 message and read an R3 response
; CMD58 is used to ask the card what voltages it supports and
; if it is an SDHC/SDXC card or not
; Return the 5-byte response in the buffer pointed to by DE
; Destroys: A, BC, DE, HL
;--------------------------------------------------------------------------
SD_CMD58:
	LD		HL,.SD_CMD58_BUF
	LD		B,.SD_CMD58_LEN
	CALL	.SD_CMD_R3
	RET

.SD_CMD58_BUF:	DEFB	58|0x40,0,0,0,0,0x00|0x01
.SD_CMD58_LEN:	EQU	$-.SD_CMD58_BUF

;--------------------------------------------------------------------------
; Send a CMD55 (APP_CMD) message and read an R1 response
; CMD55 is used to notify the card that the following message is an ACMD
; (as opposed to a regular CMD.)
; Return the 1-byte response in A
; Destroys: A, BC, DE, HL
;--------------------------------------------------------------------------
SD_CMD55:
	LD		HL,.SD_CMD55_BUF	; HL = buffer to write
	LD		B,.SD_CMD55_LEN		; B = buffer byte count
	CALL	.SD_CMD_R1			; Write buffer, A = R1 response byte
	RET

.SD_CMD55_BUF:	DEFB	55|0x40,0,0,0,0,0x00|0x01
.SD_CMD55_LEN:	EQU	$-.SD_CMD55_BUF

;--------------------------------------------------------------------------
; Send a ACMD41 (SD_SEND_OP_COND) message and return an R1 response byte in A
;
; The main purpose of ACMD41 to set the SD card state to READY so
; that data blocks may be read and written.  It can fail if the card
; is not happy with the operating voltage
;
; Destroys: A, BC, DE, HL
; Note that A-commands are prefixed with a CMD55
;--------------------------------------------------------------------------
SD_ACMD41:
	CALL	SD_CMD55			; Send the A-command prefix

	LD		HL,.SD_ACMD41_BUF	; HL = command buffer
	LD		B,.SD_ACMD41_LEN	; B = buffer byte count
	CALL	.SD_CMD_R1
	RET

; SD spec p263 Fig 7.1 footnote 1 says we want to set the HCS bit here for HC/XC cards
; Notes on Internet about setting the supply voltage in ACMD41. But not in SPI mode?
; The following works on my MicroCenter SDHC cards:

.SD_ACMD41_BUF:	DEFB	41|0x40,0x40,0,0,0,0x00|0x01	; Note the HCS flag is set here
.SD_ACMD41_LEN:	EQU	$-.SD_ACMD41_BUF

;--------------------------------------------------------------------------
; CMD17 (READ_SINGLE_BLOCK)
;
; Read one block given by the 32-bit (little endian) number at
; the top of the stack into the buffer given by address in DE
;
; - Set SSEL = true
; - Send command
; - Read for CMD ACK
; - Wait for 'data token'
; - Read data block
; - Read data CRC
; - Set SSEL = false
;
; A = 0 if the read operation was successful. Else A = 1
; Destroys: A, IX
;--------------------------------------------------------------------------
SD_CMD17:
							; +10 = &block_number
							; +8 = return address
	PUSH	BC				; +6
	PUSH	HL				; +4
	PUSH	IY				; +2
	PUSH	DE				; +0 target buffer address

	LD		IY,.SD_SCRATCH	; IY = buffer to format command
	LD		IX,10			; 10 is the offset from SP to the location of the block number
	ADD		IX,SP			; IX = address of uint32_t sd_lba_block number

	LD		(IY+0),17|0x40	; The command byte
	LD		A,(IX+3)		; Stack = little endian
	LD		(IY+1),A		; cmd_buffer = big endian
	LD		A,(IX+2)
	LD		(IY+2),A
	LD		A,(IX+1)
	LD		(IY+3),A
	LD		A,(IX+0)
	LD		(IY+4),A
	LD		(IY+5),0x00|0x01	; The CRC byte

; Assert the SSEL line
	CALL	SPI_SSEL_TRUE

; Send the command 
	PUSH	IY
	POP		HL				; HL = IY = cmd_buffer address
	LD		B,6				; B = command buffer length
	CALL	SPI_WRITE_STR	; Destroys A, BC, D, HL

; Read the R1 response message
	CALL	.SD_READ_R1		; Destroys A, B, DE

; If R1 status != SD_READY (0x00) then error (SD spec p265, Section 7.2.3)
	OR		A				; If (A == 0x00) then is OK
	JR		Z,.SD_CMD17_R1OK

	JR		.SD_CMD17_ERR

.SD_CMD17_R1OK:
; Read and toss bytes while waiting for the data token
	LD		BC,0x1000		; Expect to wait a while for a reply ~ 14.5msec @ 10Mhz

.SD_CMD17_LOOP:
	CALL	SPI_READ8		; Destroys A, DE
	CP		0xFF			; If (A == 0xFF) then command is not yet completed
	JR		NZ,.SD_CMD17_TOKEN
	DEC		BC
	LD		A,B
	OR		C
	JR		NZ,.SD_CMD17_LOOP

	JR		.SD_CMD17_ERR	; No flag ever arrived

.SD_CMD17_TOKEN:
	CP		0xFE			; A == data block token? (else is junk from the SD)
	JR		Z,.SD_CMD17_TOKOK

	JR		.SD_CMD17_ERR

.SD_CMD17_TOKOK:
	POP		HL				; HL = target buffer address
	PUSH	HL				; And keep the stack level the same
	LD		BC,0x200		; 512 bytes to read

.SD_CMD17_BLK:
	CALL	SPI_READ8		; Destroys A, DE
	LD		(HL),A
	INC		HL				; Increment the buffer pointer
	DEC		BC				; Decrement the byte counter

	LD		A,B				; Did BC reach zero?
	OR		C
	JR		NZ,.SD_CMD17_BLK	; If not, go back & read another byte

	CALL	SPI_READ8		; Read the CRC value (XXX should check this)
	CALL	SPI_READ8		; Read the CRC value (XXX should check this)

	CALL	SPI_SSEL_FALSE
	XOR		A				; A = 0 = success!

.SD_CMD17_DONE:
	POP		DE
	POP		IY
	POP		HL
	POP		BC
	RET

.SD_CMD17_ERR:
	CALL	SPI_SSEL_FALSE

	LD		A,0x01			; Return an error flag
	JR		.SD_CMD17_DONE

;--------------------------------------------------------------------------
; CMD24 (WRITE_SINGLE_BLOCK)
;
; Write one block given by the 32-bit (little endian) number at
; the top of the stack from the buffer given by address in DE
;
; - Set SSEL = true
; - Send command
; - Read for CMD ACK
; - Send 'data token'
; - Write data block
; - Wait while busy
; - Read 'data response token' (must be 0bxxx00101 else errors) (see SD spec: 7.3.3.1, p281)
; - Set SSEL = false
;
; - Set SSEL = true
; - Wait while busy		Wait for the write operation to complete
; - Set SSEL = false
;
; XXX This /should/ check to see if the block address was valid
; and that there was no write protect error by sending a CMD13
; after the long busy wait has completed.
;
; A = 0 if the write operation was successful. Else A = 1
; Destroys: A, IX
;--------------------------------------------------------------------------
SD_CMD24:
							; +10 = &block_number
							; +8 = return address
	PUSH	BC				; +6
	PUSH	DE				; +4 target buffer address
	PUSH	HL				; +2
	PUSH	IY				; +0

	LD		IY,.SD_SCRATCH	; IY = buffer to format command
	LD		IX,10			; 10 is the offset from SP to the location of the block number
	ADD		IX,SP			; IX = address of uint32_t sd_lba_block number

.SD_CMD24_LEN: EQU	6

	LD		(IY+0),24|0x40	; The command byte
	LD		A,(IX+3)		; Stack = little endian
	LD		(IY+1),A		; cmd_buffer = big endian
	LD		A,(IX+2)
	LD		(IY+2),A
	LD		A,(IX+1)
	LD		(IY+3),A
	LD		A,(IX+0)
	LD		(IY+4),A
	LD		(IY+5),0x00|0x01	; The CRC byte

; Assert the SSEL line
	CALL	SPI_SSEL_TRUE

; Send the command 
	PUSH	IY
	POP		HL				; HL = IY = &cmd_buffer
	LD		B,.SD_CMD24_LEN
	CALL	SPI_WRITE_STR	; Destroys A, BC, D, HL

; Read the R1 response message
	CALL	.SD_READ_R1		; Destroys A, B, DE

; If R1 status != SD_READY (0x00) then error
	OR		A				; If (A == 0x00)
	JR		Z,.SD_CMD24_R1OK	; Then OK
							; Else error...
	JR		.SD_CMD24_ERR

.SD_CMD24_R1OK:
; Give the SD card an extra 8 clocks before we send the start token
	CALL	SPI_READ8

; Send the start token: 0xFE
	LD		C,0xFE
	CALL	SPI_WRITE8		; Destroys A, DE

; Send 512 bytes
	LD		L,(IX-6)		; HL = source buffer address
	LD		H,(IX-5)
	LD		BC,0x200		; BC = 512 bytes to write

.SD_CMD24_BLK:
	PUSH	BC				; XXX speed this up
	LD		C,(HL)
	CALL	SPI_WRITE8		; Destroys A, DE
	INC		HL
	POP		BC				; XXX speed this up
	DEC		BC
	LD		A,B
	OR		C
	JR		NZ,.SD_CMD24_BLK

; Read for up to 250msec waiting on a completion status
	LD		BC,0xAB00			; Wait a potentially /long/ time for the write to complete

; [n] = number of T states, 57 T states @ 10Mhz = 5.7us. 250msec ~ 0xAB00 loop cycles
.SD_CMD24_WDR:					; Wait for data response message
	CALL	SPI_READ8			; [17] Destroys A, DE
	CP		0xFF				; [7]
	JR		NZ,.SD_CMD24_DRC	; [7F/12T]
	DEC		BC					; [6]
	LD		A,B					; [4]
	OR		C					; [4]
	JR		NZ,.SD_CMD24_WDR	; [7F/12T]

	JR		.SD_CMD24_ERR		; Timed out

.SD_CMD24_DRC:
; Make sure the response is 0bxxx00101 else is an error
	AND		0x1F
	CP		0x05
	JR		Z,.SD_CMD24_OK

	JR		.SD_CMD24_ERR

.SD_CMD24_OK:
	CALL	SPI_SSEL_FALSE

; Wait until the card reports that it is not busy
	CALL	SPI_SSEL_TRUE

.SD_CMD24_BUSY:
	CALL	SPI_READ8		; Destroys A, DE
	CP		0xFF
	JR		NZ,.SD_CMD24_BUSY

	CALL	SPI_SSEL_FALSE

	XOR		A				; A = 0 = success!

.SD_CMD24_DONE:
	POP		IY
	POP		HL
	POP		DE
	POP		BC
	RET

.SD_CMD24_ERR:
	CALL	SPI_SSEL_FALSE

	LD		A,0x01			; Return an error flag
	JR		.SD_CMD24_DONE

;--------------------------------------------------------------------------
; A buffer for exchanging messages with the SD card
;--------------------------------------------------------------------------
.SD_SCRATCH:
	DEFS	6

;**************************************************************************
;
;					S P I  P O R T  S U B R O U T I N E S
;
;**************************************************************************

;**************************************************************************
; An SPI library suitable for talking to SD cards
;
; This library implements SPI mode 0 (SD cards operate on SPI mode 0.)
; Data changes on falling CLK edge & sampled on rising CLK edge:
;        __                                             ___
; /SSEL    \______________________ ... ________________/      Host --> Device
;                 __    __    __   ... _    __    __
; CLK    ________/  \__/  \__/  \__     \__/  \__/  \______   Host --> Device
;        _____ _____ _____ _____ _     _ _____ _____ ______
; MOSI        \_____X_____X_____X_ ... _X_____X_____/         Host --> Device
;        _____ _____ _____ _____ _     _ _____ _____ ______
; MISO        \_____X_____X_____X_ ... _X_____X_____/         Host <-- Device
;
;**************************************************************************

;--------------------------------------------------------------------------
; Write 8 bits in C to the SPI port and discard the received data
; It is assumed that the GPIO_OUT_CACHE value matches the current state
; of the GP output port and that SSEL is low
; This will leave: CLK = 1, MOSI = (the LSB of the byte written)
; Destroys: A, DE
;--------------------------------------------------------------------------
SPI_WRITE8:
	LD		A,(GPIO_OUT_CACHE)	; Get current GPIO_OUT value
	AND		0+~(GPIO_OUT_SD_MOSI|GPIO_OUT_SD_CLK)	; MOSI & CLK = 0
	LD		D,A					; Save in D for reuse

	PUSH	BC					; Setup to run .SPI_WRITE1 8 times
	LD		B,8
	LD		E,BIT7				; Bit mask

; Send the 8 bits ([n] = number of T states used)
.SPI_WRITE1:
	LD		A,E					; [9] Get current bit mask
	AND		C					; [4] Check if bit in C is a 1
	LD		A,D					; [9] A = GPIO_OUT value w/CLK & MOSI = 0
	JR		Z,.LO_BIT			; [7F/12T] Send a 0
	OR		GPIO_OUT_SD_MOSI	; [7] prepare to transmit a 1

.LO_BIT:
	OUT		(GPIO_OUT),A		; [11] Set data value & CLK falling edge
	OR		GPIO_OUT_SD_CLK		; [7] Ready the CLK to send a 1
	OUT		(GPIO_OUT),A		; [11] Set the CLK's rising edge

	SRL		E					; [8] Adjust bit mask
	DJNZ	.SPI_WRITE1			; [8 B=0/13] Continue until all 8 bits are sent

	POP		BC
	RET

;--------------------------------------------------------------------------
; Read 8 bits from the SPI & return it in A
; MOSI will be set to 1 during all bit transfers
; This will leave: CLK = 1, MOSI = 1
; Returns the byte read in A (and a copy of it also in E)
; Destroys: A, DE
;--------------------------------------------------------------------------
SPI_READ8:
	LD		E,0					; Prepare to accumulate the bits into E

	LD		A,(GPIO_OUT_CACHE)	; Get current GPIO_OUT value
	AND		~GPIO_OUT_SD_CLK	; CLK = 0
	OR		GPIO_OUT_SD_MOSI	; MOSI = 1
	LD		D,A					; Save in D for reuse

	PUSH	BC					; Setup to run .SPI_READ1 8 times
	LD		B,8

; Read the 8 bits
.SPI_READ1:
	LD		A,D
	OUT		(GPIO_OUT),A		; Set data value & CLK falling edge
	OR		GPIO_OUT_SD_CLK		; Set the CLK bit
	OUT		(GPIO_OUT),A		; CLK rising edge

	IN		A,(GPIO_IN)			; Read MISO
	AND		GPIO_IN_SD_MISO		; Strip all but the MISO bit
	OR		E					; Accumulate the current MISO value
	RLCA						; The LSB is read last, rotate into proper place
								; NOTE: this only works because GPIO_IN_SD_MISO = 0x80
	LD		E,A					; Save a copy of the running value in A and E

	DJNZ	.SPI_READ1			; Continue until all 8 bits are read

; The final value will be in both the E and A registers
	POP		BC
	RET

;--------------------------------------------------------------------------
; Assert the select line (set it low)
; This will leave: SSEL = 0, CLK = 0, MOSI = 1
; Destroys: A
;--------------------------------------------------------------------------
SPI_SSEL_TRUE:
	PUSH	DE					; Save DE because READ8 alters it

; Read and discard a byte to generate 8 clk cycles
	CALL	SPI_READ8

	LD		A,(GPIO_OUT_CACHE)

; Make sure the clock is low before we enable the card
	AND		~GPIO_OUT_SD_CLK	; CLK = 0
	OR		GPIO_OUT_SD_MOSI	; MOSI = 1
	OUT		(GPIO_OUT),A

; Enable the card
	AND		~GPIO_OUT_SD_SSEL	; SSEL = 0
	LD		(GPIO_OUT_CACHE),A	; Save current state in the cache
	OUT		(GPIO_OUT),A

; Generate another 8 clk cycles
	CALL	SPI_READ8

	POP		DE
	RET

;--------------------------------------------------------------------------
; De-assert the select line (set it high)
; This will leave: SSEL = 1, CLK = 0, MOSI = 1
; Destroys: A
;
; See section 4 of 
;	Physical Layer Simplified Specification Version 8.00
;--------------------------------------------------------------------------
SPI_SSEL_FALSE:
	PUSH	DE					; Save DE because READ8 alters it

; Read and discard a byte to generate 8 clk cycles
	CALL	SPI_READ8

	LD		A,(GPIO_OUT_CACHE)

; Make sure the clock is low before we disable the card
	AND		~GPIO_OUT_SD_CLK	; CLK = 0
	OUT		(GPIO_OUT),A

	OR		GPIO_OUT_SD_SSEL|GPIO_OUT_SD_MOSI	; SSEL = 1, MOSI = 1
	LD		(GPIO_OUT_CACHE),A
	OUT		(GPIO_OUT),A

; Generate another 16 clk cycles
	CALL	SPI_READ8
	CALL	SPI_READ8

	POP		DE
	RET

;--------------------------------------------------------------------------
; HL = address of bytes to write
; B = byte count
; Destroys: A, BC, DE, HL
;--------------------------------------------------------------------------
SPI_WRITE_STR:
	LD		C,(HL)			; Get next byte to send
	CALL	SPI_WRITE8		; Send it
	INC		HL				; Point to the next byte
	DJNZ	SPI_WRITE_STR	; Count the byte & continue if not done
	RET

;**************************************************************************
;
;					E N D  O F  S U B R O U T I N E S
;
;**************************************************************************

; Temporary storage area (21D bytes)
GPIO_OUT_CACHE:	DEFB	GPIO_OUT_SD_MOSI|GPIO_OUT_SD_SSEL|GPIO_OUT_PRN_STB|(.BANK<<4)
.CBANK:			DEFB	.BANK	; Current low 32K RAM bank selected 0-E
.AFTEMP:		DEFS	2		; AF temp
.BCTEMP:		DEFS	2		; BC temp
.DETEMP:		DEFS	2		; DE temp
.HLTEMP:		DEFS	2		; HL temp
.PCTEMP:		DEFS	2		; PC temp
.SPTEMP:		DEFS	2		; SP temp
.PARTITION:		DEFS	1		; Partition number to boot
.BP_TABLE:		DEFS	3		; Breakpoint location first, then byte at loc
.PORT_RW:		DEFS	3		; Area for port read/write commands

;--------------------------------------------------------------------------
; This marks the end of the data that is copied from FLASH into SRAM
;--------------------------------------------------------------------------
.END:

	END