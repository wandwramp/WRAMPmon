# This file contains the following IO routines for the teaching computer

# char read_char()
# Read a character from the serial port, returning it in $1
.global	read_char
read_char:
	lw	$1, 0x70003($zero)
	andi	$1, $1, 0x1
	beqz	$1, read_char

	lw	$1, 0x70001($zero)

	andi	$1, $1, 0xff

	jr	$ra

# void send_char(char ch)
# contains a character to be sent on the main serial port
.global	send_char
send_char:
	lw	$1, 0x70003($0)		# Get LSR
	andi	$1, $1, 0x2		# Look at TDS bit
	beqz	$1, send_char		# Wait for previous character to be sent

	lw	$1, 0($sp)		# Get the character
	sw	$1, 0x70000($0)		# Send the character
	
	jr	$ra




