;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Elf-Cube BIOS
;;
;; Version 1.0
;;
;; Basic Input Output system calls for the
;; fully populated Elf-Cube:
;; - Processor Card (1802 or 1806)
;; - UART Card (Interrupt driven)
;; - Video Card (TMS9929A)
;; - IDE Adapter (8 bit SD Card)
;;
;; (c) M.Clegg 2021
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

                cpu     1802

                list    off
                include BIOS.asm
                list    on
                list    macro

himem           equ     $10000                  ; Top of RAM+1 - should be $ffff when BIOS is in EEPROM

; PORT Assignments
IDE_Data        equ     1
IDE_Address     equ     2
UART            equ     3
Video           equ     4

; Memory Map
vectors         equ     himem - 1               ; BIOS Entry Points start here and work down

                seg     bios_data               ; BIOS Data Area
                org     himem - $200

                seg     bios_stack              ; Stack
stack           org     himem - $200 -1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; MAIN CODE START
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                seg     bios_code
origin          org     $8000

                dis
                db      $00

                ldi     high(bios_init)
                phi     r3
                ldi     low(bios_init)
                plo     r3
                sep     r3

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                subroutine bios_init
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
bios_init       ldi     high(interrupt)         ; Initialise Interrupt handler (R1)
                phi     r1
                ldi     low(interrupt)
                plo     r1

                ldi     high(stack)             ; Initialise Stack Pointer (R2)
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
                call    ide_init

                sex     r3                      ; Enable interrupts
                ret
                db      $23
                lbr     start                   ; BIOS Initialisation complete - Enter OS ???

                include scrt.asm
                include serial.asm
                include reset.asm
                include ide.asm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; BIOS Entry Vector Initialisation Table
;; Contains the addresses of the published BIOS Interface routines
;;
;; These should be listed in reverse order, and will be copied to high
;; RAM with each entry point preceeded by an LBR ($C0) instruction
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
vector_start    dw      reset       ; $FFFD = Reset
                dw      serial_read
                dw      serial_count
                dw      serial_write
                dw      serial_write_immediate
                dw      serial_write_hex
                dw      serial_write_hex_immediate
                dw      serial_write_string
                dw      serial_write_string_at
                dw      serial_write_string_immediate
                dw      ide_identity_string
                dw      ide_sector_count
vector_end
vector_count    equ (vector_end - vector_start) / 2

                subroutine
                .1802

                align   $100

start           ghi     r2
                BIOS_SerialWriteHex
                glo     r2
                BIOS_SerialWriteHex
                BIOS_SerialWriteStringImmediate "\r\n"

.loop           BIOS_SerialRead
                str     r2
                smi     'x'
                bz      .exit
                ldn     r2
                BIOS_SerialWrite
                BIOS_SerialWriteImmediate '-'
                ghi     r2
                BIOS_SerialWriteHex
                glo     r2
                BIOS_SerialWriteHex
                BIOS_SerialWRiteImmediate '-'
                BIOS_SerialCount
                BIOS_SerialWriteHex
                BIOS_SerialWriteStringImmediate '\r\n'

                br      .loop

.exit           BIOS_SerialWriteStringImmediate "\r\nDone\r\n"
                BIOS_SerialWriteStringAt .string

                ghi     r2
                BIOS_SerialWriteHex
                glo     r2
                BIOS_SerialWriteHex
                BIOS_SerialWriteStringImmediate "\r\n"

                ghi     r2
                BIOS_SerialWriteHex
                glo     r2
                BIOS_SerialWriteHex
                BIOS_SerialWriteStringImmediate "\r\n"

                BIOS_IDEIdentityString
                BIOS_SerialWriteString
                BIOS_SerialWriteStringImmediate "<\r\n"

                BIOS_SerialWriteStringImmediate "Number of Sectors: "

                BIOS_IDESectorCount
                lda     re
                BIOS_SerialWriteHex
                lda     re
                BIOS_SerialWriteHex
                lda     re
                BIOS_SerialWriteHex
                lda     re
                BIOS_SerialWriteHex

                BIOS_SerialWriteStringImmediate "\r\n"
                ghi     r2
                BIOS_SerialWriteHex
                glo     r2
                BIOS_SerialWriteHex

                BIOS_SerialWriteStringImmediate "\r\n"

                BIOS_Reset

.string         db      "\r\nPress Enter to return to Idiot/4\r\n",0
                end
