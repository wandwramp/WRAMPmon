# This subroutine loads in an S-Record to memory
.global command_load
command_load:
	subui	$sp, $sp, 9
	sw	$4, 4($sp)
	sw	$5, 5($sp)
	sw	$6, 6($sp)
	sw	$7, 7($sp)
	sw	$ra, 8($sp)


command_load_get_record:
	# Read a line at a time
	la	$4, line_buf
	sw	$4, 0($sp)
	jal	gets_noecho

	sw	$4, 0($sp)
	jal	tokenise

	jal	get_token
	addu	$4, $1, $0

	# Righto, now read the first character
	lw	$1, 0($4)
	seqi	$1, $1, 'S'
	beqz	$1, command_load_error

	# Check which type of record
	lw	$5, 1($4)
	seqi	$1, $5, '3'
	beqz	$1, command_load_not_s3

	# Move the pointer along
	addui	$4, $4, 2
	
	# Read the length now
	lw	$1, 0($4)
	sw	$1, 0($sp)
	jal	a_con_bin
	slli	$5, $1, 4

	lw	$1, 1($4)
	sw	$1, 0($sp)
	jal	a_con_bin
	or	$5, $5, $1

	# Now we have the length in $5
	# Get the address
	addui	$4, $4, 2
	
	lw	$1, 0($4)
	sw	$1, 0($sp)
	jal	a_con_bin
	slli	$6, $1, 4

	lw	$1, 1($4)
	sw	$1, 0($sp)
	jal	a_con_bin
	or	$6, $6, $1
	slli	$6, $6, 4

	lw	$1, 2($4)
	sw	$1, 0($sp)
	jal	a_con_bin
	or	$6, $6, $1
	slli	$6, $6, 4

	lw	$1, 3($4)
	sw	$1, 0($sp)
	jal	a_con_bin
	or	$6, $6, $1
	slli	$6, $6, 4

	lw	$1, 4($4)
	sw	$1, 0($sp)
	jal	a_con_bin
	or	$6, $6, $1
	slli	$6, $6, 4

	lw	$1, 5($4)
	sw	$1, 0($sp)
	jal	a_con_bin
	or	$6, $6, $1
	slli	$6, $6, 4

	lw	$1, 6($4)
	sw	$1, 0($sp)
	jal	a_con_bin
	or	$6, $6, $1
	slli	$6, $6, 4

	lw	$1, 7($4)
	sw	$1, 0($sp)
	jal	a_con_bin
	or	$6, $6, $1

	addui	$4, $4, 8
	# Now we have the address in $6

	# Remove the address and checksum from the length count
	subui	$5, $5, 5
	# Divide the length by 4 bytes per word
	srli	$5, $5, 2
	
command_load_next_word:
	beqz	$5, command_load_done_line

	# Read the word
	lw	$1, 0($4)
	sw	$1, 0($sp)
	jal	a_con_bin
	slli	$7, $1, 4

	lw	$1, 1($4)
	sw	$1, 0($sp)
	jal	a_con_bin
	or	$7, $7, $1
	slli	$7, $7, 4

	lw	$1, 2($4)
	sw	$1, 0($sp)
	jal	a_con_bin
	or	$7, $7, $1
	slli	$7, $7, 4

	lw	$1, 3($4)
	sw	$1, 0($sp)
	jal	a_con_bin
	or	$7, $7, $1
	slli	$7, $7, 4

	lw	$1, 4($4)
	sw	$1, 0($sp)
	jal	a_con_bin
	or	$7, $7, $1
	slli	$7, $7, 4

	lw	$1, 5($4)
	sw	$1, 0($sp)
	jal	a_con_bin
	or	$7, $7, $1
	slli	$7, $7, 4

	lw	$1, 6($4)
	sw	$1, 0($sp)
	jal	a_con_bin
	or	$7, $7, $1
	slli	$7, $7, 4

	lw	$1, 7($4)
	sw	$1, 0($sp)
	jal	a_con_bin
	or	$7, $7, $1

	addui	$4, $4, 8

	# Make sure we only write to RAM
	la	$1, 0x07fff
	and	$1, $1, $6
	# Put the word in memory
	sw	$7, 0($1)
	
	# Increment the address counter
	addui	$6, $6, 1
	
	# Decrement the counter
	subui	$5, $5, 1
	j	command_load_next_word
command_load_not_s3:	
	seqi	$1, $5, '7'
	beqz	$1, command_load_not_s7

	# Get the starting address of the program
	# Move the pointer along past the length
	addui	$4, $4, 4
		
	lw	$1, 0($4)
	sw	$1, 0($sp)
	jal	a_con_bin
	slli	$6, $1, 4

	lw	$1, 1($4)
	sw	$1, 0($sp)
	jal	a_con_bin
	or	$6, $6, $1
	slli	$6, $6, 4

	lw	$1, 2($4)
	sw	$1, 0($sp)
	jal	a_con_bin
	or	$6, $6, $1
	slli	$6, $6, 4

	lw	$1, 3($4)
	sw	$1, 0($sp)
	jal	a_con_bin
	or	$6, $6, $1
	slli	$6, $6, 4

	lw	$1, 4($4)
	sw	$1, 0($sp)
	jal	a_con_bin
	or	$6, $6, $1
	slli	$6, $6, 4

	lw	$1, 5($4)
	sw	$1, 0($sp)
	jal	a_con_bin
	or	$6, $6, $1
	slli	$6, $6, 4

	lw	$1, 6($4)
	sw	$1, 0($sp)
	jal	a_con_bin
	or	$6, $6, $1
	slli	$6, $6, 4

	lw	$1, 7($4)
	sw	$1, 0($sp)
	jal	a_con_bin
	or	$6, $6, $1

	# Save the address into its slot
	sw	$6, program_counter($0)

	jal	program_init
	
	la	$1, srec_complete_msg
	sw	$1, 0($sp)
	jal	printf
	
	
	# We are done after this
	j	command_load_return
	
command_load_done_line:
	# Acknowledge this line
	addui	$1, $0, '.'
	sw	$1, 0($sp)
	jal	putchar
	
	j	command_load_get_record

command_load_not_s7:
	seqi	$1, $5, '0'
	# Bad record type
	beqz	$1, command_load_error

	# We ignore S0 records
	
	j	command_load_get_record

command_load_error:
	la	$1, srec_error_msg
	sw	$1, 0($sp)
	jal	printf

command_load_return:

	lw	$4, 4($sp)
	lw	$5, 5($sp)
	lw	$6, 6($sp)
	lw	$7, 7($sp)
	lw	$ra, 8($sp)
	addui	$sp, $sp, 9

	jr	$ra

# This function sets up things for a program for when it is run for the first time
program_init:
	subui	$sp, $sp, 3
	sw	$4, 0($sp)
	sw	$5, 1($sp)
	sw	$6, 2($sp)
	
	# Setup the stack pointer to just below the bss segment
	# which is at the top of RAM
	la $4, 0x04000 # top of RAM
	la	$5, bss_size	# global symbol representing bss segment size
	subu	$4, $4, $5	# subtract to find the stack start

	# Save this into the PCB in the stack pointer slot
	la	$5, regsave	
	sw	$4, 14($5)

	# Make the initial return address the interrupt handler
	la	$4, interrupt_handler
	sw	$4, 15($5)	
	
	lw	$4, 0($sp)
	lw	$5, 1($sp)
	lw	$6, 2($sp)
	addui	$sp, $sp, 3

	jr	$ra

	
.bss
line_buf:
	.space	128
	
.data

srec_error_msg:
	.asciiz	"Error in S-Record!\n"
srec_complete_msg:
	.asciiz "S-Record successfully loaded.\n"
