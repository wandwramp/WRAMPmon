########################################################################
# This file is part of WRAMPmon, the WRAMP monitor programe.
#
# Copyright (C) 2019 The University of Waikato, Hamilton, New Zealand.
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
########################################################################
.bss
end_ptr:	.word
old_char:	.word
.text
	
# void tokenise(char *str)
# Setup to extract tokens from the specified string
.global tokenise
tokenise:
	# Get the parameter
	lw	$1, 0($sp)
	
	sw	$1, end_ptr($0)
	
	sw	$0, old_char($0)
	jr	$ra


# char *get_token()
# Get the next token from a string
.global get_token
get_token:
	subui	$sp, $sp, 8
	sw	$4, 4($sp)
	sw	$5, 5($sp)
	sw	$6, 6($sp)
	sw	$ra, 7($sp)

	lw	$4, end_ptr($0)
	lw	$5, old_char($0)

	beqz	$5, get_token_first_token

	# Restore the character we replaced
	sw	$5, 0($4)
get_token_first_token:	

	# Skip over whitespace to find the start of the next token
	lw	$1, 0($4)
	# Check for end of string
	beqz	$1, get_token_return	# No more tokens

	# Is this character whitespace?
	sw	$1, 0($sp)
	jal	isspace
	beqz	$1, get_token_found_start

	addui	$4, $4, 1
	j	get_token_first_token

get_token_found_start:
	# $4 contains the start of our token
	lw	$1, 0($4)
	beqz	$1, get_token_return	# No more tokens

	# Find the end of the token
	addui	$5, $4, 1
get_token_find_end:

	lw	$1, 0($5)
	sw	$1, old_char($0)
	# Check for end of string
	beqz	$1, get_token_last_token
	sw	$1, 0($sp)
	jal	isspace
	bnez	$1, get_token_found_end

	addui	$5, $5, 1
	j	get_token_find_end
	
get_token_found_end:	
	lw	$1, 0($5)
	sw	$1, old_char($0)
	# Put a null character in here
	sw	$0, 0($5)

get_token_last_token:
	# Setup the return value
	addu	$1, $4, $0
	sw	$5, end_ptr($0)
	
get_token_return:
	
	lw	$4, 4($sp)
	lw	$5, 5($sp)
	lw	$6, 6($sp)
	lw	$ra, 7($sp)
	addui	$sp, $sp, 8

	jr	$ra