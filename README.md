# Elf Cube BIOS

## Version 1.0

Copyright (c) Mark Clegg: 2021

# Disclaimer

This is still very much a work in progress. It is not usable in it's current form.

# Introduction

Elf Cube BIOS provides basic I/O operations for the Elf Cube, Serial UART, IDE Interface and TMS9929A Video Card. It also provides standard call and return routines, pre-configured to use R4 R5 and R6 in the traditional setup. These are compatible with the 1806 SCAL R6 and SRET R6 instructions.

The provided SCRT routines preserve the D register, but overwrites RF.0. To maintain compatibility, R4 and R5 should not be used by the application program.

# Register Assignments

<dl>
<dt>R0</dt><dd>DMA Pointer (currently unused)</dd>
<dt>R1</dt><dd>Interrupt Handler - Initialsed fo handle interrupts from the 1854 UART</dd>
<dt>R2</dt><dd>Stack Pointer</dd>
<dt>R3</dt><dd>Program Counter</dd>
<dt>R4</dt><dd>Standard Call Program Counter</dd>
<dt>R5</dt><dd>Standard Return Program Counter</dd>
<dt>R6</dt><dd>In-Line Parameter Counter for SCRT and 1806 SCAL R6 type calls</dd>
<dt>R7</dt><dd>...</dd>
<dt>R8</dt><dd>...</dd>
<dt>R9</dt><dd>...</dd>
<dt>RA</dt><dd>...</dd>
<dt>RB</dt><dd>...</dd>
<dt>RC</dt><dd>...</dd>
<dt>RD</dt><dd>...</dd>
<dt>RE</dt><dd>...</dd>
<dt>RF</dt><dd>Temporary data - overwritten by SCRT routines</dd>
</dl>
# Function Reference

All BIOS functions are called using SCRT (or 1806 SCAL R6...) via entry vectors stored in high memory. These are all stored as LBR instructions to the internal BIOS routin. This ensures that the entry point remains fixed, regardless of the implementation. It also allows application programs to redirect the built in functions by simply replacing the vector.

Application code should include the BIOS.asm to provide easy reference to the supplied interfaces.

Unless otherwise stated, all registers are preserved except those used to pass parameters to the function.

## BIOS_Reset ($FFFD)

Perform a system restart, reset X=P=0 and LBR to $0000

## BIOS_SerialRead ($FFFA)

Waits for a single character to be received from teh UART and return it in D

## BIOS_SerialCount ($FFF7)

Returns the numbre of characters currently held in the UART receive buffer

## BIOS_SerialWrite ($FFF4)

Writes the character in D to the UART (D is preserved)

## BIOS_SerialWriteImmediate ($FFF1)

Writes the next byte following the call to the UART (returns with the transmitted character in D)

## BIOS_SerialWriteHex ($FFEE)

Writes the character in D to the UART as two hexadecimal digits (D is preserved)

## BIOS_SerialWriteHexImmediate ($FFEB)

Writes the next byte following the call to the UART as two hexadecimal digits (returns with the byte transmitted in D)

## BIOS_SerialWriteString ($FFE8)

Writes the ASCIIZ string starting at the address in RE to the UART. Returns with RE pointing to the next byte after the null terminator.

## BIOS_SerialWriteStringAt

Writes the ASCIIZ string starting at the address following the call. Returns with RE pointing to the next byte after the null terminator.

## BIOS_SerialWriteStringImmediate ($FFE5)

Writes the ASCIIZ string immediately following the call to the UART.
