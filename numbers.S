.text
.global write_hex
# void write_hex(int number, int no_digits)
# This function outputs the number in hexadecimal

write_hex:	
	subui	$sp, $sp, 7
	sw	$2, 4($sp)
	sw	$3, 5($sp)
	sw	$ra, 6($sp)

	# Print the hexadecimal prefix
	la	$2, hex_prefix
	sw	$2, 0($sp)
	jal	print_string
	

	
	# Initialise our loop counter
	lw	$3, 8($sp)

next_char:
	# Decrement the loop counter
	subi	$3, $3, 1
	
	# Get the number
	lw	$2, 7($sp)

	# Multiply the loop counter by 4
	slli	$1, $3, 2
	# Shift the number right and extract the current nibble
	srl	$2, $2, $1
	andi	$2, $2, 0xf
	
	addi	$2, $2, '0'

	sgti	$1, $2, '9'
	beqz	$1, not_alpha
	
	addi	$2, $2, 39

not_alpha:
	# Send this character
	sw	$2, 0($sp)
	jal	send_char

	bneqz	$3, next_char

done:	
		
	lw	$ra, 6($sp)
	lw	$3, 5($sp)
	lw	$2, 4($sp)
	addui	$sp, $sp, 7
	jr	$ra



.data
hex_prefix:
	.asciiz	"0x"


.text
# void write_number(int number)
write_number:
	subui	$sp, $sp, 7
	sw	$2, 4($sp)
	sw	$3, 5($sp)
	sw	$ra, 6($sp)

	lw	$3, 7($sp)	# Get the number to print

	addu	$2, $0, $0

	
	
get_msd:
	# Here we repeatedly divide until the result is less than 10 and then we print that char
	sw	$3, 0($sp)	# Divide the
	addui	$1, $0, 10	# number by 
	sw	$1, 1($sp)	# 10
	jal	divide

	sw	$3, 0($sp)
	
	addu	$3, $1, $0	# Get the result of the division
	
	addui	$1, $0, 10
	sw	$1, 1($sp)
	jal	remainder
	
	addu	$2, $1, $0
		
	
	slti	$1, $3, 10 
	beqz	$1, get_msd

	# Here we have found the most significant digit
	addui	$1, $3, '0'
	sw	$1, 0($sp)
	jal	send_char

	
	
	lw	$ra, 6($sp)
	lw	$3, 5($sp)
	lw	$2, 4($sp)
	addui	$sp, $sp, 7
	jr	$ra
	