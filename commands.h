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
void command_jtag();

void command_sws_debug();
void command_games();

void on_reset();
void setup_breakpoints();

#endif
