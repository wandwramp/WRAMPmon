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
