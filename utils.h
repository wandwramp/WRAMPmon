#ifndef UTILS_H
#define UTILS_H

void exit_user_prog();

void command_flash();

void start_program(unsigned int start_address);
void program_init();

void lock_rom();
void unlock_rom();
void save_serial();
void restore_serial();
void init_serial();

#endif
