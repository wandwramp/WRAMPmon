.text

.global exit_user_prog
exit_user_prog:
	syscall
	
.global init_serial
init_serial:
	# Setup the serial port for 38400 8N1
	addui	$1, $0, 0xc7
	sw	$1, 0x70002($0)
	sw	$1, serial1_control($0)
	sw	$0, 0x70004($0)
	sw	$0, serial1_iack($0)

	jr	$ra
	
# This routine saves the user's serial port settings and reverts to our defaults
.global save_serial
save_serial:
	lw	$1, 0x70002($0)	# Serial control register
	sw	$1, serial1_control($0)

	lw	$1, 0x70004($0) # IACK register
	sw	$1, serial1_iack($0)

	# Setup the serial port for 38400 8N1
	addui	$1, $0, 0xc7
	sw	$1, 0x70002($0)
	sw	$0, 0x70004($0)

	jr	$ra

# This routine restores the user's serial port settings
.global restore_serial
restore_serial:
	lw	$1, serial1_control($0)
	sw	$1, 0x70002($0)	# Serial control register

	lw	$1, serial1_iack($0)
	sw	$1, 0x70004($0) # IACK register

	jr	$ra

.bss
serial1_control:	.word
serial1_iack:		.word
.text

	
	
.global lock_rom
lock_rom:
	subui	$sp, $sp, 2
	sw	$2, 0($sp)
	sw	$3, 1($sp)

	la	$2, start_lock
	la	$3, rom_protect
copy_loop:
	lw	$1, 0($2)
	sw	$1, 0($3)

	addui	$2, $2, 1
	addui	$3, $3, 1

	la	$1, lock_rom_exit
	seq	$1, $2, $1
	beqz	$1, copy_loop
		
	lhi	$1, 0xaaaa
	ori	$1, $1, 0xaaaa
	lhi	$2, 0x5555
	ori	$2, $2, 0x5555
	lhi	$3, 0xa0a0
	ori	$3, $3, 0xa0a0

	j	rom_protect
	
start_lock:	
	sw	$1, 0x85555($0)
	sw	$2, 0x82aaa($0)
	sw	$3, 0x85555($0)

wait_lock:	
	lw	$1, 0x85555($0)
	lw	$2, 0x85555($0)

	xor	$1, $1, $2
	bnez	$1, wait_lock

	j	lock_rom_exit
	
lock_rom_exit:
	# Lock in the Spartan	
	addui	$1, $1, 0x1
	sw	$1, 0x7fff1($0)

	lw	$2, 0($sp)
	lw	$3, 1($sp)
	addui	$sp, $sp, 2
	
	jr	$ra
	
.global unlock_rom
unlock_rom:
	subui	$sp, $sp, 3
	sw	$2, 0($sp)
	sw	$3, 1($sp)
	sw	$4, 2($sp)
	
	# Unlock in the Spartan
	sw	$0, 0x7fff1($0)

	la	$2, start_unlock
	la	$3, rom_protect
unlock_copy_loop:
	lw	$1, 0($2)
	sw	$1, 0($3)

	addui	$2, $2, 1
	addui	$3, $3, 1

	la	$1, unlock_rom_exit
	seq	$1, $2, $1
	beqz	$1, unlock_copy_loop

	lhi	$1, 0xaaaa
	ori	$1, $1, 0xaaaa
	lhi	$2, 0x5555
	ori	$2, $2, 0x5555
	lhi	$3, 0x8080
	ori	$3, $3, 0x8080
	lhi	$4, 0x2020
	ori	$4, $4, 0x2020

	j	rom_protect
	
start_unlock:	
	sw	$1, 0x85555($0)
	sw	$2, 0x82aaa($0)
	sw	$3, 0x85555($0)
	sw	$1, 0x85555($0)
	sw	$2, 0x82aaa($0)
	sw	$4, 0x85555($0)

wait_unlock:	
	lw	$1, 0x85555($0)
	lw	$2, 0x85555($0)

	xor	$1, $1, $2
	bnez	$1, wait_unlock

	j	unlock_rom_exit
	
unlock_rom_exit:
	lw	$2, 0($sp)
	lw	$3, 1($sp)
	lw	$4, 2($sp)
	addui	$sp, $sp, 3	
	
	jr	$ra

.bss
rom_protect:
	.space	11
	
.text	
.global program_init
# This function sets up things for a program for when it is run for the first time
program_init:
	subui	$sp, $sp, 3
	sw	$4, 0($sp)
	sw	$5, 1($sp)
	sw	$6, 2($sp)
	
	# Setup the stack pointer to just below the bss segment
	# which is at the top of RAM
	la	$4, 0x08000	# top of RAM
	la	$5, bss_size	# global symbol representing bss segment size
	subu	$4, $4, $5	# subtract to find the stack start

	# Save this into the PCB in the stack pointer slot
	la	$5, regsave	
	sw	$4, 14($5)

	# Setup the return address
	la	$4, exit_user_prog
	sw	$4, 15($5)	
	
	lw	$4, 0($sp)
	lw	$5, 1($sp)
	lw	$6, 2($sp)
	addui	$sp, $sp, 3

	jr	$ra

.text
.global start_program
start_program:
	# Restore the program's serial port settings
	jal	restore_serial
	
	# First we setup a redirection vector to allow us to start the program
	# without altering any registers
	lw	$1, 0($sp)
	# Get the twenty bit address
	la	$2, 0xfffff
	and	$1, $1, $2
	# Turn it into a jump instruction
	lhi	$2, 0x4000
	or	$1, $1, $2
	# Store it in the vector
	sw	$1, start_vector($0)

	# Now load all the registers
	la	$1, regsave
	lw	$2, 2($1)
	lw	$3, 3($1)
	lw	$4, 4($1)
	lw	$5, 5($1)
	lw	$6, 6($1)
	lw	$7, 7($1)
	lw	$8, 8($1)
	lw	$9, 9($1)
	lw	$10, 10($1)
	lw	$11, 11($1)
	lw	$12, 12($1)
	lw	$13, 13($1)
	lw	$sp, 14($1)
	lw	$ra, 15($1)
	lw	$1, regsave+1($0)
	
	# And start the program
	j	start_vector
.bss
start_vector:
	.word
	
tmp:	.word
	
.text
.global command_flash
command_flash:
	jal	unlock_rom
	
	la	$3, 0x0
	la	$4, flash_code
	la	$5, flash_end
command_flash_loop:
	lw	$1, 0($4)
	sw	$1, 0($3)

	seq	$1, $4, $5
	bnez	$1, begin_flash
	
	addui	$3, $3, 1
	addui	$4, $4, 1
	j	command_flash_loop

begin_flash:	
	jr	$0
	

flash_code:
	# Setup the serial port for 38400bps, N81
	addui	$1, $0, 0x00c7
	sw	$1, 0x70002($0)

flash_start:
	# Setup the stack pointer
	la	$sp, 0x1ffff
	
read_char_1:
	lw	$1, 0x70003($zero)
	andi	$1, $1, 0x1
	beqz	$1, read_char_1

	lw	$1, 0x70001($zero)

	andi	$1, $1, 0xff

	seqi	$1, $1, 'P'
	beqz	$1, flash_start

read_char_2:
	lw	$1, 0x70003($zero)
	andi	$1, $1, 0x1
	beqz	$1, read_char_2

	lw	$1, 0x70001($zero)

	andi	$1, $1, 0xff

	slli	$2, $1, 8
read_char_3:
	lw	$1, 0x70003($zero)
	andi	$1, $1, 0x1
	beqz	$1, read_char_3

	lw	$1, 0x70001($zero)

	andi	$1, $1, 0xff

	or	$2, $2, $1
	slli	$2, $2, 8
	# Now the sector address is in $2

	# Now we read the data
	addu	$3, $0, $0	# Clear a loop counter
	addu	$5, $0, $0	# And a checksum counter
flash_loop:
read_char_4:
	lw	$1, 0x70003($zero)
	andi	$1, $1, 0x1
	beqz	$1, read_char_4

	lw	$1, 0x70001($zero)

	andi	$1, $1, 0xff

	addu	$5, $5, $1
	addu	$4, $1, $0
	slli	$4, $4, 8
read_char_5:
	lw	$1, 0x70003($zero)
	andi	$1, $1, 0x1
	beqz	$1, read_char_5

	lw	$1, 0x70001($zero)

	andi	$1, $1, 0xff

	addu	$5, $5, $1
	or	$4, $4, $1
	slli	$4, $4, 8
read_char_6:
	lw	$1, 0x70003($zero)
	andi	$1, $1, 0x1
	beqz	$1, read_char_6

	lw	$1, 0x70001($zero)

	andi	$1, $1, 0xff

	addu	$5, $5, $1
	or	$4, $4, $1
	slli	$4, $4, 8
read_char_7:
	lw	$1, 0x70003($zero)
	andi	$1, $1, 0x1
	beqz	$1, read_char_7

	lw	$1, 0x70001($zero)

	andi	$1, $1, 0xff

	addu	$5, $5, $1
	or	$4, $4, $1

	# Save this word into our buffer
	sw	$4, 0x10000($3)
	# Increment the loop counter
	addui	$3, $3, 1

	seqi	$1, $3, 256
	beqz	$1, flash_loop

	srli	$1, $2, 16
	sw	$1, 0($sp)
send_char_1:
	lw	$1, 0x70003($0)		# Get LSR
	andi	$1, $1, 0x2		# Look at TDS bit
	beqz	$1, send_char_1		# Wait for previous character to be sent

	lw	$1, 0($sp)		# Get the character
	sw	$1, 0x70000($0)		# Send the character

	srli	$1, $2, 8
	andi	$1, $1, 0xff
	sw	$1, 0($sp)
send_char_2:
	lw	$1, 0x70003($0)		# Get LSR
	andi	$1, $1, 0x2		# Look at TDS bit
	beqz	$1, send_char_2		# Wait for previous character to be sent

	lw	$1, 0($sp)		# Get the character
	sw	$1, 0x70000($0)		# Send the character


	andi	$1, $5, 0xff
	sw	$1, 0($sp)
send_char_3:
	lw	$1, 0x70003($0)		# Get LSR
	andi	$1, $1, 0x2		# Look at TDS bit
	beqz	$1, send_char_3		# Wait for previous character to be sent

	lw	$1, 0($sp)		# Get the character
	sw	$1, 0x70000($0)		# Send the character


read_char_8:
	lw	$1, 0x70003($zero)
	andi	$1, $1, 0x1
	beqz	$1, read_char_8

	lw	$1, 0x70001($zero)

	andi	$1, $1, 0xff

	seqi	$1, $1, 'Y'
	beqz	$1, flash_start

	# Go ahead and program a sector
	la	$5, 0x80000
	addu	$5, $5, $2
	
	addu	$3, $0, $0
flash_prog_loop:
	lw	$1, 0x10000($3)
	addu	$6, $5, $3
	sw	$1, 0($6)

	addui	$3, $3, 1

	seqi	$1, $3, 256
	beqz	$1, flash_prog_loop

	# Done so...
	addui	$1, $0, 'D'
	sw	$1, 0($sp)
send_char_4:
	lw	$1, 0x70003($0)		# Get LSR
	andi	$1, $1, 0x2		# Look at TDS bit
	beqz	$1, send_char_4		# Wait for previous character to be sent

	lw	$1, 0($sp)		# Get the character
	sw	$1, 0x70000($0)		# Send the character

flash_end:
	beqz	$0, flash_start
	