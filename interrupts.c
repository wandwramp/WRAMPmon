#include "commands.h"
#include "utils.h"

extern breakpoint brk_point[MAX_BREAKPOINTS];

void handle_interrupt(unsigned int estat, unsigned int cctrl, unsigned int ear)
{
  int i;
  
  save_serial();

  if (estat & 0x4000) { // break exception
    // If we just did a single step
    if (step_mode == true && step_break_addr == (ear - 1)) {
      // Backup so that when we restart we execute this instruction
      program_counter--;

      if (step_break_mode == true) {
	// Replace the breakpoint instruction
	*(unsigned int *)cont_addr = BREAK_INSN;
      }
      
      // Replace the old instruction
      *(unsigned int *)step_break_addr = step_old_insn;
      step_mode = false;

      if (cont_mode == true) {
	cont_mode = false;
	*(unsigned int *)cont_addr = BREAK_INSN;
	enable_ints();
	start_program(program_counter);
	return; // redundant
      }
      
      // Display the instruction we have just executed
      printf("EXECUTED:  ");
      printf("0x%05x ", step_insn_addr);
      if (step_break_mode == true) {
	for (i = 0 ; i < MAX_BREAKPOINTS ; i++) {
	  if (brk_point[i].addr == step_insn_addr) {
	    printf("%08x", brk_point[i].insn);
	    printf(" !BRK! ");
	    disassemble(brk_point[i].addr, brk_point[i].insn);
	    break;
	  }
	}
	if (i == MAX_BREAKPOINTS) {
	  printf("%08x", *(unsigned int *)step_insn_addr);
	  printf("       ");
	  disassemble(step_insn_addr, cont_insn);
	}
      }
      else {
	printf("%08x", *(unsigned int *)step_insn_addr);
	printf("       ");
	disassemble(step_insn_addr, *(unsigned int *)step_insn_addr);
      }
      printf("\n");

      printf("NEXT INSN: ");
      i = 0;
      if (*(unsigned int *)program_counter == BREAK_INSN) {
	for (i = 0 ; i < MAX_BREAKPOINTS ; i++) {
	  if (brk_point[i].addr == program_counter) {
	    printf("0x%05x %08x", brk_point[i].addr, brk_point[i].insn);
	    printf(" !BRK! ");
	    disassemble(brk_point[i].addr, brk_point[i].insn);
	    printf("\n");
	    break;
	  }
	}
      }
      if (*(unsigned int *)program_counter != BREAK_INSN || i == MAX_BREAKPOINTS) {
	printf("0x%05x %08x       ", program_counter, *(unsigned int *)program_counter);
	disassemble(program_counter, *(unsigned int *)program_counter);
	printf("\n");
      }

      
      step_break_mode = false;
      // Return and reenter the monitor
      return;
    }
    
    // This exception has been caused by a break instruction
    // We should check to see if it is one of our breakpoints
    for (i = 0 ; i < MAX_BREAKPOINTS ; i++) {
      if (brk_point[i].addr == (ear - 1)) {
	program_counter--;
	// Yep, this is one of ours.
	printf("BREAKPOINT: ");
	printf("0x%05x %08x", brk_point[i].addr, brk_point[i].insn);
	printf(" !BRK! ");
	disassemble(brk_point[i].addr, brk_point[i].insn);
	printf("\n");
	dump_regs();
	return;
      }
    } 
  }
  if (estat & 0x2000) { // syscall exception
    //    printf("Program completed.\n");
    program_counter = program_start_addr;
    return;
  }
  if (estat & 0x1000) { // gpf
    printf("\nGPF: $ear = 0x%08x  $estat = 0x%08x  $cctrl = 0x%08x\n", ear, estat, cctrl);
    dump_regs();
    return;
  }
  if (estat & 0x8000) { // arithmetic
    printf("\nARITHMETIC: $ear = 0x%08x  $estat = 0x%08x  $cctrl = 0x%08x\n", ear, estat, cctrl);    
    dump_regs();
    return;
  }
  
  if (estat & 0x4000) { // unexpected breakpoint
    printf("\nBREAK: $ear = 0x%08x  $estat = 0x%08x  $cctrl = 0x%08x\n", ear, estat, cctrl);    
    dump_regs();
    return;
  }

  // Here we should really restore the serial port settings
  printf("\nINTERRUPT: $ear = 0x%08x  $estat = 0x%08x  $cctrl = 0x%08x\n", ear, estat, cctrl);
  dump_regs();
}
