;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ERROR.ASM
;;
;; System Reset call
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; bios_ifError
;;
;; Parameters
;; Immediate    Address of Error Message
;; D            Error Code
;; DF=0         No Error - just return
;; DF=1         Display Error Message and Halt
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                subroutine error
iferror         bnf     .return
                stxd
                lda     r6
                phi     re
                lda     r6
                plo     re
                call    serial_write_string
                irx
                ldn     r2
                call    serial_write_hex
                idl
                br      .-1
.return         return

