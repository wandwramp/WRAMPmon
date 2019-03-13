/*
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
*/

#include "wramp.h"

//Which serial port should we use?
#define SERIAL_PORT WrampSp1

//ASCII escape sequences for controlling terminal behaviour
#define CLEAR_SCREEN	"\\033[2J"
#define GO_HOME			"\\033[H"

/**
 * Prints a character to the serial port. Note: blocks until SP is ready
 *
 * Parameters:
 *   c		The character to print.
 **/
static void putc(int c) {
	while(!(SERIAL_PORT->Stat & 2));
	SERIAL_PORT->Tx = c;
}

/**
 * Reads a character from the serial port.
 *
 * Returns:
 *   The character if available, otherwise -1.
 **/
static int getc() {
	if(!(SERIAL_PORT->Stat & 1))
		return -1;
	return SERIAL_PORT->Rx;
}

/**
 * Writes a null-terminated string to the serial port.
 *
 * Returns:
 *   The character, or -1 if not available
 **/
static void puts(char *str) {
	while(*str)
		putc(*str++);
}

/**
 * Prints the instructions for the two games to the serial port.
 **/
static void help() {
	puts(CLEAR_SCREEN);
	puts(GO_HOME);
	
	puts("#################################\r\n");
	puts("########## How to Play ##########\r\n");
	puts("#################################\r\n");
	puts("-- Rocks --\r\n");
	puts("Guide the spaceship through a minefield of space rocks.\r\n\r\n");
	puts("Controls:\r\n");
	puts("<space> Change direction\r\n");
	puts("<q>     Quit game\r\n");
	puts("\r\n");
	puts("-- Breakout --\r\n");
	puts("A cheap clone of the Atari game Breakout. Just stay alive as long as possible!\r\n\r\n");
	puts("Controls:\r\n");
	puts("<a>     Move paddle left.\r\n");
	puts("<d>     Move paddle right.\r\n");
	puts("<q>     Quit game\r\n\r\n");
	
	puts("Press <Enter> to continue...");
	while(getc() != '\r');
}

/**
 * Blocks until the user chooses a valid option.
 **/
static int chooseOption() {
	while(1) {
		switch(getc()) {
			case '1':
				rocks_main();
				return 1;
				
			case '2':
				breakout_main();
				return 1;
				
			case '3':
				help();
				return 1;
				
			case 'q':
				puts("Games Task Ended :(\r\n");
				return 0;
		}
	}
	return 0; //not possible, but keeps the compiler happy.
}

/**
 * Main
 **/
void gameSelect_main() {	
	while(1) {
		puts(CLEAR_SCREEN);
		puts(GO_HOME);
		puts("Select an Option:\r\n");
		puts("1: Play \"Rocks\"\r\n");
		puts("2: Play \"Breakout\"\r\n");
		puts("3: View Help\r\n");
		puts("\r\n");
		puts("q: Quit Task\r\n");
		
		//Choose a task to run, or exit.
		if(!chooseOption())
			return;
	}
}
