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
#ifndef COMMANDS_H
#define COMMANDS_H

#define BREAK_INSN 0x200c0000
#define MAX_BREAKPOINTS 10

typedef struct {
  unsigned int addr;
  unsigned int insn;
} breakpoint;

typedef enum { false = 0, true = 1 } boolean;

extern unsigned step_old_insn, step_insn_addr, step_break_addr, cont_insn, cont_addr, program_counter, program_start_addr;

extern boolean step_mode, cont_mode, step_break_mode;

void command_vm();
void command_sm();
void command_about();
void command_help();
void command_dis();
void command_vr();
void command_sr();
void command_go();
void command_vb();
void command_sb();
void command_rb();
void command_load();
void command_s();
void command_so();
void command_cont();
void command_cls();

void command_sws_debug();
void command_games();

void on_reset();
void setup_breakpoints();

#endif
