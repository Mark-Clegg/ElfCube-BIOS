;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Elf Cube BIOS
;;
;; Version 1.0
;;
;; BIOS Entry Points
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

BIOS_Reset                      equ     $FFFD
BIOS_IfError                    equ     $FFFA

BIOS_SerialRead                 equ     $FFF7
BIOS_SerialCount                equ     $FFF4
BIOS_SerialWrite                equ     $FFF1
BIOS_SerialWriteImmediate       equ     $FFEE
BIOS_SerialWriteHex             equ     $FFEB
BIOS_SerialWriteHexImmediate    equ     $FFE8
BIOS_SerialWriteString          equ     $FFE5
BIOS_SerialWriteStringAt        equ     $FFE2
BIOS_SerialWriteStringImmediate equ     $FFDF

BIOS_IDEIdentityString          equ     $FFDC
BIOS_IDESectorCount             equ     $FFD9
BIOS_IDEReadSector              equ     $FFD6
BIOS_IDEWriteSector             equ     $FFD3

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Standard CALL
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
call            macro   addr
                sep     r4
                dw      addr
                endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Standard Return
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
return          macro
                sep     r5
                endm

;; Define Macros to access the BIOS functions, based on
;; Processor type

                if CPU(1802)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;   *    ***     *     **
;;  **   *   *   * *   *  *
;;   *    ***   *   *     *
;;   *   *   *  *   *   **
;;   *   *   *   * *   *
;;  ***   ***     *    ****
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
BIOS_Reset      macro
                lbr     BIOS_Reset
                endm

BIOS_IfError    macro   address
                sep     r4
                dw      BIOS_IfError
                dw      address
                endm

BIOS_SerialRead macro
                sep     r4
                dw      BIOS_SerialRead
                endm

BIOS_SerialCount    macro
                sep     r4
                dw      BIOS_SerialCount
                endm

BIOS_SerialWrite    macro
                sep     r4
                dw      BIOS_SerialWrite
                endm

BIOS_SerialWriteImmediate   macro   character
                sep     r4
                dw      BIOS_SerialWriteImmediate
                db      character
                endm

BIOS_SerialWriteHex macro
                sep     r4
                dw      BIOS_SerialWriteHex
                endm

BIOS_SerialWriteHexImmediate    macro   byte
                sep     r4
                dw      BIOS_SerialWriteHexImmediate
                db      byte
                endm

BIOS_SerialWriteString  macro
                sep     r4
                dw      BIOS_SerialWriteString
                endm

BIOS_SerialWriteStringAt    macro   address
                sep     r4
                dw      BIOS_SerialWriteStringAt
                dw      address
                endm

BIOS_SerialWriteStringImmediate macro   string
                sep     r4
                dw      BIOS_SerialWriteStringImmediate
                db      string,0
                endm

BIOS_IDEIdentityString  macro
                sep     r4
                dw      BIOS_IDEIdentityString
                endm

BIOS_IDESectorCount macro
                sep     r4
                dw      BIOS_IDESectorCount
                endm

BIOS_IDEReadSector  macro
                sep     r4
                dw      BIOS_IDEReadSector
                endm

BIOS_IDEWriteSector macro
                sep     r4
                dw      BIOS_IDEWriteSector
                endm

                endif

                if CPU(1804) || CPU(1805) || CPU(1806)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;   *    ***     *       *       *  ****      *   ***
;;  **   *   *   * *     **      *   *        *   *
;;   *    ***   *   *   * *     *    ***     *    ****
;;   *   *   *  *   *  *****    *       *    *    *   *
;;   *   *   *   * *      *    *     *  *   *     *   *
;;  ***   ***     *       *   *       **   *       ***
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

BIOS_Reset      macro
                lbr     BIOS_Reset
                endm

BIOS_IfError    macro   address
                scal    r6, BIOS_IfError
                dw      address
                endm

BIOS_SerialRead macro
                scal    r6, BIOS_SerialRead
                endm

BIOS_SerialCount    macro
                scal    r6, BIOS_SerialCount
                endm

BIOS_SerialWrite    macro
                scal    r6, BIOS_SerialWrite
                endm

BIOS_SerialWriteImmediate   macro   character
                scal    r6, BIOS_SerialWriteImmediate
                db      character
                endm

BIOS_SerialWriteHex macro
                scal    r6, BIOS_SerialWriteHex
                endm

BIOS_SerialWriteHexImmediate    macro   byte
                scal    r6, BIOS_SerialWriteHexImmediate
                db      byte
                endm

BIOS_SerialWriteString  macro
                scal    r6, BIOS_SerialWriteString
                endm

BIOS_SerialWriteStringAt    macro   address
                scal    r6, BIOS_SerialWriteStringAt
                dw      address
                endm

BIOS_SerialWriteStringImmediate macro   string
                scal    r6, BIOS_SerialWriteStringImmediate
                db      string, 0
                endm

BIOS_IDEIdentityString  macro
                scal    r6, BIOS_IDEIdentityString
                endm

BIOS_IDESectorCount macro
                scal    r6, BIOS_IDESectorCount
                endm

BIOS_IDEReadSector  macro
                scal    r6, BIOS_IDEReadSector
                endm

BIOS_IDEWriteSector macro
                scal    r6, BIOS_IDEWriteSector
                endm

                endif
