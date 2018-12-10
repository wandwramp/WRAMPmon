# WRAMPmon!!

WRAMPmon is the monitor program that runs on a WRAMP board when it is reset
to its initial state.  
It has a number of features, allowing a user to load, run, inspect, and debug
their own code.

WRAMPmon was initially written by Dean Armstrong, and ran on the original
REX boards. A few changes and enhancements were made by Daniel Oosterwijk
and Tyler Marriner while reimplementing WRAMP on the Basys3 FPGA.

## Usage

WRAMPmon is stored on the flash memory of the Basys3 FPGAs. Instructions for
using the .mem file created by this project can be found in WRAMPsys.

## Building

Building WRAMPmon from source requires a complete WRAMP toolchain, including
`wasm`, `wlink`, `wcc`, and `trim`.
These can be found in the wasm, wcc, and trim projects.
Once all four binaries can be run from the command line, run `make`.
This will also build `monitor.srec` as an intermediate file, but it cannot
be loaded onto the board as other .srec files can.
