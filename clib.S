# char *strcat(char *s, char *t)
# Concatenates t onto s, returns the pointer to the beginning of s
.global strcat
strcat:
	# Save the registers we will modify
	subui	$sp, $sp, 3
	sw	$4, 0($sp)
	sw	$5, 1($sp)
	sw	$6, 2($sp)

	# Get the parameters
	lw	$4, 3($sp)
	lw	$5, 4($sp)
	
	# Get the start of s
	addu	$1, $4, $0

	# Move back to allow for a zero length string
	subui	$4, $4, 1

strcat_findend:
	# Next character
	addui	$4, $4, 1
	# Get the character
	lw	$6, 0($4)
	# Loop while not zero
	bnez	$6, strcat_findend

strcat_cat:
	# Get the character to concatenate
	lw	$6, 0($5)
	# Move the pointer along
	addui	$5, $5, 1
	# Concatenate the character
	sw	$6, 0($4)
	# Move the pointer along
	addui	$4, $4, 1
	# Until we have reached the end of the string
	bnez	$6, strcat_cat

	# Restore the registers
	lw	$4, 0($sp)
	lw	$5, 1($sp)
	lw	$6, 2($sp)
	addui	$sp, $sp, 3
	
	# Return
	jr	$ra
	

# int strcmp(char *s, char *t)
# Compares string s to string t. s<t returns <0, s=t returns = 0, s>t returns >0
.global strcmp
strcmp:
	# Save the registers we want to use
	subui	$sp, $sp, 4
	sw	$4, 0($sp)
	sw	$5, 1($sp)
	sw	$6, 2($sp)
	sw	$7, 3($sp)

	# Get the parameters
	lw	$4, 4($sp)
	lw	$5, 5($sp)
strcmp_compare:
	# Get the characters to compare
	lw	$6, 0($4)
	lw	$7, 0($5)

	# Compare them
	sub	$1, $6, $7
	bnez	$1, strcmp_notequal

	# Move to the next characters
	addui	$4, $4, 1
	addui	$5, $5, 1

	# Loop until null character
	bnez	$6, strcmp_compare
strcmp_notequal:	
	# Restore the registers
	lw	$4, 0($sp)
	lw	$5, 1($sp)
	lw	$6, 2($sp)
	lw	$7, 3($sp)
	addui	$sp, $sp, 4

	# Return
	jr	$ra


# char *strcpy(char *s, char *t)
# Copy the string t into the buffer pointed to by s, return a pointer to the start of s
.global strcpy
strcpy:
	# Save the registers we will modify
	subui	$sp, $sp, 3
	sw	$4, 0($sp)
	sw	$5, 1($sp)
	sw	$6, 2($sp)

	# Get the parameters
	lw	$4, 3($sp)
	lw	$5, 4($sp)
	
	# Get the start of s
	addu	$1, $4, $0

strcpy_copy:
	# Get the character to copy
	lw	$6, 0($5)
	# Move the pointer along
	addui	$5, $5, 1
	# Copy the character
	sw	$6, 0($4)
	# Move the pointer along
	addui	$4, $4, 1
	# Until we have reached the end of the string
	bnez	$6, strcpy_copy

	# Restore the registers
	lw	$4, 0($sp)
	lw	$5, 1($sp)
	lw	$6, 2($sp)
	addui	$sp, $sp, 3
	
	# Return
	jr	$ra
	
	
# int strlen(char *s)
# returns the length of string s
.global strlen
strlen:
	# Save registers
	subui	$sp, $sp, 2
	sw	$4, 0($sp)
	sw	$5, 1($sp)

	# Get the parameter
	lw	$4, 2($sp)

	# Reset the counter
	addu	$1, $0, $0

strlen_loop:
	# Get the character
	lw	$5, 0($4)
	
	# Increment the pointer
	addui	$4, $4, 1

	# Exit on end of string
	beqz	$5, strlen_end

	# Increment the counter
	addui	$1, $1, 1

	# Loop
	j	strlen_loop
strlen_end:

	# Restore registers
	lw	$4, 0($sp)
	lw	$5, 1($sp)
	addui	$sp, $sp, 2
	
	# Return
	jr	$ra








# int isupper(char c)
# Returns 1 if c is an uppercase character
.global isupper
isupper:
	# Save a register
	subui	$sp, $sp, 1
	sw	$4, 0($sp)

	# Get the parameter
	lw	$4, 1($sp)

	# Test for >= 'A'
	sgei	$1, $4, 'A'
	# Test for <= 'Z'
	slei	$4, $4, 'Z'
	# We want both of these
	and	$1, $1, $4
	
	# Restore the register
	lw	$4, 0($sp)
	addui	$sp, $sp, 1
	
	# Return
	jr	$ra

# int islower(char c)
# Returns 1 if c is an lowercase character
.global islower
islower:
	# Save a register
	subui	$sp, $sp, 1
	sw	$4, 0($sp)

	# Get the parameter
	lw	$4, 1($sp)

	# Test for >= 'a'
	sgei	$1, $4, 'a'
	# Test for <= 'a'
	slei	$4, $4, 'a'
	# We want both of these
	and	$1, $1, $4
	
	# Restore the register
	lw	$4, 0($sp)
	addui	$sp, $sp, 1
	
	# Return
	jr	$ra

# int isdigit(char c)
# Returns 1 if c is an digit character
.global isdigit
isdigit:
	# Save a register
	subui	$sp, $sp, 1
	sw	$4, 0($sp)

	# Get the parameter
	lw	$4, 1($sp)

	# Test for >= '0'
	sgei	$1, $4, '0'
	# Test for <= '9'
	slei	$4, $4, '9'
	# We want both of these
	and	$1, $1, $4
	
	# Restore the register
	lw	$4, 0($sp)
	addui	$sp, $sp, 1
	
	# Return
	jr	$ra

# int ishex(char c)
# Returns 1 if c is an digit character
.global ishex
ishex:
	# Save a register
	subui	$sp, $sp, 3
	sw	$4, 0($sp)
	sw	$5, 1($sp)
	sw	$6, 2($sp)

	# Get the parameter
	lw	$4, 3($sp)

	# Test for >= '0'
	sgei	$1, $4, '0'
	# Test for <= '9'
	slei	$5, $4, '9'
	# We want both of these
	and	$1, $1, $5

	# Test for >= 'a'
	sgei	$5, $4, 'a'
	# Test for <= 'f'
	slei	$6, $4, 'f'
	# We want both of these
	and	$5, $5, $6

	# Combine with the first result
	or	$1, $1, $5
	
	# Test for >= 'A'
	sgei	$5, $4, 'A'
	# Test for <= 'F'
	slei	$6, $4, 'F'
	# We want both of these
	and	$5, $5, $6

	# Combine with the first two
	or	$1, $1, $5
	
	# Restore the register
	lw	$4, 0($sp)
	lw	$5, 1($sp)
	lw	$6, 2($sp)
	addui	$sp, $sp, 3
	
	# Return
	jr	$ra

# int isprint(char c)
# Returns 1 if c is an printable character
.global isprint
isprint:
	# Save a register
	subui	$sp, $sp, 1
	sw	$4, 0($sp)

	# Get the parameter
	lw	$4, 1($sp)

	# Test for >= 32
	sgei	$1, $4, 32
	# Test for < 127
	slti	$4, $4, 127
	# We want both of these
	and	$1, $1, $4
	
	# Restore the register
	lw	$4, 0($sp)
	addui	$sp, $sp, 1
	
	# Return
	jr	$ra

# int isspace(char c)
# returns 1 if c is a whitespace character
.global isspace
isspace:
	subui	$sp, $sp, 1
	sw	$4, 0($sp)
	
	# Get the parameter
	lw	$4, 1($sp)
	seqi	$1, $4, 32	# c == ' '
	bnez	$1, isspace_return

	slei	$1, $4, 13
	sgei	$4, $4, 9
	and	$1, $1, $4
isspace_return:

	lw	$4, 0($sp)
	addui	$sp, $sp, 1
	
	jr	$ra
	


# char tolower(char c)
# returns the lower case version of c
.global tolower
tolower:
	subui	$sp, $sp, 1
	sw	$4, 0($sp)

	# Get the parameter
	lw	$4, 1($sp)

	slti	$1, $4, 'A'
	bnez	$1, tolower_not_upcase
	
	sgti	$1, $4, 'Z'
	bnez	$1, tolower_not_upcase
	
	addui	$4, $4, 32
tolower_not_upcase:

	addu	$1, $4, $0

	lw	$4, 0($sp)
	addui	$sp, $sp, 1

	jr	$ra

# int a_con_bin(char c)
# Convert a character to its binary representation
.global a_con_bin
a_con_bin:
	subui	$sp, $sp, 6
	sw	$4, 4($sp)
	sw	$ra, 5($sp)
	
	# Get the parameter
	lw	$4, 6($sp)

	# Convert to lowercase
	sw	$4, 0($sp)
	jal	tolower
	addu	$4, $1, $0

	sw	$4, 0($sp)
	jal	isdigit

	beqz	$1, a_con_bin_not_digit

	subui	$1, $4, '0'

	j	a_con_bin_return
a_con_bin_not_digit:	

	sw	$4, 0($sp)
	jal	ishex

	beqz	$1, a_con_bin_not_hex

	subui	$1, $4, 87	# return (c - 'a' + 10)

	j	a_con_bin_return
a_con_bin_not_hex:

	addui	$1, $0, 10000
	
a_con_bin_return:	
	
	lw	$4, 4($sp)
	lw	$ra, 5($sp)
	addui	$sp, $sp, 6

	jr	$ra

.data
debug:	.asciiz	"(%08x)"
.text
# char *atoui(char *str, u_int *ptrnum, u_int base)
# convert an ASCII string to a unsigned number in base.
atoui:
	subui	$sp, $sp, 11
	sw	$4, 4($sp)
	sw	$5, 5($sp)
	sw	$6, 6($sp)
	sw	$7, 7($sp)	# next_nib
	sw	$8, 8($sp)	# accum
	sw	$9, 9($sp)	# max_accum
	sw	$ra, 10($sp)

	lw	$4, 11($sp)	# char *str
	lw	$5, 12($sp)	# u_int *ptrnum
	lw	$6, 13($sp)	# u_int base

	# max_accum = -1 / base
	subi	$1, $0, 1
	divu	$9, $1, $6
	
	# *ptrnum = 0
	sw	$0, 0($5)
	
	# accum = 0
	addu	$8, $0, $0

	# while ((next_nib = a_con_bin(*str)) < base)
atoui_loop:
	lw	$1, 0($4)
	sw	$1, 0($sp)
	jal	a_con_bin
	addu	$7, $1, $0
	sltu	$1, $7, $6
	beqz	$1, atoui_done

	# if (accum > max_accum)
	sgtu	$1, $8, $9
	bnez	$1, atoui_overflow

	# tmp = (accum * base) + next_nib
	multu	$1, $8, $6
	addu	$1, $1, $7

	
	# if (tmp < accum)
	sltu	$7, $1, $8
	bnez	$7, atoui_overflow

	# accum = tmp
	addu	$8, $1, $0

	# str++
	addui	$4, $4, 1

	j	atoui_loop
atoui_overflow:
.data
overflow_msg:	
	.asciiz	"Integer Overflow\n"
.text
	la	$1, overflow_msg
	sw	$1, 0($sp)
	jal	printf

atoui_done:	
	# *ptrnum = accum
	sw	$8, 0($5)

	# return (str)
	addu	$1, $4, $0
	
	lw	$4, 4($sp)
	lw	$5, 5($sp)
	lw	$6, 6($sp)
	lw	$7, 7($sp)
	lw	$8, 8($sp)
	lw	$9, 9($sp)
	lw	$ra, 10($sp)
	addui	$sp, $sp, 11

	jr	$ra


# char *atob(char *str, u_int *ptrnum, u_int base)
# Convert an ASCII string to a number
.global atob
atob:	
	subui	$sp, $sp, 12
	sw	$4, 4($sp)
	sw	$5, 5($sp)
	sw	$6, 6($sp)
	sw	$7, 7($sp)
	sw	$8, 8($sp)	# minus
	sw	$9, 9($sp)
	sw	$10, 10($sp)	# end_str
	sw	$ra, 11($sp)

	lw	$4, 12($sp)	# char *str
	lw	$5, 13($sp)	# u_int *ptrnum
	lw	$6, 14($sp)	# u_int base

.bss
num:	.word
.text
	# num = 0
	sw	$0, num($0)

	# while (isspace(*str))
atob_leading_whitespace:
	lw	$1, 0($4)
	sw	$1, 0($sp)
	jal	isspace
	beqz	$1, atob_check_minus

	addui	$4, $4, 1
	j	atob_leading_whitespace
atob_check_minus:
	# if (*str == '-')
	#  minus = 1, str++
	# else
	# minus = 0
	lw	$1, 0($4)
	seqi	$8, $1, '-'
	addu	$4, $4, $8

	# if (*str == '0')
	lw	$1, 0($4)
	seqi	$1, $1, '0'
	beqz	$1, atob_else

	# switch (*++str)
	addui	$4, $4, 1
	lw	$7, 0($4)
	
	seqi	$1, $7, 'x'
	seqi	$9, $7, 'X'
	or	$1, $1, $9
	beqz	$1, atob_check_octal

	# ++str
	addui	$4, $4, 1
	sw	$4, 0($sp)
	la	$1, num
	sw	$1, 1($sp)
	addui	$1, $0, 16
	sw	$1, 2($sp)
	jal	atoui
	addu	$10, $1, $0

	j	atob_break
	
atob_check_octal:	
	seqi	$1, $7, 'o'
	seqi	$9, $7, 'O'
	or	$1, $1, $9
	beqz	$1, atob_check_decimal

	# ++str
	addui	$4, $4, 1
	sw	$4, 0($sp)
	la	$1, num
	sw	$1, 1($sp)
	addui	$1, $0, 8
	sw	$1, 2($sp)
	jal	atoui
	addu	$10, $1, $0

	j	atob_break

atob_check_decimal:	
	seqi	$1, $7, 'd'
	seqi	$9, $7, 'D'
	or	$1, $1, $9
	beqz	$1, atob_default_case

	# ++str
	addui	$4, $4, 1
	sw	$4, 0($sp)
	la	$1, num
	sw	$1, 1($sp)
	addui	$1, $0, 10
	sw	$1, 2($sp)
	jal	atoui
	addu	$10, $1, $0

	j	atob_break

atob_default_case:
	# str--
	subui	$4, $4, 1
	
atob_else:	
	sw	$4, 0($sp)
	la	$1, num
	sw	$1, 1($sp)
	sw	$6, 2($sp)
	jal	atoui
	addu	$10, $1, $0

atob_break:

	# if ((minus) && num < 0)
	lw	$1, num($0)
	slt	$1, $1, $0
	and	$1, $1, $8
	beqz	$1, atob_not_overflow

.data
signed_overflow_msg:
	.asciiz	"Signed Overflow\n"
.text
	
	la	$1, signed_overflow_msg
	sw	$1, 0($sp)
	jal	printf

	j	atob_return
atob_not_overflow:	

	# else if (minus)
	beqz	$8, atob_return
	lw	$1, num($0)
	sub	$1, $0, $1
	sw	$1, num($0)
	
atob_return:
	# *ptrnum = num
	lw	$1, num($0)
	sw	$1, 0($5)

	# return(end_str)
	addu	$1, $10, $0
	
	lw	$4, 4($sp)
	lw	$5, 5($sp)
	lw	$6, 6($sp)
	lw	$7, 7($sp)
	lw	$8, 8($sp)
	lw	$9, 9($sp)
	lw	$10, 10($sp)
	lw	$ra, 11($sp)
	addui	$sp, $sp, 12

	jr	$ra














