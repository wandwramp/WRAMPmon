#include "token.h"
#include "clib.h"
#include "flih.h"
#include "utils.h"
#include "instructions.h"
#include "commands.h"

#include "micro.h"

boolean step_mode, cont_mode, step_break_mode;

unsigned int step_break_addr, step_old_insn, step_insn_addr, cont_insn, cont_addr;

unsigned int viewmem_start, dis_start, program_counter, program_start_addr;
unsigned int regsave[16];

breakpoint brk_point[MAX_BREAKPOINTS];

void on_load()
{
  setup_breakpoints();
  step_mode = false;
  cont_mode = false;
  step_break_mode = false;
}

void on_reset()
{
  viewmem_start = dis_start = program_counter = program_start_addr = 0;
  on_load();
}

int in_rom(unsigned int addr) { return (addr >= 0x80000); }

char makeprintable(char ch)
{
  if (isprint(ch))
    return ch;

  return '.';
}

void command_sws_debug()
{
  unsigned int *ptr = (unsigned int *)0x73000;
  unsigned int val;

  for (;;) {
    val = *ptr;
    *(ptr + 3) = val;
    *(ptr + 2) = val >> 4;
  }
}

void command_vm()
{
  char *token;
  unsigned int *ptr;
#define viewmem_length 40
  unsigned int viewmem_end = viewmem_start + viewmem_length - 1;

  // Get the first token
  token = get_token();
  if (token) {
    if (strcmp(token, "?") == 0) {
      printf("NAME:      view memory\n" \
	     "USAGE:     vm [start_address [end_address]]\n" \
	     "DESCR:     View the contents of a series of memory locations. When invoked\n" \
	     "           with no options, vm will display 40 words of memory, continuing\n" \
	     "           from after the last displayed memory location. Either the start\n" \
	     "           address or both the start and end addresses can be specified.\n\n" \
	     "EXAMPLES:  vm                   - display from last viewed address.\n" \
	     "           vm 0x00030           - display 40 words starting from\n" \
	     "                                  address 0x00030.\n" \
	     "           vm 0x00024 0x0002b   - display the contents of memory locations\n" \
	     "                                  0x00024 through 0x0002b.\n\n" \
	     "NOTES:     The contents of memory can be set using the sm command.\n" \
	     "           The contents of CPU registers can be viewed using the vr command.\n" \
	     "           The contents of memory can be disassembled using the dis command.\n");
      return;
    }

    // Convert it to a number
    atob(token, &viewmem_start, 10);
    viewmem_start &= 0xfffff;
    viewmem_end = viewmem_start + viewmem_length - 1;

    // Get the second token
    token = get_token();
    if (token) {
      // Convert it to a number
      atob(token, &viewmem_end, 10);
    }
  }


  if (viewmem_end < viewmem_start)
    viewmem_end = viewmem_start + viewmem_length - 1;

  viewmem_end &= 0xfffff;

  for (ptr = (unsigned int *)viewmem_start ; (unsigned int)ptr <= viewmem_end ; ptr += 4) {
    printf("0x%05x\t%08x %08x %08x %08x\t%c%c%c%c\n", (unsigned int)ptr, *ptr, *(ptr + 1), *(ptr + 2), *(ptr + 3),
	   makeprintable(*ptr), makeprintable(*(ptr + 1)), makeprintable(*(ptr + 2)), makeprintable(*(ptr + 3)));
  }
      
  viewmem_start = (unsigned int)ptr;
}

void command_sm()
{
  char *token;
  unsigned int *ptr;
  unsigned int value;
  
  // Get the first token (the address)
  token = get_token();
  if (token) {
    if (strcmp(token, "?") != 0) {
      // Convert it to a number
      atob(token, (unsigned int *)&ptr, 10);
      
      // Get the second token (the value to change it to)
      token = get_token();
      if (token) {
	// Convert it to a number
	atob(token, &value, 10);
	
	if (in_rom((unsigned int)ptr)) {
	  printf("ERROR: Cannot change that memory.\n");
	  return;
	}
	
	*ptr = value;
	return;
      }
    }
  }
  printf("NAME:      set memory\n" \
	 "USAGE:     sm <address> <value>\n" \
	 "DESCR:     Set the contents of a memory location. You must specify an\n" \
	 "           address and a value to change the contents of that address to.\n" \
	 "           The value can specified in decimal, hexadecimal or octal.\n\n" \
	 "EXAMPLES:  sm 0x00013 56        - set the contents of memory location\n" \
	 "                                  0x00013 to decimal 56.\n" \
	 "           sm 0x00045 0xf0f0    - set the contents of memory location\n" \
	 "                                  0x00045 to hexadecimal 0xf0f0.\n\n" \
	 "NOTES:     The contents of memory can be viewed using the vm command.\n" \
	 "           The contents of CPU registers can be set using the sr command.\n");
}

void command_about()
{
  printf("WRAMPmon!!\n" \
	 "Written by Dean Armstrong at the University of Waikato.\n" \
	 "$Id: commands.c,v 1.3 2003/03/25 00:12:22 daa1 Exp $\n" \
	 "Type '?' and press enter for help on commands.\n");
}

void command_help()
{
  printf("Available commands:\n" \
	 " load                               Load an S-Record into RAM\n" \
	 " go [address]                       Begin executing a program\n" \
	 " dis [start_address [end_address]]  Disassemble instructions from memory\n" \
	 " vm [start_address [end_address]]   View memory contents\n" \
	 " sm <address> <value>               Set the value of a memory location\n" \
	 " vr [reg]                           View register contents\n" \
	 " sr <reg> <value>                   Set register contents\n" \
	 " sb <address>                       Set a breakpoint\n" \
	 " vb                                 View current breakpoints\n" \
	 " rb <address>                       Remove a breakpoint\n" \
	 " cont                               Continue executing a program\n" \
	 " s                                  Step\n" \
	 " so                                 Step over\n" \
	 " about                              Display information about this system\n" \
	 " help or ?                          Display this information\n\n" \
	 "More information about indivdual commands can be obtained by entering\n" \
	 "the command name and then a question mark. eg. vm ?\n");
}

void command_dis()
{
  int i;
  char *token;
  unsigned int *ptr;

#define dis_length 16

  unsigned int dis_end = dis_start + dis_length - 1;

  // Get the first token
  token = get_token();
  if (token) {
    if (strcmp(token, "?") == 0) {
      printf("NAME:      disassemble\n" \
	     "USAGE:     dis [start_address [end_address]]\n" \
	     "DESCR:     Translate the contents of memory locations from machine code\n" \
	     "           back to WRAMP assembler. When invoked with no options, dis will\n" \
	     "           disassemble 16 instructions from the last disassembled location.\n" \
	     "           Either the start address or both the start and end addresses can\n" \
	     "           be specified.\n\n" \
	     "EXAMPLES:  dis                  - disassemble from the last viewed address.\n" \
	     "           dis 0                - disassemble 16 words starting from\n" \
	     "                                  address 0x00000.\n" \
	     "           dis 0x00024 0x0002b  - disassemble the contents of memory locations\n" \
	     "                                  0x00024 through 0x0002b.\n\n" \
	     "NOTES:     The raw contents of memory can be viewed using the vm command.\n");
      return;
    }

    // Convert it to a number
    atob(token, &dis_start, 10);
    dis_start &= 0xfffff;
    dis_end = dis_start + dis_length - 1;


    // Get the second token
    token = get_token();
    if (token) {
      // Convert it to a number
      atob(token, &dis_end, 10);
    }
  }

  if (dis_end < dis_start)
    dis_end = dis_start + dis_length - 1;

  dis_end &= 0xfffff;

  for (ptr = (unsigned int *)dis_start ; (unsigned int)ptr <= dis_end ; ptr++) {
    if (*ptr == BREAK_INSN) {
      for (i = 0 ; i < MAX_BREAKPOINTS ; i++) {
	if (brk_point[i].addr == (unsigned int)ptr) {
	  printf("0x%05x %08x", brk_point[i].addr, brk_point[i].insn);
	  printf(" !BRK! ");
	  disassemble(brk_point[i].addr, brk_point[i].insn);
	  printf("\n");
	  break;
	}
      }
    }
    if (*ptr != BREAK_INSN || i == MAX_BREAKPOINTS) {
      printf("0x%05x %08x", (unsigned int)ptr, *ptr);
      printf("       ");
      disassemble((unsigned int)ptr, *ptr);
      printf("\n");
    }
  }
      
  dis_start = (unsigned int)ptr;
}

void dump_regs()
{
  
  printf("REGISTERS: (Program Counter = 0x%05x)\n", program_counter);
  printf(" $0  = 0x%08x, $1  = 0x%08x, $2  = 0x%08x, $3  = 0x%08x\n", 0, regsave[1], regsave[2], regsave[3]);
  printf(" $4  = 0x%08x, $5  = 0x%08x, $6  = 0x%08x, $7  = 0x%08x\n", regsave[4], regsave[5], regsave[6], regsave[7]);
  printf(" $8  = 0x%08x, $9  = 0x%08x, $10 = 0x%08x, $11 = 0x%08x\n", regsave[8], regsave[9], regsave[10], regsave[11]);
  printf(" $12 = 0x%08x, $13 = 0x%08x, $sp = 0x%08x, $ra = 0x%08x\n", regsave[12], regsave[13], regsave[14], regsave[15]);
}

void command_vr()
{
  char *token;
  unsigned int reg_no;

  // Make sure $0 is always zero
  regsave[0] = 0;

  // Get the first token
  token = get_token();
  if (token) {
    if (strcmp(token, "?") == 0) {
      printf("NAME:      view registers\n" \
	     "USAGE:     vr [reg]\n" \
	     "DESCR:     View the contents of the CPU register file. When invoked\n" \
	     "           with no options, vr will display all 16 registers, and the address\n" \
	     "           of the next instruction to be executed in the user program.\n" \
	     "           Alternatively, a single register can be viewed by specifying it's\n" \
	     "           identifier.\n\n" \
	     "EXAMPLES:  vr                   - display the contents of all registers.\n" \
	     "           vr $1                - display the contents of CPU register $1.\n" \
	     "           vr $sp               - display the contents of the CPU stack pointer\n" \
	     "                                  register.\n\n" \
	     "NOTES:     The contents of memory can be viewed using the vm command.\n" \
	     "           The contents of CPU registers can be set using the sr command.\n");
      return;
    }    

    for (reg_no = 0 ; reg_no < 16 ; reg_no++)
      if (strcmp(token, GPR_name[reg_no]) == 0)
	break;
    
    if (reg_no == 16) {
      printf("ERROR: Bad register specified.\n");
      return;
    }

    printf(" %s = 0x%08x\n", GPR_name[reg_no], regsave[reg_no]);
  }
  else
    dump_regs();
}

void command_load()
{
  char *token;
  char line_buf[128];

  // Get the first token
  token = get_token();
  if (token)
    if (strcmp(token, "?") == 0) {
      printf("NAME:      load s-record\n" \
	     "USAGE:     load\n" \
	     "DESCR:     Place the monitor into upload mode so that an s-record program\n" \
	     "           can be loaded into RAM via the main serial port. Using remote,\n" \
	     "           files can be sent by typing '<ctrl>a' and then 's' and entering\n" \
	     "           the file name into the dialog box.\n\n" \
	     "NOTES:     Programs can be executed by using the go command.\n" \
	     "           Programs can be disassembled using the dis command.\n");
      return;
    }

  printf("Press '<ctrl>a' and then 's' in remote to upload a program...\n");

  // Get the record
  for (;;) {
    do {
      gets_noecho(line_buf);
      tokenise(line_buf);
      
      token = get_token();
    } while (!token);

    if (*token++ != 'S') {
      printf("\nERROR: Bad character in S-Record.\n");
      return;
    }
 
    if (*token == '3') {
      unsigned int len = 0, address = 0, i, j;
      token++;
      // Get the length of this record
      for (i = 0 ; i < 2 ; i++) {
	len <<= 4;
	len |= a_con_bin(*token++);
      }
      // Get the address
      for (i = 0 ; i < 8 ; i++) {
	address <<= 4;
	address |= a_con_bin(*token++);
      }
      
      // Remove the address and checksum from the length count
      len -= 5;
      // Divide the length by 4 bytes per word
      len >>= 2;

      for (i = 0 ; i < len ; i++) {
	unsigned int data = 0;

	// Get a word of data
	for (j = 0 ; j < 8 ; j++) {
	  data <<= 4;
	  data |= a_con_bin(*token++);
	}

	// Ensure we only write to RAM
	if (in_rom(address)) {
	  printf("\nERROR: S-Record attempted to load into ROM.\n");
	  return;
	}
	
	*((unsigned int *)address) = data;

	address++;	
      }
    }
    else if (*token == '7') {
      unsigned int start_address = 0, i;
      token++;
      // Skip past the length field
      token += 2;
      
      // Get the address
      for (i = 0 ; i < 8 ; i++) {
	start_address <<= 4;
	start_address |= a_con_bin(*token++);
      }

      program_start_addr = (program_counter = (viewmem_start = (dis_start = start_address)));

      program_init();
      on_load();
      // Acknowledge this line
      putchar('.');

      printf("\nProgram successfully loaded into memory.\n");
      return;
    }
    else if (*token != '0') {
      printf("\nERROR: Bad character in S-Record.\n");
      return;      
    }
    // Acknowledge this line
    putchar('.');
  }
}

void command_sr()
{
  char *token;
  unsigned int reg_no, value;
  
  // Get the first token (the address)
  token = get_token();
  if (token) {
    if (strcmp(token, "?") != 0) {

      for (reg_no = 0 ; reg_no < 16 ; reg_no++)
	if (strcmp(token, GPR_name[reg_no]) == 0)
	  break;
      
      if (reg_no == 16) {
	printf("ERROR: Bad register specified.\n");
	return;
      }
      if (reg_no == 0) {
	printf("ERROR: Cannot modify register $0.\n");
	return;
      }
      
      // Get the second token (the value to change it to)
      token = get_token();
      if (token) {
	// Convert it to a number
	atob(token, &value, 10);
	
	regsave[reg_no] = value;
	return;
      }
    }
  }
  printf("NAME:      set registers\n" \
	 "USAGE:     sr <reg> <value>\n" \
	 "DESCR:     Set the contents of a CPU general purpose register. You must\n" \
	 "           specify a register identifier and a value to change the contents of\n" \
	 "           that register to. The value can specified in decimal, hexadecimal\n" \
	 "           or octal.\n\n" \
	 "EXAMPLES:  sr $4 56             - set the contents of CPU register $4 to\n" \
	 "                                  decimal 56.\n" \
	 "           sr $2 0x1234         - set the contents of CPU register $2 to\n" \
	 "                                  hexadecimal 0x1234.\n\n" \
	 "NOTES:     The contents of memory can be set using the sm command.\n" \
	 "           The contents of CPU registers can be viewed using the vr command.\n");
}

void command_go()
{
  unsigned int addr;
  char *token;

  addr = program_start_addr;

  // Get the first token
  token = get_token();
  if (token) {
    if (strcmp(token, "?") == 0) {
      printf("NAME:      go\n" \
	     "USAGE:     go [start_address]\n" \
	     "DESCR:     Begin execution of a user program. When invoked with no options,\n" \
	     "           go will start executing a loaded program from the 'main' entry\n" \
	     "           point. Alternatively, an address to start execution from can be\n" \
	     "           specified.\n\n" \
	     "EXAMPLES:  go                   - start executing the last uploaded program.\n" \
	     "           go 0x00126           - start executing from address 0x00126.\n\n" \
	     "NOTES:     Programs can be loaded using the load command.\n" \
	     "           Programs can be disassembled using the dis command.\n");
      return;
    }

    // Convert it to a number
    atob(token, &addr, 10);
  }
  start_program(addr);
}

void setup_breakpoints()
{
  int i;
  for (i = 0 ; i < MAX_BREAKPOINTS ; i++)
    brk_point[i].addr = 0xffffffff;
}

// Set a breakpoint
void command_sb()
{
  int i;
  char *token;
  unsigned int addr;
  
  // Get the first token (the address)
  token = get_token();
  if (token) {
    if (strcmp(token, "?") != 0) {
      // Convert it to a number
      atob(token, &addr, 10);
      
      for (i = 0 ; i < MAX_BREAKPOINTS ; i++) {
	if (brk_point[i].addr == addr) {
	  printf("ERROR: Breakpoint already set at address 0x%05x.\n", addr);
	  return;
	}
	else if (brk_point[i].addr == 0xffffffff) {
	  if (in_rom(addr)) {
	    printf("ERROR: Cannot set breakpoint in ROM.\n");
	    return;
	  }
	  brk_point[i].addr = addr;
	  brk_point[i].insn = *((unsigned int *)addr);
	  *((unsigned int *)addr) = BREAK_INSN;
	  printf("Breakpoint set at address 0x%05x.\n", addr);
	  return;
	}
      }
      
      printf("ERROR: Maximum number of breakpoints (%d) are already set.\n", MAX_BREAKPOINTS);
      return;
    }
  }
  printf("NAME:      set breakpoint\n" \
	 "USAGE:     sb <address>\n" \
	 "DESCR:     Set a breakpoint before the instruction at the specified address.\n" \
	 "           Execution of the program will terminate, and control will be\n" \
	 "           returned to the monitor immediately before the specified\n" \
	 "           instruction is to be executed.\n\n" \
	 "EXAMPLES:  sb 0x00042           - set a breakpoint before the instruction\n" \
	 "                                  at address 0x00042.\n\n" \
	 "NOTES:     Breakpoints can be removed using the rb command.\n" \
	 "           All breakpoints can be viewed using the vb command.\n" \
	 "           Execution can be resumed using the cont command.\n" \
	 "           Instruction stepping can be achieved using the s and so commands.\n" \
	 "           To discover the address of instructions use the dis command.\n" \
	 "           After encountering a breakpoint, the vm and vr commands may\n" \
	 "           be useful for debugging.\n");
}

// Remove a breakpoint
void command_rb()
{
  int i;
  char *token;
  unsigned int addr;
  
  // Get the first token (the address)
  token = get_token();
  if (token) {
    if (strcmp(token, "?") != 0) {
      // Convert it to a number
      atob(token, &addr, 10);
      
      for (i = 0 ; i < MAX_BREAKPOINTS ; i++) {
	if (brk_point[i].addr == addr) {
	  brk_point[i].addr = 0xffffffff;
	  *((unsigned int *)addr) = brk_point[i].insn;
	  printf("Removed breakpoint at address 0x%05x.\n", addr);
	  return;
	}
      }
      
      printf("ERROR: There is no breakpoint set at address 0x%05x.\n", addr);
      return;
    }
  }
  printf("NAME:      remove breakpoint\n" \
	 "USAGE:     rb <address>\n" \
	 "DESCR:     Remove a breakpoint that has been previously set at the specified\n" \
	 "           address.\n\n" \
	 "EXAMPLES:  rb 0x00042           - remove a breakpoint at the address 0x00042.\n\n" \
	 "NOTES:     Breakpoints can be set using the sb command.\n" \
	 "           All breakpoints can be viewed using the vb command.\n");
}

void command_vb()
{
  int i, num_breakpoints = 0;
  char *token;

  // Get the first token
  token = get_token();
  if (token)
    if (strcmp(token, "?") == 0) {
      printf("NAME:      view breakpoints\n" \
	     "USAGE:     vb\n" \
	     "DESCR:     List all the currently set breakpoints.\n\n" \
	     "NOTES:     Breakpoints can be set using the sb command.\n" \
	     "           Breakpoints can be removed using the rb command.\n");
      return;
    }

  for (i = 0 ; i < MAX_BREAKPOINTS ; i++) {
    if (brk_point[i].addr != 0xffffffff) {
      if (num_breakpoints == 0)
	printf("BREAKPOINTS:\n");
      num_breakpoints++;
      printf(" 0x%05x %08x       ", brk_point[i].addr, brk_point[i].insn);
      disassemble(brk_point[i].addr, brk_point[i].insn);
      printf("\n");
    }
  }

  if (num_breakpoints == 0)
    printf("There are no breakpoints currently set.\n");
  
}

void do_step(boolean trace_into)
{
  int i, brk_num = MAX_BREAKPOINTS;
  unsigned int insn;
  
  // Figure out the address of the next instruction that will be executed
  // Default to the following instruction
  step_break_addr = program_counter + 1;
  insn = *(unsigned int *)program_counter;

  // We must figure out if we are sitting on a breakpoint
  if (*(unsigned int *)program_counter == BREAK_INSN) {
    for (i = 0 ; i < MAX_BREAKPOINTS ; i++)
      if (brk_point[i].addr == program_counter) {
	brk_num = i;
	insn = brk_point[i].insn;
	break;
      }
  }

  if ((insn >> 28) == 0x4 || (insn >> 28) == 0x6) { // j or jal
    // If we are tracing into then we place the breakpoint in the function
    if (trace_into == true || (insn >> 28) == 0x4) {
      step_break_addr = insn & 0xfffff;
    }
  }
  else if ((insn >> 28) == 0x5 || (insn >> 28) == 0x7) { // jr or jalr
    // If we are tracing into then we place the breakpoint in the function
    if (trace_into == true || (insn >> 28) == 0x5) {
      step_break_addr = regsave[(insn >> 20) & 0xf];
    }
  }
  else if ((insn >> 28) == 0xa) {// beqz
    int temp;
    if (regsave[(insn >> 20) & 0xf] == 0) {
      temp = (insn & 0xfffff);
      if (temp & 0x80000) {
	temp |= 0xfff00000;
      }
      step_break_addr = (int)step_break_addr + temp;
    }
  }
  else if ((insn >> 28) == 0xb) {// bnez
    int temp;
    if (regsave[(insn >> 20) & 0xf] != 0) {
      temp = (insn & 0xfffff);
      if (temp & 0x80000) {
	temp |= 0xfff00000;
      }
      step_break_addr = (int)step_break_addr + temp;
    }
  }

  // This branch will end up back here
  if (step_break_addr == program_counter) {
    // We must emulate the effects of this instruction
    if ((insn >> 28) == 0x6 || (insn >> 28) == 0x7) { // jal or jalr
      regsave[15] = program_counter + 1;
    }
    
    // So we just pretend to execute it
    printf("0x%05x  ", step_insn_addr);
    disassemble(step_insn_addr, *(unsigned int *)step_insn_addr);
    printf("\n");
    return;
  }
  else if (brk_num < MAX_BREAKPOINTS) {
    // We must replace the breakpoint instruction and then single step
    cont_addr = program_counter;
    cont_insn = (*(unsigned int *)program_counter = brk_point[brk_num].insn);
    step_break_mode = true;
  }

  if (in_rom(step_break_addr)) {
    printf("ERROR: Tried to step into ROM code.\n"); // probably shouldn't be an error, but rather a return to the monitor
    return;
  }
  
  // Insert the break instruction
  step_old_insn = *(unsigned int *)step_break_addr;
  *(unsigned int *)step_break_addr = BREAK_INSN;
  step_insn_addr = program_counter;

  // Begin execution
  step_mode = true;
  start_program(program_counter);
}

void command_so()
{
  char *token;

  // Get the first token
  token = get_token();
  if (token)
    if (strcmp(token, "?") == 0) {
      printf("NAME:      step over\n" \
	     "USAGE:     so\n" \
	     "DESCR:     Execute only the next instruction from the user program. Both the\n" \
	     "           instruction that is executed and the next instruction to be executed\n" \
	     "           will be displayed after the command has completed. When a subroutine\n" \
	     "           call (jal or jalr) is stepped over, then instead of stepping into\n" \
	     "           the routine, the routine will be completed before control is returned\n" \
	     "           returned the monitor.\n\n" \
	     "NOTES:     Subroutine calls can be stepped into using the s command.\n" \
	     "           Breakpoints can be set using the sb command.\n" \
	     "           Execution can be resumed using the cont command.\n" \
	     "           The address of the next instruction to be executed can be seen\n" \
	     "           using the vr command.\n");
      return;
    }

  do_step(false);
}

void command_s()
{
  char *token;

  // Get the first token
  token = get_token();
  if (token)
    if (strcmp(token, "?") == 0) {
      printf("NAME:      step\n" \
	     "USAGE:     s\n" \
	     "DESCR:     Execute only the next instruction from the user program. Both the\n" \
	     "           instruction that is executed and the next instruction to be executed\n" \
	     "           will be displayed after the command has completed.\n\n" \
	     "NOTES:     Subroutine calls can be skipped over using the so command.\n" \
	     "           Breakpoints can be set using the sb command.\n" \
	     "           Execution can be resumed using the cont command.\n" \
	     "           The address of the next instruction to be executed can be seen\n" \
	     "           using the vr command.\n");
      return;
    }

  do_step(true);
}

void command_cont()
{
  int i, brk_num = MAX_BREAKPOINTS;
  unsigned int insn;
  char *token;

  // Get the first token
  token = get_token();
  if (token)
    if (strcmp(token, "?") == 0) {
      printf("NAME:      continue\n" \
	     "USAGE:     cont\n" \
	     "DESCR:     Continue execution of a user program from after the last executed\n" \
	     "           instruction. This is normally used to resume execution after a\n" \
	     "           breakpoint has been encountered.\n\n" \
	     "NOTES:     Breakpoints can be set using the sb command.\n" \
	     "           Instruction stepping can be achieved using the s and so commands.\n" \
	     "           The address of the next instruction to be executed can be seen\n" \
	     "           using the vr command.\n");
      return;
    }

  // We must figure out if we are sitting on a breakpoint
  if (*(unsigned int *)program_counter == BREAK_INSN) {
    for (i = 0 ; i < MAX_BREAKPOINTS ; i++)
      if (brk_point[i].addr == program_counter) {
	brk_num = i;
	break;
      }
  }

  if (brk_num >= MAX_BREAKPOINTS) {
    start_program(program_counter);
    return; // redundant
  }

  // We are sitting on a breakpoint so we must single step and then after one step we let fly

  // Figure out the address of the next instruction that will be executed
  // Default to the following instruction
  step_break_addr = program_counter + 1;

  insn = brk_point[brk_num].insn;    //*(unsigned int *)program_counter;

  if ((insn >> 28) == 0x4 || (insn >> 28) == 0x6) { // j or jal
    step_break_addr = insn & 0xfffff;
  }
  else if ((insn >> 28) == 0x5 || (insn >> 28) == 0x7) { // jr or jalr
    step_break_addr = regsave[(insn >> 20) & 0xf];
  }
  else if ((insn >> 28) == 0xa) {// beqz
    unsigned int temp;
    if (regsave[(insn >> 20) & 0xf] == 0) {
      temp = (insn & 0xfffff);
      if (temp & 0x80000) {
	temp |= 0xfff00000;
      }
      step_break_addr += temp;
    }
  }
  else if ((insn >> 28) == 0xb) {// bnez
    unsigned int temp;
    if (regsave[(insn >> 20) & 0xf] != 0) {
      temp = (insn & 0xfffff);
      if (temp & 0x80000) {
	temp |= 0xfff00000;
      }
      step_break_addr += temp;
    }
  }

  // This branch will end up back here (which is a breakpoint)
  if (step_break_addr == program_counter) {
    // We must emulate the effects of this instruction if there are side-effects
    if ((insn >> 28) == 0x6 || (insn >> 28) == 0x7) { // jal or jalr
      regsave[15] = program_counter + 1;
    }
    
    // And then we just go from here again
    start_program(program_counter);
    return; // redundant
  }

  if (in_rom(step_break_addr)) {
    printf("ERROR: Tried to continue into ROM code.\n"); // probably shouldn't be an error, but rather a return to the monitor
    return;
  }
  
  // Replace the old instruction for a single step
  cont_insn = brk_point[brk_num].insn;
  cont_addr = program_counter;
  *(unsigned int *)program_counter = brk_point[brk_num].insn;
  cont_mode = true;

  // Insert the break instruction for the single step
  step_old_insn = *(unsigned int *)step_break_addr;
  *(unsigned int *)step_break_addr = BREAK_INSN;
  step_insn_addr = program_counter;

  // Begin execution
  step_mode = true;
  start_program(program_counter);
}

unsigned get_word()
{
  int i;
  unsigned data = 0;
  for (i = 0 ; i < 4 ; i++) {
    data <<= 8;
    data |= read_char();
  }
  return data;
}

void command_jtag()
{
  int num_words, i;
  unsigned *ptr;

  printf("Expecting xsvf file...\n");

  ptr = (unsigned *)0;
  num_words = get_word();

  for (i = 0 ; i < num_words ; i++)
    *ptr++ = get_word();

  printf("Waiting for keypress.\n");
  read_char();
  printf("Configuring via JTAG.\n");
  configure_JTAG((unsigned *)0);
  printf("Please reset the board.\n");
  while(1);
}
