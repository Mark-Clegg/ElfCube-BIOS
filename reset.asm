;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; RESET.ASM
;;
;; System Reset call
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

                seg     bios_data

dump_flags      ds      1
dump_register   ds      $20

                seg     bios_code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; reset
;;
;; Reset back to X=P=0 and lbr to 0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

                subroutine reset
reset           ldi     high(.save)             ; Switch to P=0 with Interrupts disabled
                phi     r0
                ldi     low(.save)
                plo     r0
                sep     r0

.save           sex     r0
                dis
                db      $10
                ldi     high(dump_register+$1f) ; Setup R1 to point to BIOS Dump area
                phi     r1
                ldi     low(dump_register+$1f)
                plo     r1

                glo     rf                      ; Save registers
                stxd
                ghi     rf
                stxd
                glo     re
                stxd
                ghi     re
                stxd
                glo     rd
                stxd
                ghi     rd
                stxd
                glo     rc
                stxd
                ghi     rc
                stxd
                glo     rb
                stxd
                ghi     rb
                stxd
                glo     ra
                stxd
                ghi     ra
                stxd
                glo     r9
                stxd
                ghi     r9
                stxd
                glo     r8
                stxd
                ghi     r8
                stxd
                glo     r7
                stxd
                ghi     r7
                stxd
                glo     r6
                stxd
                ghi     r6
                stxd
                glo     r5
                stxd
                ghi     r5
                stxd
                glo     r4
                stxd
                ghi     r4
                stxd
                glo     r3
                stxd
                ghi     r3
                stxd
                glo     r2
                stxd
                ghi     r2
                stxd
                glo     r1
                stxd
                ghi     r1
                stxd
                glo     r0
                stxd
                ghi     r0
                stxd

                ldi     $00                     ; Loaad 0, and save a copy for later
                bn4     . + 4                   ; Pack status of EF lines (low nibble)
                ori     $08
                bn3     . + 4
                ori     $04
                bn2     . + 4
                ori     $02
                bn1     . + 4
                ori     $01
                lsnq                            ; Q = $40
                ori     $40
                lsnf                            ; DF = $80
                ori     $80
                stxd                            ; Flags: DF  Q   0   0   EF4 EF3 EF2 Ef1

                req
                sex     r0
                lbr     $0000
