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




