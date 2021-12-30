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
                call    serial_write_string_at
                dw      string_Announce

                call    ide_init
                call    iferror
                dw      string_IDEFail

.ideFound       sex     r3                      ; Enable interrupts
                ret
                db      $23
                lbr     start                   ; BIOS Initialisation complete - Enter OS ???

                include error.asm
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
                dw      iferror
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
                dw      ide_read_sector
                dw      ide_write_sector
vector_end
vector_count    equ (vector_end - vector_start) / 2

string_Announce db      $1b,"[2J",$1b,"[HElf-Cube BIOS Version 1.0\r\n\r\n",0
string_IDEFail  db      "IDE Device Error: ",0

                subroutine
                .1802

                align   $100

Sector          db      0,2,0,0         ; Test Sector Numbers

start           BIOS_SerialWriteStringImmediate "\r\n"
                BIOS_SerialWriteStringImmediate "Drive Model: "
                BIOS_IDEIdentityString
                BIOS_SerialWriteString
                BIOS_SerialWriteStringImmediate "\r\n"

                BIOS_SerialWriteStringImmediate "Sectors:     "
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

                BIOS_SerialWriteStringImmediate "Stack: "
                ghi     r2
                BIOS_SerialWriteHex
                glo     r2
                BIOS_SerialWriteHex
                BIOS_SerialWriteStringImmediate "\r\n"

Command         BIOS_SerialWriteStringImmediate "(R)ead or (W)rite a Sector, or return to (I)diot Monitor\r\n"
                BIOS_SerialRead
                smi     'I'
                bz      GoToBIOS
                smi     'R'-'I'
                lbz     ReadTest
                smi     'W'-'R'
                bz      WriteTest
                br      Command

GoToBIOS        BIOS_SerialWriteStringImmediate "Press <Enter> to re-start\r\n"
                BIOS_Reset

WriteTest       ldi     $88
                plo     r7                      ; Value to initialise sector / sector number

                ldi     $00
                plo     r8
                ldi     $91
                phi     r9
                ldi     $ff
                plo     r9
                sex     r9

fillbuffer      glo     r7                      ; Write 512 bytes of R7.0
                stxd
                stxd
                dec     r8
                glo     r8
                bnz     fillbuffer
                glo     r7
                stxd

                sex     r2
                BIOS_SerialWriteStringImmediate "Write Sector from data at $9000 - "

                ldi     high(Sector)
                phi     rd
                ldi     low(Sector)
                plo     rd

                ldi     $90
                phi     re
                ldi     $00
                plo     re

                ldi     $01
                plo     rc
                ldi     $00
                phi     rc

                BIOS_IDEWriteSector
                bdf     Failed

Succeeded       BIOS_SerialWriteHex
                BIOS_SerialWriteStringImmediate " OK\r\n"
                lbr     Command

Failed          BIOS_SerialWriteHex
                BIOS_SerialWriteStringImmediate " Error\r\n"
                lbr     Command

ReadTest        BIOS_SerialWriteStringImmediate "Read Sector to $A000 - "

                ldi     high(Sector)
                phi     rd
                ldi     low(Sector)
                plo     rd

                ldi     $a0
                phi     re
                ldi     $00
                plo     re

                ldi     $01
                plo     rc
                ldi     $00
                phi     rc

                BIOS_IDEReadSector
                lbdf    Failed
                lbr     Succeeded

                end
