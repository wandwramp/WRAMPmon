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
/**
 * WRAMP Serial Ports
 **/
typedef volatile struct
{
	int Tx;
	int Rx;
	int Ctrl;
	int Stat;
	int Iack;
} WrampSp_t;

//TODO: bit flag defines
#define WRAMP_SP_RDR	0x0001


/**
 * WRAMP Timer
 **/
typedef volatile struct
{
	int Ctrl;
	int Load;
	int Count;
	int Iack;
} WrampTimer_t;
 
/**
 * WRAMP Parallel Port
 **/
typedef volatile struct
{
	int Switches;
	int Buttons;
	int LeftSSD;
	int RightSSD;
	int Ctrl;
	int Iack;
} WrampParallel_t;

 
/**
 * WRAMP User Interrupt Button
 **/
typedef volatile struct
{
	int Iack;
} WrampUserInt_t;


/**
 * Declarations
 **/
#define WrampSp1 		((WrampSp_t*)0x70000)
#define WrampSp2 		((WrampSp_t*)0x71000)
#define WrampTimer  	((WrampTimer_t*)0x72000)
#define WrampParallel	((WrampParallel_t*)0x73000)
#define WrampUserInt	((WrampUserInt_t*)0x7f000)
