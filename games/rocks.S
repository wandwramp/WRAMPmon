########################################################################
# This file is part of WRAMPmon, the WRAMP monitor programe.
#
# Copyright (C) 2002-2019 The University of Waikato, Hamilton, New Zealand.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
# Acknowledgments:
#      Original MIPS code:      Jonathan Purvis
#      Original game concept:   Matthew Browne
#
# Modifications to use the WRAMP instruction set by Dean Armstrong and 
# Jamie Curtis, 2002
#
# $Id: game.s,v 1.9 2002/08/15 03:02:44 jpc2 Exp $
#######################################################################	

	.equ	port_base,	0x70000
	.equ	tx_offset,	0
	.equ	rx_offset,	1
	.equ	control_offset,	2
	.equ	status_offset,	3	

	.equ	num_rocks,	96
	.equ	wait_delay,     15000
.text

.global	rocks_main

rocks_main:
	subui	$sp, $sp, 7
	sw	$2, 2($sp)
	sw	$3, 3($sp)
	sw	$4, 4($sp)
	sw	$5, 5($sp)
	sw	$ra, 6($sp)
	
		
	la	$1, setup
	sw	$1, 0($sp)
	jal	print			# clear screen, home cursor, no cursor
	
initgame:
	la	$1, press_enter
	sw	$1, 0($sp)
	jal	print			# tell the user to press enter

check4quit:
	jal getkey			# Check for 'q' to quit the game
	seqi $2, $1, 'q'
	bnez $2, exit_game
	
wait4enter:
	#jal	getkey			# Check for enter to start a new game
	seqi	$2, $1, 13
	beqz	$2, check4quit	

	la	$1, setup
	sw	$1, 0($sp)
	jal	print			# clear screen, home cursor, no cursor
	
	jal	initrocks		# draw the rocks on screen
	
	addi	$2, $0, 1		# X co-ordinate
	addi	$3, $0, 12		# Y co-ordinate
	addi	$4, $0, 1		# direction

pause:	jal	wait			# pause after drawing rocks to
	jal	wait			#  allow the user to realise

gameloop:
	jal	wait			# wait a .25 of a second
	
	jal	getkey			# get a key if one has been pressed
	seqi	$1, $1, ' '		# Check to see if it was a space
	beqz	$1, L1
	
	sub	$4, $0, $4		# if space pressed, reverse direction
	j	checkYpos
	
L1:	
	add	$3, $3, $4		# update Y pos
	
checkYpos:
	sgti	$1, $3, 1
	bnez	$1, L2

	sub	$4, $0, $4		# we`re at the top of screen, go down
	j	L3
	
L2:	
	slti	$1, $3, 23
	bnez	$1, L3

	sub	$4, $0, $4		# we`re at the bottom of screen, go up
	
L3:	
	addi	$2, $2, 1		# increment X pos

	sw	$2, 0($sp)
	sw	$3, 1($sp)
	jal	setpos			# set the cursor position
	
	la	$1, down_char
	sw	$1, 0($sp)
	sgt	$1, $4, $0
	bnez	$1, L4

	la	$1, up_char
	sw	$1, 0($sp)
	
L4:	
	jal	print			# draw the approriate character
	
	
check_lose:
	sw	$2, 0($sp)
	sw	$3, 1($sp)
	jal	check4rock		# check to see if we hit a rock
	
	beqz	$1, check_win

	sw	$2, 0($sp)
	sw	$3, 1($sp)
	jal	setpos			# set the cursor position
	
	la	$1, crash_char
	sw	$1, 0($sp)
	jal	print			# if we hit, print a #
	

	la	$1, youlose
	sw	$1, 0($sp)
	jal	print			# tell the user they lost
	
	j	initgame		# start the game again
	

check_win:
	slti	$1, $2, 80
	bnez	$1, do_next		# if they haven`t won yet
	
	la	$1, youwin
	sw	$1, 0($sp)
	jal	print			# tell the user they won
	
	j	initgame		# start the game again
	

do_next:	
	j	gameloop		# next move


	# Redundant (return from game subroutine)
exit_game:	
	lw	$2, 2($sp)
	lw	$3, 3($sp)
	lw	$4, 4($sp)
	lw	$5, 5($sp)
	lw	$ra, 6($sp)
	addui	$sp, $sp, 7
	jr	$ra
	
#######################################################################

initrocks:
	subui	$sp, $sp, 7		# 2 args, 5 reg save
	sw	$5, 2($sp)
	sw	$6, 3($sp)
	sw	$7, 4($sp)
	sw	$8, 5($sp)
	sw	$ra, 6($sp)		# store return address on stack

	la	$5, rocks		# array of rock positions
	la	$6, num_rocks		# count of rocks
newrock:
	addi	$1, $0, 75
	sw	$1, 0($sp)
	jal	random			# get random number between 0 and 74
	
	addi	$7, $1, 6		# X co-ord 6-80

	addi	$1, $0, 25
	sw	$1, 0($sp)
	jal	random			# get random number between 0 and 24
	
	addi	$8, $1, 1		# Y co-ord 1-25
	
	sw	$7, 0($5)		# store the position of this rock
	sw	$8, 1($5)

	sw	$7, 0($sp)		# put args onto stack
	sw	$8, 1($sp)
	jal	setpos			# call setpos to set the cursor postion
	
	la	$1, rock_char		# draw this rock
	sw	$1, 0($sp)		# put the string arg on the stack
	jal	print			# call print to display the string
	
	addi	$5, $5, 2		# update array pointer
	subi	$6, $6, 1		# decrement counter
	bnez	$6, newrock		# draw next rock (if there is one)
	
	lw	$5, 2($sp)		# restore registers
	lw	$6, 3($sp)
	lw	$7, 4($sp)
	lw	$8, 5($sp)
	lw	$ra, 6($sp)		# get return address from stack
	addui	$sp, $sp, 7
	
	jr	$ra
	
#######################################################################

check4rock:
	subui	$sp, $sp, 6		# 6 reg save
	sw	$3, 0($sp)		# save the registers
	sw	$4, 1($sp)
	sw	$5, 2($sp)
	sw	$6, 3($sp)
	sw	$7, 4($sp)
	sw	$8, 5($sp)
	
	lw	$3, 6($sp)		# get the args we were called with
	lw	$4, 7($sp)
	
	la	$5, rocks		# array of rock positions
	la	$6, num_rocks		# count of rocks
	addi	$1, $0, 0		# return 0 if not found

checkrock:
	lw	$7, 0($5)		# load the position of rock to check
	lw	$8, 1($5)

	sne	$7, $7, $3
	bnez	$7, not_this_rock

	sne	$8, $8, $4
	bnez	$8, not_this_rock
	
	addi	$1, $0, 1		# if it is, return a 1
	j	check4rock_done		# and don`t check any more
	

not_this_rock:
	addi	$5, $5, 2		# update array pointer
	subi	$6, $6, 1		# decrement counter
	bnez	$6, checkrock		# check next rock
	
	add	$1, $0, $0		# return 0, we didn't hit a rock
	
	
check4rock_done:
	lw	$3, 0($sp)		# restore registers
	lw	$4, 1($sp)
	lw	$5, 2($sp)
	lw	$6, 3($sp)
	lw	$7, 4($sp)
	lw	$8, 5($sp)
	addi	$sp, $sp, 6
	jr	$ra
	
#######################################################################

wait:	
	la	$1, wait_delay
waitloop:
	subi	$1, $1, 1
	bnez	$1, waitloop

	jr	$ra

#######################################################################
getkey:
	subui	$sp, $sp, 1
	sw	$2, 0($sp)

	add	$1, $0, $0		# return 0 for no key pressed
	la	$2, port_base
	lw	$2, status_offset($2)

	andi	$2, $2, 0x1		# has a key been pressed?
	beqz	$2, no_key

	la	$2, port_base
	lw	$1, rx_offset($2)	# if so, get it
	

no_key:
	lw	$2, 0($sp)
	addui	$sp, $sp, 1
	jr	$ra
	
#######################################################################

setpos:
	subui	$sp, $sp, 5
	sw	$2, 1($sp)
	sw	$3, 2($sp)
	sw	$4, 3($sp)
	sw	$ra, 4($sp)		# store return address on stack

	lw	$3, 5($sp)
	lw	$4, 6($sp)
		
	la	$2, pos
	
	remi	$1, $3, 10		# get 1s digit of X pos
	addi	$1, $1, '0'
	sw	$1, 6($2)	

	divi	$1, $3, 10		# get 10s digit of X pos
	addi	$1, $1, '0'
	sw	$1, 5($2)	

	remi	$1, $4, 10		# get 1s digit of Y pos
	addi	$1, $1, '0'
	sw	$1, 3($2)	

	divi	$1, $4, 10		# get 10s digit of Y pos
	addi	$1, $1, '0'
	sw	$1, 2($2)	
	

	sw	$2, 0($sp)
	jal	print			# print escape sequence
	

	lw	$2, 1($sp)
	lw	$3, 2($sp)
	lw	$4, 3($sp)
	lw	$ra, 4($sp)		# get return address from stack
	addui	$sp, $sp, 5
	
	jr	$ra
	
#######################################################################
		
print:	subui	$sp, $sp, 3
	sw	$2, 0($sp)
	sw	$3, 1($sp)
	sw	$4, 2($sp)
	
	lw	$2, 3($sp)		# the pointer to the string
	la	$3, port_base
	
p_wait:	
	lw	$4, status_offset($3)	# read the status from the port
					# indicated by base
	andi	$4, $4, 0x2		# mask off bit 0, tdr
	beqz	$4, p_wait
	
	lw	$4, 0($2)		# get the next character in the string
	beqz	$4, print_done		# loop if end of message
	
	sw	$4, tx_offset($3)	# send the character to the console box
	addi	$2, $2, 1		# increment the pointer
	j	p_wait			# print next character
	

print_done:
	lw	$2, 0($sp)
	lw	$3, 1($sp)
	lw	$4, 2($sp)
	addui	$sp, $sp, 3
	jr	$ra
	
#######################################################################

random:
	subui	$sp, $sp, 4
	sw	$2, 0($sp)
	sw	$3, 1($sp)
	sw	$4, 2($sp)
	sw	$5, 3($sp)
	
	# if next == 0 then seed
	lw	$2, next($0)
	bnez	$2, pick_next

	# fetch a random seed from the CPU cycle count (a special
	# purpose register)
	movsg	$2, $ccount

	# Limit the seed to a (positive) 16 bit value
	andi	$2, $2, 0xffff
	
pick_next:
	# The random number is picked using the following formula	
	# next = A * (next % q) - r * (next / q)
	
	lw	$3, q($0)

	rem	$4, $2, $3
	div	$5, $2, $3
	lw	$2, r($0)
	mult	$5, $5, $2		# $5 = r * (next / q)
	
	lw	$2, A($0)
	mult	$4, $4, $2		# $4 = A * (next % q)
	
	sub	$4, $4, $5

	slt	$1, $4, $0
	beqz	$1, rand_return
	
	lw	$2, M($0)
	add	$4, $4, $2
	
rand_return:
	sw	$4, next($0)
		
	lw	$2, 4($sp)		# get our argument (the max number)
	rem	$1, $4, $2		# limit the number to the range we want

	lw	$2, 0($sp)
	lw	$3, 1($sp)
	lw	$4, 2($sp)
	lw	$5, 3($sp)
	
	addui	$sp, $sp, 4
	jr	$ra

#######################################################################	

.data
	
# These values control the random number creation and are
# *very* special. Do not change them !
	
next:	.word	0
A:	.word	16807
M:	.word	2147483647
q:	.word	127773
r:	.word	2836

# These are the various strings used to talk to the terminal

setup:
	.asciiz	"\033[2J\033[H\033[?25l"
press_enter:
	.asciiz	"\007\033[13;28H Press <Enter> to play \007\033[14;32H Or <q> to quit "
pos:
	.asciiz	"\033[xx;xxH"
up_char:
	.asciiz	"/"
down_char:
	.asciiz	"\\"
rock_char:
	.asciiz	"*"
crash_char:
	.asciiz	"#"
youlose:
	.asciiz	"\007\033[12;35H You lose "
youwin:
	.asciiz	"\007\033[12;35H You win "
	
#######################################################################	

.bss

rocks:
	.space	192                     # reserve space for the rocks 
					# (2 * num_rocks)