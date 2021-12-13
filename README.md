# Elf Cube BIOS

## Version 1.0

Copyright (c) Mark Clegg: 2021

# Disclaimer

This is still very much a work in progress. It is not usable in it's current form.

# Introduction

Elf Cube BIOS provides basic I/O operations for the Elf Cube, Serial UART, IDE Interface and TMS9929A Video Card. It also provides standard call and return routines, pre-configured to use R4 R5 and R6 in the traditional setup. These are compatible with the 1806 SCAL R6 and SRET R6 instructions.

The provided SCRT routines preserve the D register, but overwrites RF.0. To maintain compatibility, R4 and R5 should not be used by the application program.

For function reference, please see the wiki.
