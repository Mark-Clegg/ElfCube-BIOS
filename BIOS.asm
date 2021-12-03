; Elf Cube BIOS
;
; Version 1.0
;
; BIOS Entry Points

BIOS_Reset                      equ     $FFFD
BIOS_SerialRead                 equ     $FFFA
BIOS_SerialCount                equ     $FFF7
BIOS_SerialWrite                equ     $FFF4
BIOS_SerialWriteImmediate       equ     $FFF1
BIOS_SerialWriteHex             equ     $FFEE
BIOS_SerialWriteHexImmediate    equ     $FFEB
BIOS_SerialWriteString          equ     $FFE8
BIOS_SerialWriteStringImmediate equ     $FFE5
