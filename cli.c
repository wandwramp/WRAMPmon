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

#include "stdio.h"
#include "commands.h"
#include "token.h"
#include "clib.h"
#include "utils.h"

typedef struct {
  char *cmd;
  void (*fn)(void);
} cmd_entry;

cmd_entry cmd_table[] = {
	{"load",		&command_load 		},
	{"dis",			&command_dis 		},
	{"vr", 			&command_vr 		},
	{"sr", 			&command_sr 		},
	{"sb", 			&command_sb 		},
	{"vb", 			&command_vb 		},
	{"rb", 			&command_rb 		},
	{"vm", 			&command_vm 		},
	{"sm", 			&command_sm 		},
	{"go", 			&command_go 		},
	{"cont",		&command_cont 		},
	{"s", 			&command_s 			},
	{"so", 			&command_so 		},
	{"about", 		&command_about 		},
	{"help",		&command_help 		},
	{"?", 			&command_help 		},
	{"cls", 		&command_cls 		},
	{"iddqd", 		&command_games		},
	{"sws_debug",	&command_sws_debug	},
	{(char *)0, 	&command_help 		}
  };

void welcome()
{
  printf("\n");
  printf("+------------------------------------------------+\n");
  printf("|                 WRAMPmon 0.8                   |\n");
  printf("| Copyright 2002-2019 The University of Waikato  |\n");
  printf("|                                                |\n");
  printf("|          Written by Dean Armstrong             |\n");
  printf("|       Ported to the Basys3 in 2018 by          |\n");
  printf("|     Daniel Oosterwijk and Tyler Marriner       |\n");
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
