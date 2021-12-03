;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Elf-Cube BIOS
;
; Version 1.0
;
; Basic Input Output system calls for the
; fully populated Elf-Cube:
; - Processor Card (1802 or 1806)
; - UART Card (Interrupt driven)
; - Video Card (TMS9929A)
; - IDE Adapter (8 bit SD Card)
;
; (c) M.Clegg 2021
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

himem           equ     $10000                  ; Top of RAM+1 - should be $ffff when BIOS is in EEPROM

; PORT Definitions
IDE_Address     equ     1
IDE_Data        equ     2
UART            equ     3
Video           equ     4


vectors         equ     himem - 1               ; BIOS Entry Points start here and work down

                seg     bios_data               ; BIOS Data Area
                org     himem - $200

                seg     bios_stack              ; Stack
stack           org     himem - $200 -1


                cpu     1802

                include macros.asm
                list    macro

                seg     bios_code
origin          org     $8000

                dis
                db      $00

                assert high(bios_init) = high(.)
                ghi     r0
                phi     r3
                ldi     low(bios_init)
                plo     r3
                sep     r3

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                subroutine bios_init
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
bios_init       ldi     high(stack)             ; Initialise Stack Pointer (R2)
                phi     r2
                ldi     low(stack)
                plo     r2

                ldi     high(scal)              ; Initialise SCAL/SRET (R4,R5)
                phi     r4
                ldi     low(scal)
                plo     r4
                ldi     high(sret)
                phi     r5
                ldi     low(sret)
                plo     r5

                ldi     high(vector_start)      ; Initialise the BIOS Vector Table
                phi     re
                ldi     low(vector_start)
                plo     re

                ldi     high(vectors)
                phi     rf
                ldi     low(vectors)
                plo     rf
                sex     rf

                ldi     $c0
                phi     rd
                ldi     vector_count            ; For upto a maximum of 256 vectors
                plo     rc

.loop           lda     re
                plo     rd
                lda     re
                stxd
                glo     rd
                stxd
                ghi     rd
                stxd
                dec     rc
                glo     rc
                bnz     .loop

                sex     r2
                call    serial_init

                sex     r3
                ret
                db      $23
                lbr     start                   ; BIOS Initialisation complete - Enter OS ???

                include reset.asm
                include scrt.asm
                include serial.asm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; BIOS Entry Vector Initialisation Table
; Contains the addresses of the published BIOS Interface routines
;
; These should be listed in reverse order, and will be copied to high
; RAM with each entry point preceeded by an LBR ($C0) instruction
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
vector_start    dw      reset       ; $FFFD = Reset
                dw      serial_read
                dw      serial_count
                dw      serial_write
                dw      serial_write_immediate
                dw      serial_writehex
                dw      serial_writehex_immediate
                dw      serial_writestring
                dw      serial_writestring_immediate
vector_end
vector_count    equ (vector_end - vector_start) / 2



                subroutine
                align   $100

                include BIOS.asm
start           sex     r2

.loop           call    BIOS_SerialRead
                str     r2
                smi     'x'
                bz      exit
                ldn     r2
                call    BIOS_SerialWrite
                br      .loop

exit            call    BIOS_SerialWriteStringImmediate
                db      "\r\nDone\r\n",0
                ldi     high(string)
                phi     re
                ldi     low(string)
                plo     re
                call    BIOS_SerialWriteString
                lbr     BIOS_Reset

string          db      "\r\nPress Enter to return to Idiot/4\r\n",0
                end
