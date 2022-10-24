# Z80-Retro! Monitor

A comprehensive monitor utility for the [Z80-Retro!](https://github.com/johnwinans/2063-Z80) SBC.

## Description

retromon.asm - a Z80 assembler utility monitor to interact with the
[Z80-Retro!](https://github.com/johnwinans/2063-Z80) SBC. Commands include memory bank select, dump, program,
search, compare, copy, exchange, test, fill, execute, checksum, and
file and port I/O. Breakpoints can be set and a register/stack display
is presented. SPI/SD card support and the ability to launch CP/M 2.2.

## Companion Projects

[Z80-Retro! I2C/SPI Master Interface Board & Drive Library](https://github.com/KRSynthWorx/z80-retro-i2cspi)

## Help

```
	-Command Summary-

	A -> D select low 32k RAM bank 0-E
	B -> Boot CP/M
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
	R -> BBBB BBBB DDDD read block (512 bytes) from SD card
	S -> SSSS FFFF DD one byte search
	T -> SSSS FFFF destructive memory test
	U -> LLLL set breakpoint
	V -> Clear breakpoint
	W -> LLLL BBBB BBBB write block (512 bytes) to SD card
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

This monitor runs 100% in a 4096 byte page of SRAM on the Z80-Retro!
The stack is located at the end of this page. The device initialization
code is first copied from FLASH to SRAM low bank 0 beginning at 0x0000
on every boot. Next, the monitor code is copied from the FLASH to its
final location in SRAM high bank F. The FLASH is then disabled which
remaps the SRAM into the FLASH address space. Execution continues in the
SRAM low bank to finish device initialization. The code then jumps and
begins execution in the upper bank and the low bank is now available
for any use.

Whew... ok, All this trouble saves some SRAM as the device
initialization code only needs to execute once on boot and can be
discarded. Additionally we need the low SRAM to use CP/M.

All commands immediately echo a full command name as soon as the
first command letter is typed. This makes it easier to identify
commands without a list of commands present, although (H) 'Help' will
list all available commands for you. Upper or lower case can be used.

The command prompt is an asterisk. Backspace and DEL are not used.
If you make a mistake, type ESC (or ctrl-c) to get back to the prompt
and re-enter the command. Most executing commands can be aborted by
ESC (or ctrl-c).

All commands are a single letter. Four hex digits must be typed in
for an address. Two hex digits must be typed for a byte. An exception
is the (A) 'Select Bank' command which takes only 1 hex digit.

The spaces you see between the parameters are displayed by the monitor,
you don't type them. The command executes as soon as the last required
value is typed – a RETURN should not be typed.

Long running displays can be paused/resumed with the space bar.

The (D) 'Dump' command shows the currently selected lower 32K SRAM
bank in the first column of the display, the memory contents requested,
and an ASCII representation in additional columns. Bank 0 is selected
at every boot and reflects addresses 0x0000-0x7FFF. You can change this
low 32K bank with the (A) 'Select Bank' command to any desired bank
0 - E. Addresses 0x8000-0xFFFF are always in bank F and not switchable.
The dump display always shows bank F when viewing memory above 0x7FFF.
The breakpoint, register and stack display also shows the currently
selected 32K bank in the first column of the display.

NOTE: All memory operation commands operate on the memory within
the currently selected low 32K bank. Memory operations above 0x7FFF
(upper 32K bank F) always affect that bank only regardless of the
currently selected low 32K bank. Currently there is no facility to
transfer memory between banks with this monitor but this can be done
in your own programs by accessing the GPIO_OUT port 0x10 bits 4-7.
Programs changing the SRAM bank should be executed only from the
upper 32K bank beginning at 0x8000 to avoid crashing when the bank
switch occurs. Otherwise the switch over code can be duplicated in
multiple banks to allow uninterrupted execution between low banks.
This monitor is currently located at 0xB000-0xBFFF. Addresses
0xC000-0xFFFF are reserved for the CP/M loader, BDOS, CCP and BIOS,
but can still be used if not booting CP/M from the SD card.

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
specified. The monitor then displays it's asterisk main prompt.
The (V) 'Clear Breakpoint' command can be used to manually remove an
unwanted breakpoint. Setting another breakpoint will clear the previous
breakpoint and install a new one. Upon execution of the code containing
the breakpoint, control is returned to the monitor and a register/stack
display is shown. The breakpoint is automatically cleared at this point.
A sub command line is presented that allows (Esc) 'Abort' back to
the monitor main prompt; (Enter) 'Continue' executing code with no more
breakpoints; (Space) 'Dump' a range of memory you specify; and
(LLLL) 'New Breakpoint' where a new location address can be specified.
Execution will immediately resume to the new breakpoint.

NOTE: Your code listing should be referenced when choosing breakpoint
locations if you wish to continue execution or add new breakpoints
using the sub command options described above. Breakpoints should be
placed on opcode not operand/mid-instruction/data area addresses. The
monitor breakpoint code does not keep track of how long each
instruction is so the code under test could crash if it is stopped and
restarted mid-instruction. If you ESC out to the main command prompt
after the first breakpoint for a quick look then it doesn't matter
where you place it.

Currently configured console port settings are 9600:8N1. See the note
below in the INIT_CTC_1 function to change these settings.

Semi-Pro Tip... If you include [retromon.sym](src/retromon.sym) at the beginning of your
code, you will have access to all of the Z80-Retro! monitor subroutines
and equate values by name.

## Author

[Kenny Maytum](mailto:ken_m@comcast.net) - KRSynthWorx

## Version History

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
* [John's Basement YouTube Channel](https://www.youtube.com/c/JohnsBasement)
* [John Winans](https://github.com/johnwinans)
* [Mike Douglas](https://deramp.com)
* Martin Eberhard
