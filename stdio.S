# void stdio_init()
# Initialise all the static variables in this file
.global stdio_init
stdio_init:
	# column = 0
	sw	$0, column($0)
	# Return
	jr	$ra
	
	
# void putchar(char c)
# Output the character c to the main serial port
.global putchar
.bss
column:	.word
.text
putchar:
	# Save some registers
	subui	$sp, $sp, 7
	sw	$4, 4($sp)
	sw	$5, 5($sp)
	sw	$ra, 6($sp)

	# Get the parameter
	lw	$4, 7($sp)

	# Test for newline
	seqi	$1, $4, '\n'
	beqz	$1, putchar_not_newline

	# putchar('\r')	
	addui	$1, $0, '\r'
	sw	$1, 0($sp)
	jal	putchar
	
	# column = 0
	sw	$0, column($0)
	
	j	putchar_case_end
putchar_not_newline:	
	# Test for tab
	seqi	$1, $4, '\t'
	beqz	$1, putchar_default

putchar_do_loop:
	# putchar(' ')
	addui	$1, $0, 32 # ' ' Should make this work
	sw	$1, 0($sp)
	jal	putchar

	# column % 8
	lw	$1, column($0)
#	sw	$1, 0($sp)
#	addui	$1, $0, 8
#	sw	$1, 1($sp)
#	jal	remainder

	remui	$1, $1, 8
	
	# while (column % 8)
	bnez	$1, putchar_do_loop

	j	putchar_return
	
putchar_default:	
	# isprint(c)
	sw	$4, 0($sp)
	jal	isprint

	# if (...) column++
	lw	$5, column($0)
	addu	$5, $5, $1
	sw	$5, column($0)

putchar_case_end:	
	sw	$4, 0($sp)
	jal	send_char
	
putchar_return:
	# Restore the registers
	lw	$4, 4($sp)
	lw	$5, 5($sp)
	lw	$ra, 6($sp)
	addui	$sp, $sp, 7

	# Return
	jr	$ra


# void printf(char *fmt, ...)
# Print the string as given by the format specifier
.global printf
.bss

__fmt:	.word	# char *__fmt
__ptrbf:
	.word	# char *__ptrbf

buf:	.space	30	# char buf[30]
c:	.word	# char c
base:	.word	# int base
s:	.word	# char *s
adj:	.word	# char adj
argcount:
	.word	# int argcount
x:	.word	# int x
n:	.word	# int n
m:	.word	# int m
width:	.word	# long width
padchar:
	.word	# char padchar
charset:
	.word	# long charset
.text
printf:
	# Save some registers
	subui	$sp, $sp, 12
	sw	$2, 4($sp)
	sw	$3, 5($sp)
	sw	$4, 6($sp)
	sw	$5, 7($sp)
	sw	$6, 8($sp)
	sw	$7, 9($sp)
	sw	$8, 10($sp)
	sw	$ra, 11($sp)

	# Get the format specifier
	lw	$2, 12($sp) # get fmt
	addui	$7, $sp, 13	# Get the offset of the first argument
	
	
	# argcount = 0
	sw	$0, argcount($0)
	# charset = 0
	sw	$0, charset($0)
	# _ptrbf = buf
	la	$8, buf
		
printf_nextchar:
	# Get the next format character
	lw	$3, 0($2)
	# Increment the pointer
	addui	$2, $2, 1

	# Exit if null character
	beqz	$3, printf_return

	# Test for the % character
	seqi	$1, $3, '%'
	beqz	$1, printf_normalchar

	# adj = 'r'
	addui	$1, $0, 'r'
	sw	$1, adj($0)

	# if (*__fmt == '-')
	lw	$3, 0($2)
	seqi	$1, $3, '-'
	beqz	$1, printf_padchar

	# adj = 'l'
	addui	$1, $0, 'l'
	sw	$1, adj($0)
	# __fmt++
	addui	$2, $2, 1

printf_padchar:
	# padchar = ' '
	addui	$1, $0, 32    # ' '  Again
	sw	$1, padchar($0)
	
	# if (*__fmt == '0')
	lw	$3, 0($2)
	seqi	$1, $3, '0'
	beqz	$1, printf_width

	# padchar = '0'
	sw	$3, padchar($0)
printf_width:
	# width = __conv()
	sw	$2, __fmt($0)
	jal	__conv
	sw	$1, width($0)
	lw	$2, __fmt($0)

	# s = 0
	sw	$0, s($0)
	
	# switch (c = *__fmt++)
	lw	$3, 0($2)
	addui	$2, $2, 1
	sw	$3, c($0)	

	# Test for 'd' or 'D' or 'u'
	seqi	$4, $3, 'D'
	seqi	$5, $3, 'd'
	seqi	$6, $3, 'u'
	or	$5, $5, $6
	or	$4, $4, $5
	beqz	$4, printf_octal

	# base = 10
	addui	$1, $0, 10
	sw	$1, base($0)
	
	j	printf_output
printf_octal:	

	# Test for 'o' or 'O'
	seqi	$4, $3, 'o'
	seqi	$5, $3, 'O'
	or	$4, $4, $5
	beqz	$4, printf_hexadecimal

	# base = 8
	addui	$1, $0, 8
	sw	$1, base($0)

	j	printf_output
printf_hexadecimal:

	# Test for 'X'
	seqi	$4, $3, 'X'
	seqi	$5, $3, 'x'
	bnez	$5, printf_lowercase_hex
	beqz	$4, printf_string
	
	# charset = 1
	addui	$1, $0, 1
	sw	$1, charset($0)
printf_lowercase_hex:
	# base = 16
	addui	$1, $0, 16
	sw	$1, base($0)

	j	printf_output
	
printf_string:	
	# Test for 's' or 'S'
	seqi	$4, $3, 's'
	seqi	$5, $3, 'S'
	or	$4, $4, $5
	beqz	$4, printf_character

	# s = *argptr
	lw	$1, 0($7)
	sw	$1, s($0)
	addui	$7, $7, 1
	# argcount++
	lw	$1, argcount($0)
	addui	$1, $1, 1
	sw	$1, argcount($0)
	
	j	printf_output
printf_character:	
	# Test for 'c' or 'C'
	seqi	$4, $3, 'c'
	seqi	$5, $3, 'C'
	or	$4, $4, $5
	beqz	$4, printf_default

	# x = *argptr
	lw	$4, 0($7)
	sw	$4, x($0)
	addui	$7, $7, 1
	# argcount++
	lw	$1, argcount($0)
	addui	$1, $1, 1
	sw	$1, argcount($0)

	# *__ptrbf++ = x & 0xff
	andi	$1, $4, 0xff
	sw	$1, 0($8)
	addui	$8, $8, 1
	# *__ptrbf = 0
	sw	$0, 0($8)
	
	# s = buf
	la	$1, buf
	sw	$1, s($0)
		
	j	printf_output

printf_default:
	# *__ptrbf++ = c
	andi	$1, $3, 0xff
	sw	$1, 0($8)
	addui	$8, $8, 1
	# *__ptrbf = 0
	sw	$0, 0($8)
	
	# s = buf
	la	$1, buf
	sw	$1, s($0)

printf_output:
	# if (s == 0)
	lw	$1, s($0)
	bnez	$1, printf_get_strlen

	# x = *argptr
	lw	$4, 0($7)
	sw	$4, x($0)
	addui	$7, $7, 1
	
	# argcount++
	lw	$1, argcount($0)
	addui	$1, $1, 1
	sw	$1, argcount($0)

	# prtn(base, x, charset)

	sw	$8, __ptrbf($0)
	lw	$1, base($0)
	sw	$1, 0($sp)
	lw	$1, x($0)
	sw	$1, 1($sp)
	lw	$1, charset($0)
	sw	$1, 2($sp)
	jal	prtn
	lw	$8, __ptrbf($0)
	
	# *__ptrbf = 0
	sw	$0, 0($8)
	
	# s = buf
	la	$1, buf
	sw	$1, s($0)
	
	# charset = 0
	sw	$0, charset($0)
	
printf_get_strlen:	
	# n = strlen(s)
	sw	$1, 0($sp)
	jal	strlen
	sw	$1, n($0)

	# m = width - n
	lw	$4, width($0)
	subu	$4, $4, $1
	sw	$4, m($0)

	# if (adj == 'r')
	lw	$1, adj($0)
	seqi	$1, $1, 'r'
	beqz	$1, printf_do_output

	# while (m-- > 0)
printf_right_pad:	
	subui	$4, $4, 1
	sge	$1, $4, $0
	beqz	$1, printf_do_output

	# Print pad character
	lw	$1, padchar($0)
	sw	$1, 0($sp)
	jal	putchar

	# Loop
	j	printf_right_pad
	
printf_do_output:

	# while (n--)
	lw	$5, n($0)
printf_output_next:
	subui	$5, $5, 1
	slt	$1, $5, $0
	bnez	$1, printf_left_pad

	# putchar(*s++)
	lw	$1, s($0)
	lw	$6, 0($1)
	sw	$6, 0($sp)
	addui	$1, $1, 1
	sw	$1, s($0)
	jal	putchar

	# Loop
	j	printf_output_next

printf_left_pad:

	# while (m-- > 0)
	subui	$4, $4, 1
	sge	$1, $4, $0
	beqz	$1, printf_reset_buffer

	# Print pad character
	lw	$1, padchar($0)
	sw	$1, 0($sp)
	jal	putchar

	# Loop
	j	printf_left_pad
printf_reset_buffer:
	la	$8, buf
	sw	$8, __ptrbf($0)

	# Next iteration of the while loop
	j	printf_nextchar
			
printf_normalchar:
	# Print this character
	sw	$3, 0($sp)
	jal	putchar
	# Loop
	j	printf_nextchar

printf_return:
	# Restore the registers
	lw	$2, 4($sp)
	lw	$3, 5($sp)
	lw	$4, 6($sp)
	lw	$5, 7($sp)
	lw	$6, 8($sp)
	lw	$7, 9($sp)
	lw	$8, 10($sp)
	lw	$ra, 11($sp)
	addui	$sp, $sp, 12
	
	# Return
	jr	$ra
	
# long __conv()
# Returns the value of a decimal ascii string
__conv:
	subui	$sp, $sp, 7
	sw	$4, 4($sp)
	sw	$5, 5($sp)
	sw	$ra, 6($sp)

	# n = 0
	addu	$4, $0, $0
__conv_loop:	
	# c = *__fmt++
	lw	$1, __fmt($0)
	lw	$5, 0($1)
	addui	$1, $1, 1
	sw	$1, __fmt($0)

	slti	$1, $5, '0'
	bnez	$1, __conv_done
	sgti	$1, $5, '9'
	bnez	$1, __conv_done

	# compute n * 10
#	sw	$4, 0($sp)
#	addui	$1, $0, 10
#	sw	$1, 1($sp)
#	jal	multiply

	multui	$4, $4, 10
#	addu	$4, $1, $0

	# compute c - '0'
	subui	$5, $5, '0'
	# n = (n * 10) + (c - '0')
	addu	$4, $4, $5

	j	__conv_loop
	
__conv_done:
	lw	$1, __fmt($0)
	subui	$1, $1, 1
	sw	$1, __fmt($0)

	# Get the return value in $1	
	addu	$1, $4, $0
	
	lw	$4, 4($sp)
	lw	$5, 5($sp)
	lw	$ra, 6($sp)
	addui	$sp, $sp, 7

	jr	$ra
	
# void prtn(int base, unsigned int x, int cset)
# convert an integer to an ascii string
.bss
tmpbuf:	.space	16
.data
lc_digits:
	.asciiz	"0123456789abcdef"
uc_digits:
	.asciiz	"0123456789ABCDEF"
.text
prtn:
	subui	$sp, $sp, 10
	sw	$4, 4($sp)
	sw	$5, 5($sp)
	sw	$6, 6($sp)
	sw	$7, 7($sp)
	sw	$8, 8($sp)
	sw	$ra, 9($sp)

	lw	$4, 10($sp)	# Get the first parameter
	lw	$5, 11($sp)
	lw	$6, 12($sp)

	# cptr = tmpbuf
	la	$7, tmpbuf
prtn_divide_loop:
	# Compute x % base
#	sw	$5, 0($sp)
#	sw	$4, 1($sp)
#	jal	remainder

	remu	$1, $5, $4
	
	# Get the address of the digit set to use
	la	$8, lc_digits
	beqz	$6, prtn_lower_case

	la	$8, uc_digits
	
prtn_lower_case:
	# Index into the array
	addu	$8, $8, $1
	# Get the character
	lw	$8, 0($8)
	# Store it into our buffer
	sw	$8, 0($7)
	# cptr++
	addui	$7, $7, 1

	# x /= b
#	sw	$5, 0($sp)
#	sw	$4, 1($sp)
#	jal	divide
#	addu	$5, $1, $0

	divu	$5, $5, $4

	bnez	$5, prtn_divide_loop

	lw	$8, __ptrbf($0)

	la	$5, tmpbuf
prtn_reverse_loop:
	# --cptr
	subui	$7, $7, 1
	lw	$1, 0($7)
	sw	$1, 0($8)
	addui	$8, $8, 1

	sgt	$1, $7, $5
	bnez	$1, prtn_reverse_loop

	sw	$8, __ptrbf($0)

	lw	$4, 4($sp)
	lw	$5, 5($sp)
	lw	$6, 6($sp)
	lw	$7, 7($sp)
	lw	$8, 8($sp)
	lw	$ra, 9($sp)
	addui	$sp, $sp, 10

	jr	$ra
	



# char *get_a_str(char *buf, char *bufp)
# Read a string from the terminal
get_a_str:
	subui	$sp, $sp, 9
	sw	$2, 4($sp)
	sw	$4, 5($sp)
	sw	$5, 6($sp)
	sw	$6, 7($sp)
	sw	$ra, 8($sp)

	lw	$5, 9($sp)	# buf
	lw	$6, 10($sp)	# bufp
	
get_a_str_loop:
	# c = getchar()
	jal	read_char
	addu	$4, $1, $0

	seqi	$1, $4, '\n'
	seqi	$2, $4, '\r'
	or	$1, $1, $2
	beqz	$1, get_a_str_not_newline

	# putchar('\n')
	addui	$1, $0, '\n'
	sw	$1, 0($sp)
	jal	putchar

	# *bufp = 0
	sw	$0, 0($6)

	# return(buf)
	addu	$1, $5, $0
	j	get_a_str_return
get_a_str_not_newline:	
	seqi	$1, $4, 0x8	# CTRL-H
	seqi	$2, $4, 0x7f	# DEL
	or	$1, $1, $2
	beqz	$1, get_a_str_not_delete

	# if (bufp > buf)
	sgt	$1, $6, $5
	beqz	$1, get_a_str_loop

	# bufp--
	subui	$6, $6, 1
	# putchar(CTRL-H)
	addui	$1, $0, 0x8
	sw	$1, 0($sp)
	jal	putchar
	# putchar(' ')
	addui	$1, $0, 32	# ' '
	sw	$1, 0($sp)
	jal	putchar
	# putchar(CTRL-H)
	addui	$1, $0, 0x8
	sw	$1, 0($sp)
	jal	putchar
	
	j	get_a_str_loop

get_a_str_not_delete:

	seqi	$1, $4, '\t'
	beqz	$1, get_a_str_not_tab

	addui	$4, $0, 32	# ' '

get_a_str_not_tab:

	sw	$4, 0($sp)
	jal	isprint

	# Compute &buf[LINESIZE-3]
	addui	$2, $5, 125
	slt	$2, $6, $2
	and	$1, $1, $2

	beqz	$1, get_a_str_no_room

	# *bufp++ = c
	sw	$4, 0($6)
	addui	$6, $6, 1

	# putchar(c)
	sw	$4, 0($sp)
	jal	putchar
	
	j	get_a_str_loop
get_a_str_no_room:

	# putchar(BELL)
	addui	$1, $0, 7	# Bell
	sw	$1, 0($sp)
	jal	putchar

	j	get_a_str_loop

get_a_str_return:

	lw	$2, 4($sp)
	lw	$4, 5($sp)
	lw	$5, 6($sp)
	lw	$6, 7($sp)
	lw	$ra, 8($sp)
	addui	$sp, $sp, 9

	jr	$ra

# char *gets(char *buf)
# Get a string from the user
.global gets
gets:
	subui	$sp, $sp, 5
	sw	$ra, 4($sp)

	lw	$1, 5($sp)
	sw	$1, 0($sp)
	sw	$1, 1($sp)
	jal	get_a_str

	lw	$ra, 4($sp)
	addui	$sp, $sp, 5

	jr	$ra



# char *gets_noecho(char *buf)
# Read a string from the terminal without echo
.global gets_noecho
gets_noecho:
	subui	$sp, $sp, 9
	sw	$2, 4($sp)
	sw	$4, 5($sp)
	sw	$5, 6($sp)
	sw	$6, 7($sp)
	sw	$ra, 8($sp)

	lw	$5, 9($sp)	# buf
	lw	$6, 9($sp)	# bufp
	
gets_noecho_loop:
	# c = getchar()
	jal	read_char
	addu	$4, $1, $0

	seqi	$1, $4, '\n'
	seqi	$2, $4, '\r'
	or	$1, $1, $2
	beqz	$1, gets_noecho_not_newline

	# *bufp = 0
	sw	$0, 0($6)

	# return(buf)
	addu	$1, $5, $0
	j	gets_noecho_return
gets_noecho_not_newline:	
	sw	$4, 0($sp)
	jal	isprint

	# Compute &buf[LINESIZE-3]
	addui	$2, $5, 125
	slt	$2, $6, $2
	and	$1, $1, $2

	beqz	$1, gets_noecho_return

	# *bufp++ = c
	sw	$4, 0($6)
	addui	$6, $6, 1
	
	j	gets_noecho_loop

gets_noecho_return:

	lw	$2, 4($sp)
	lw	$4, 5($sp)
	lw	$5, 6($sp)
	lw	$6, 7($sp)
	lw	$ra, 8($sp)
	addui	$sp, $sp, 9

	jr	$ra





