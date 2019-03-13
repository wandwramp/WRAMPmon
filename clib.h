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

#ifndef CLIB_H
#define CLIB_H

char *strcat(char *s, char *t);
int strcmp(char *s, char *t);
char *strcpy(char *s, char *t);
int strlen(char *s);
int isupper(char c);
int islower(char c);
int isdigit(char c);
int isprint(char c);
int ishex(char c);
int isspace(char c);
char tolower(char c);
int a_con_bin(char c);
char *atob(char *str, unsigned int *ptrnum, unsigned int base);

#endif
