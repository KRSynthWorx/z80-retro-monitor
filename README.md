# Z80-Retro! Monitor

A comprehensive monitor utility for the [Z80-Retro!](https://github.com/Z80-Retro/2063-Z80) SBC.

## Description

[retromon.asm](https://github.com/KRSynthWorx/z80-retro-monitor/blob/main/src/retromon.asm) -
a Z80 assembler utility monitor to interact with the [Z80-Retro!](https://github.com/Z80-Retro/2063-Z80) SBC.
Commands include memory bank select, dump, program, search, compare, copy, exchange, test, fill, execute,
checksum, and file and port I/O. Breakpoints can be set and a register/stack display is presented.
SPI/SD card support and the ability to boot multiple partitions and launch CP/M 2.2.

## Companion Projects

[Z80-Retro! I2C/SPI Master Interface Board & Drive Library](https://github.com/KRSynthWorx/z80-retro-i2cspi)

## Help

```
	-Command Summary-

	A -> D select low 32k RAM bank
	B -> D boot SD partition
	C -> SSSS FFFF DDDD compare blocks
	D -> SSSS FFFF dump hex and ASCII
	E -> SSSS FFFF DDDD exchange block
	F -> SSSS FFFF DD DD two byte search
	G -> LLLL go to and execute
	H -> Command help
	I -> PP input from I/O port
	J -> SSSS FFFF dump Intel hex file
	K -> SSSS FFFF DD fill with constant
	L -> Load Intel hex file
	M -> SSSS FFFF DDDD copy block
	N -> Non-destructive memory test
	O -> PP DD output to port
	P -> LLLL program memory
	Q -> SSSS FFFF compute checksum
	R -> BBBB BBBB DDDD read SD block (512 bytes)
	S -> SSSS FFFF DD one byte search
	T -> SSSS FFFF destructive memory test
	U -> LLLL set breakpoint
	V -> Clear breakpoint
	W -> LLLL BBBB BBBB write SD block (512 bytes)
	X -> Reboot monitor
	Y -> DDDD CCCC load binary file
	Z -> LLLL CCCC dump binary file

	<SSSS>Start Address <FFFF>Finish Address
	<DDDD>Destination Address <D/DD>Data <PP>Port
	<BBBB BBBB>32-bit SD Block <LLLL>Location Address
	<CCCC>Size <Esc/Ctrl-c>Abort <Space>Pause
```
Using Retromon:

OK, please bear with me on this...

This monitor runs entirely in a 4096 byte page of SRAM on the [Z80-Retro!](https://github.com/Z80-Retro/2063-Z80)
The stack is located at the end of this page. The device initialization
code is first copied from FLASH to SRAM low bank 0 (or E if a 128K SRAM
is installed instead of a 512K SRAM) beginning at 0x0000 on every boot.
Next, the monitor code is copied from the FLASH to its final location in
SRAM high bank F. The FLASH is then disabled which remaps the SRAM into
the FLASH address space. Execution continues in the SRAM low bank to
finish device initialization. The code then jumps and begins execution
in the upper bank and the low bank is now available for any use.

Whew... ok, all this trouble saves some SRAM as the device initialization
code only needs to execute once on boot and can be discarded. Additionally
we need the low SRAM to use CP/M.

When auto boot is enabled (see note in [retromon.asm](https://github.com/KRSynthWorx/z80-retro-monitor/blob/main/src/retromon.asm))
and during the initialization process, the following occurs. A startup
message is displayed along with a 5 second message and progress dots
allowing you to press any key and skip the auto boot from partition 1
of an SD card. If no SD card is installed or there is an SD card error,
an SD card error message is displayed followed by the monitor asterisk
command prompt. When auto boot is disabled, the monitor command prompt
is immediately displayed.

Up to 4 partitions on the SD card are available and information on these
partitions is located in the Master Boot Record (MBR) beginning at SD
block 0 on the SD card. Partition SD block starting addresses are stored
at the following offset locations from the beginning of the MBR:
* Partition 1 -> 0x1BE+0x08
* Partition 2 -> 0x1CE+0x08
* Partition 3 -> 0x1DE+0x08
* Partition 4 -> 0x1EE+0x08

The 32-bit address at these offset locations indicates the SD card
block number of the beginning of the corresponding partition on the SD
card. Each SD block is 512 bytes in size. The monitor (B) 'Boot SD partition'
command extracts this information from the MBR. It then reads in 32 blocks
(16k bytes) and stores this beginning at 0xC000 in SRAM (which is always in
SRAM bank F). It then sets the A register to a 1 (indicating we are supplying
the partition and starting block information), sets the C register to the
partition number 1 - 4, sets the DE register to the high word of the starting
block address, and sets the HL register to the low word of the starting block
address where the code was read in from. The monitor then jumps to 0xC000
and begins execution. Hopefully something is useful there to execute.

All commands immediately echo a full command name as soon as the
first command letter is typed. This makes it easier to identify
commands without a list of commands present, although (H) 'Help' will
list all available commands for you. Upper or lower case can be used.

The command prompt is an asterisk. Backspace and DEL are not used.
If you make a mistake, type ESC (or ctrl-c) to get back to the prompt
and re-enter the command. Most executing commands can be aborted by
ESC (or ctrl-c).

All commands are a single letter. Four hex digits must be typed in
for an address. Two hex digits must be typed for a byte. Exceptions to 
this are the (A) 'Select Bank' and (B) 'Boot SD partition' command which
accept only 1 hex digit. The (H) 'Help' command indicates the number of
arguments each command accepts.

The spaces you see between the parameters are displayed by the monitor,
you don't type them. The command executes as soon as the last required
value is typed – a RETURN should not be typed.

Long running displays can be paused/resumed with the space bar.

The (D) 'Dump' command shows the currently selected lower 32K SRAM
bank in the first column of the display, the memory contents requested,
and an ASCII representation in additional columns. Bank 0 (or E if a
128K SRAM is configured) is selected at every boot and reflects
addresses 0x0000-0x7FFF. You can change this low 32K bank with the
(A) 'Select Bank' command to any desired bank 0 - E (or C - E if a
128K SRAM is configured). Addresses 0x8000-0xFFFF are always in bank F
and not switchable. The dump display always shows bank F when viewing
memory above 0x7FFF. The breakpoint, register and stack display also
indicates the currently selected 32K bank in the first column of the
display.

NOTE: All memory operation commands operate on the memory within
the currently selected low 32K bank. Memory operations above 0x7FFF
(upper 32K bank F) always affect that bank only regardless of the
currently selected low 32K bank. Currently there is no facility to
transfer memory between different low banks with this monitor but
this can be done in your own programs by accessing the GPIO_OUT
port 0x10 bits 4-7. Programs changing the SRAM bank should be
executed only from the upper 32K bank beginning at 0x8000 to avoid
crashing when the bank switch occurs. Otherwise the switch over code
can be duplicated in multiple banks to allow uninterrupted execution
between low banks. This monitor is currently located at 0xB000-0xBFFF.
Addresses 0xC000-0xFFFF are reserved for the CP/M loader, BDOS, CCP
and BIOS, but can still be used if not booting CP/M from the SD card.

The (N) 'Non-Destructive Test' command takes no parameters and runs
through the full 64K of SRAM (currently selected 32K low bank and 32k
high bank F). It skips the handful of bytes used in the memory
compare/swap routine to prevent crashing. A dot pacifier is displayed
at the start of each cycle through the memory test. Use ESC (or ctrl-c)
to exit back to the command prompt. Other low 32K SRAM banks can be
tested by first selecting another bank with the (A) 'Select Bank'
command.

The (T) 'Destructive Test' command skips the 4096 byte page that the
monitor and stack are in to prevent crashing. A dot pacifier is also
displayed as in the (N) command. Use ESC (or ctrl-c) to exit back to
the command prompt. As above, additional SRAM low banks can be tested
by first selecting the (A) 'Select Bank' command.

The (U) 'Break at' command sets a RST 08 opcode at the address
specified. The monitor then displays its asterisk main command prompt.
The (V) 'Clear Breakpoint' command can be used to manually remove an
unwanted breakpoint. Setting another breakpoint will clear the previous
breakpoint and install a new one. Upon execution of the code containing
the breakpoint, control is returned to the monitor and a register/stack
display is shown. The breakpoint is automatically cleared at this point.
A sub command line is presented that allows (Esc) 'Abort' back to
the monitor main prompt; (Enter) 'Continue' executing code with no more
breakpoints; (Space) 'Dump' a range of memory you specify; and
(LLLL) 'New BP' where a new location address can be specified. Execution
will immediately resume to the new breakpoint.

NOTE: Your code listing should be referenced when choosing breakpoint
locations if you wish to continue execution or add new breakpoints
using the sub command options described above. Breakpoints should be
placed on opcode not operand/mid-instruction/data area addresses. The
monitor breakpoint code does not keep track of how long each
instruction is so the code under test could crash if it is stopped and
restarted mid-instruction. If you ESC out to the main command prompt
after the FIRST breakpoint then it doesn't matter where you place it.

Currently configured console port settings are 9600:8N1. See the note
in the [retromon.asm](https://github.com/KRSynthWorx/z80-retro-monitor/blob/main/src/retromon.asm)
file .INIT_CTC_1 function to change these settings.

Semi-Pro Tip... If you include [retromon.sym](https://github.com/KRSynthWorx/z80-retro-monitor/blob/main/src/retromon.sym)
at the beginning of your code, you will have access to all of the
Z80-Retro! monitor public subroutines and equate values by name.

## Author

[Kenny Maytum](mailto:ken_m@comcast.net) - KRSynthWorx

## Version History

* 1.8
	* Add support to boot from multiple SD card partitions
	* Add auto SD card boot option from partition 1 at startup
	* Add support for using 128K SRAM
	* Abbreviate some ASCII strings to keep the code + stack < 4096 bytes
	* Clarify comments and documentation, update GitHub links

* 1.7
	* Update flag display to correspond to actual flag bit position
	* Add add/subtract flag
	* Allow Esc/Ctrl-c from (L) 'Hexload' command
	* Minor code cleanup/organization
	* Clarify comments and documentation

* 1.6
	* Initial Public Release

## License

This project is licensed under the [GNU Lesser General Public License] - see the LICENSE file for details

## Acknowledgments

Inspiration, code snippets, libraries, etc.
* [Z80-Retro! GitHub Project](https://github.com/Z80-Retro/2063-Z80)
* [John's Basement YouTube Channel](https://www.youtube.com/c/JohnsBasement)
* [John Winans](https://github.com/johnwinans)
* [Mike Douglas](https://deramp.com)
* [Martin Eberhard](https://en.wikipedia.org/wiki/Martin_Eberhard)
