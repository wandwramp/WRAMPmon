/*
########################################################################
# This file is part of WRAMPmon, the WRAMP monitor programe.
#
# Copyright (C) 2015-2019 The University of Waikato, Hamilton, New Zealand.
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
#      Original code:    Paul Monigatti, April 2015
########################################################################
*/

#include "wramp.h"

/**
 * Macros
 **/
#define MIN(a,b) (((a)<(b))?(a):(b))
#define MAX(a,b) (((a)>(b))?(a):(b))

/**
 * ASCII Escape Sequences
 **/
#define ASCII_ESC			"\\033["
#define SCREEN_CLEAR 		ASCII_ESC "2J"
#define SCREEN_GO_HOME 		ASCII_ESC "H"
#define SCREEN_CURSOR_OFF	ASCII_ESC "?25l"

#define WIDTH	80
#define HEIGHT	25

/**
 * Game State
 **/
signed int PaddleWidth;
signed int PaddleMid;
signed int BallX;
signed int BallY;
signed int BallDx;
signed int BallDy;
signed int GameInProgress;
signed int Score;
signed int DelayVal;
signed int Running;

/**
 * Writes a character to a serial port.
 * Note: this function blocks.
 *
 * Parameters:
 *  c		The character to send
 *  
 **/
void putc(char c)
{
	//TODO: don't use hard-coded SP1
	while(!(WrampSp1->Stat & 2));
	WrampSp1->Tx = c;
}

/**
 * Writes a string to a serial port.
 * Note: this function blocks.
 *
 * Parameters:
 *  s		A pointer to the string to send
 *
 **/
void puts(const char *s)
{
	//TODO: don't use a hard-coded SP1
	while(*s != 0)
	{
		putc(*s++);
	}
}

void putn(int n)
{
	int digits = 1000000000; //max number of digit places
	int doingIt = 0;
	int working;
	
	while(digits)
	{
		working = n / digits;
		working %= 10;
		if(doingIt || working != 0)
		{
			doingIt = 1;
			putc(working + '0');
		}
		digits /= 10;
	}
	
	if(!doingIt)
		putc('0');
}

void ClearDisplay()
{	
	puts(SCREEN_CLEAR);
	puts(SCREEN_GO_HOME);
}

/**
 * Sets the cursor position to x,y.
 *
 * Parameters:
 *  x		The X-coordinate to set
 *  y		The Y-coordinate to set
 **/
void GotoXY(int x, int y)
{
	if(1 || 0 <= x && x < WIDTH && 0 <= y && y < HEIGHT)
	{
        x += 1;
        y += 1;
        
		puts(ASCII_ESC);
		x %= 100;
		y %= 100;
		putc(y / 10 + '0');
		putc(y % 10 + '0');
		putc(';');
		putc(x / 10 + '0');
		putc(x % 10 + '0');
		putc('H');
	}
}

void InitDisplay()
{
	ClearDisplay();
	puts(SCREEN_CURSOR_OFF);
}

static void NewGame()
{
	if(!GameInProgress)
	{
		InitDisplay();
		PaddleWidth = 9;
		PaddleMid = WIDTH / 2;
		BallX = WIDTH / 2;
		BallY = HEIGHT / 2;
		BallDx = 1;
		BallDy = -1;
		Score = 0;
		DelayVal = 0x2fff;
		GameInProgress = 1;
	}
}

static void Delay()
{
	unsigned int i;
	for(i = 0; i < DelayVal; i++) { }
}

static void GameTick()
{
	char charRecv = 0;
	int i;
	
	//next gamestate
	int paddleWidth = PaddleWidth;
	int paddleDx = 0;
	int start, end, oldStart, oldEnd, newStart, newEnd;
	
	//Check serial input
	if(WrampSp1->Stat & WRAMP_SP_RDR)
	{
		charRecv = WrampSp1->Rx;
	}
	
	switch(charRecv)
	{
		case 'a':
			paddleDx -= 2;
			break;
		
		case 'd':
			paddleDx += 2;
			break;
		
		case '\r':
			NewGame();
			break;
			
		case 'q':
			Running = 0;
			return;
	}
	
	//Calculate score, and make the game harder if necessary
	if(GameInProgress)
		Score++;
	
	GotoXY(0, 0);
	puts("Score: ");
	putn(Score);
	
	
	//calculate old paddle position
	oldStart = PaddleMid - PaddleWidth/2;
	oldEnd = oldStart + PaddleWidth;
	
	//Make the game harder as score increases
	if(Score > 400)
	{
		PaddleWidth = 5;
		DelayVal = 0x07ff;
	}
	else if(Score > 300)
	{
		PaddleWidth = 5;
		DelayVal = 0x0fff;
	}
	else if(Score > 200)
	{
		PaddleWidth = 7;
		DelayVal = 0x1fff;
	}
	
	//update position and apply limits
	PaddleMid += paddleDx;
	PaddleMid = MAX(PaddleWidth/2, PaddleMid);
	PaddleMid = MIN(PaddleMid, WIDTH - PaddleWidth/2);
	
	newStart = PaddleMid - PaddleWidth/2;
	newEnd = newStart + PaddleWidth;
	
	start = MIN(oldStart, newStart);
	end = MAX(oldEnd, newEnd);
	
	//draw ball
	GotoXY(BallX, BallY);
	putc(' ');
	
	//Update position
	BallX += BallDx;
	BallY += BallDy;
			
	if(BallX <= 0)
	{
		BallX = 0;
		BallDx = 1;
	}
	else if(BallX >= WIDTH)
	{
		BallX = WIDTH;
		BallDx = -1;
	}
	
	if(BallY <= 0)
	{
		BallY = 0;
		BallDy = 1;
	}
	else if(BallY >= HEIGHT - 1)
	{		
		//Bounce, or die?
		if(oldStart <= BallX && BallX < oldEnd)
		{
			//BallY *= -1;
			BallDy = -1;
		}
		else
		{
			BallDx = 0;
			BallDy = 0;
			GotoXY(WIDTH / 2 - 10, HEIGHT/2);
			puts("Whoops! You're dead.");
			GotoXY(WIDTH / 2 - 12, HEIGHT/2 + 1);
			puts("Press Space To Play Again");
			GotoXY(WIDTH / 2 - 6, HEIGHT/2 + 2);
			puts("Or <q> to Quit");
			GameInProgress = 0;
		}
	}
	
	GotoXY(BallX, BallY);
	putc('O');
	
	//Redraw paddle
	GotoXY(start, HEIGHT-1);
	for(i = start; i < end; i++)
	{
		if(newStart <= i && i < newEnd)
			putc('-');
		else
			putc(' ');
	}
}

void breakout_main()
{
	Running = 1; //this game is going
	
	//Initialise game state
	PaddleWidth = 9;
	PaddleMid = WIDTH / 2;
	BallX = WIDTH / 2;
	BallY = HEIGHT / 2;
	BallDx = 0;
	BallDy = 0;
	GameInProgress = 0;
	Score = 0;
	DelayVal = 0x2fff;
	Running = 1;
	
	//Setup and go!
	InitDisplay();
	GotoXY(WIDTH/2 - 10, HEIGHT/2+1);
	puts("Press <Enter> To Play");
	
	GotoXY(WIDTH/2 - 6, HEIGHT/2+2);
	puts("Or <q> to Quit");
	while(Running)
	{
		GameTick();
		Delay();
	}
}

