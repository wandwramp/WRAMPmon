#ifndef INSTRUCTIONS_H
#define INSTRUCTIONS_H

extern char *GPR_name[];
extern char *SPR_name[];


typedef enum { INSN, I_TYPE, R_TYPE, J_TYPE, DIRECTIVE, OTHER } insn_descriptor;

typedef struct {
  char *mnemonic;
  char *operands;
  unsigned int OPCode, func;
  insn_descriptor type;
} insn_type;

typedef struct {
  char *reg_name;
  int reg_num;
} reg_type;

extern insn_type insn_table[];

//extern void disassemble(unsigned int, unsigned int);

#endif

