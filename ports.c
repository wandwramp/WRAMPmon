/*******************************************************/
/* file: ports.c                                       */
/* abstract:  This file contains the routines to       */
/*            output values on the JTAG ports, to read */
/*            the TDO bit, and to read a byte of data  */
/*            from the prom                            */
/*                                                     */
/*******************************************************/
#include "ports.h"

unsigned *xsvf_data;
int byte_no;

/* if in debugging mode, then just set the variables */
void setPort(short p, short val)
{
  if (p == TCK)
    (*(unsigned *)0x7fff0) = ((*(unsigned *)0x7fff0) & 0x7) | (val << 3);
  if (p == TMS)
    (*(unsigned *)0x7fff0) = ((*(unsigned *)0x7fff0) & 0xb) | (val << 2);
  if (p == TDI)
    (*(unsigned *)0x7fff0) = ((*(unsigned *)0x7fff0) & 0xd) | (val << 1);
}


/* toggle tck LHL */
void pulseClock()
{
  setPort(TCK, 0);  /* set the TCK port to low  */
  setPort(TCK, 1);  /* set the TCK port to high */
  setPort(TCK, 0);  /* set the TCK port to low  */
}

void initialise_xsvf(unsigned *buffer)
{
  xsvf_data = buffer;
  byte_no = 0;
}

/* read in a byte of data from the prom */
void readByte(unsigned char *data)
{
  *data = ((*xsvf_data) >> ((3 - byte_no) * 8)) & 0xff;

  byte_no = (byte_no + 1) & 0x3;

  // Every 4 we increment our data pointer
  if (byte_no == 0)
    xsvf_data++;
}

/* read the TDO bit from port */
unsigned char readTDOBit()
{
  return ((*(unsigned *)0x7fff0) & 1);
}

/* Wait at least the specified number of microsec.                           */
/* Use a timer if possible; otherwise estimate the number of instructions    */
/* necessary to be run based on the microcontroller speed.  For this example */
/* we pulse the TCK port a number of times based on the processor speed.     */
void waitTime(long microsec)
{
  long tckCycles   = (microsec / 50);
  int i;

  /* For systems with TCK rates >= 1 MHz;  This implementation is fine. */
  for (i = 0 ; i < tckCycles ; i++) {
    pulseClock();
  }
}
