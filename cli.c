#include "stdio.h"
#include "commands.h"
#include "token.h"
#include "clib.h"
#include "utils.h"

typedef struct {
  char *cmd;
  void *fn;
} cmd_entry;

cmd_entry cmd_table[] = {
  { "load", (void *)command_load },
  { "dis", (void *)command_dis },
  { "vr", (void *)command_vr },
  { "sr", (void *)command_sr },
  { "sb", (void *)command_sb },
  { "vb", (void *)command_vb },
  { "rb", (void *)command_rb },
  { "vm", (void *)command_vm },
  { "sm", (void *)command_sm },
  { "go", (void *)command_go },
  { "cont", (void *)command_cont },
  { "s", (void *)command_s },
  { "so", (void *)command_so },
  { "about", (void *)command_about },
  { "help", (void *)command_help },
  { "?", (void *)command_help },
  { "flash", (void *)command_flash },
  //  { "jtag", (void *)command_jtag },
  { "sws_debug", (void *)command_sws_debug },
  { (char *)0, (void *)0 }};

void welcome()
{
  printf("\n");
  printf("+------------------------------------------------+\n");
  printf("|                 WRAMPmon 0.5                   |\n");
  printf("| Copyright 2002, 2003 The University of Waikato |\n");
  printf("|                                                |\n");
  printf("|          Written by Dean Armstrong             |\n");
  printf("+------------------------------------------------+\n");
  printf("\n");
  printf("Type ? and press enter for available commands.\n\n");
}

void process_cmd(char *cmd)
{
  int i;
  char *tmp = cmd;

  /* Convert the entire command to lower case */
  while (*tmp != '\0') {
    *tmp = tolower(*tmp);
    tmp++;
  }

  tokenise(cmd);

  tmp = get_token();
  if (!tmp)
    return;

  for (i = 0 ; cmd_table[i].cmd ; i++) {
    if (strcmp(tmp, cmd_table[i].cmd) == 0)
      break;
  }

  if (!cmd_table[i].cmd) {
    printf("Invalid command entered.\n");
    return; 
  }
  
  invoke(cmd_table[i].fn);
}

void cli()
{
  char cmd_buf[256];
  for (;;) {
    printf(" > ");
    gets(cmd_buf);
    process_cmd(cmd_buf);
  }
}
