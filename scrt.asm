;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; SCRT.ASM
;;
;; Standard Call and Return
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                subroutine scal
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                sep     r3
scal            plo     rf
                glo     r6                      ; Standard Call
                stxd
                ghi     r6
                stxd
                glo     r3
                plo     r6
                ghi     r3
                phi     r6
                lda     r6
                phi     r3
                lda     r6
                plo     r3
                glo     rf
                br      scal-1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                subroutine sret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                sep     r3
sret            plo     rf
                glo     r6                      ; Standard Return
                plo     r3
                ghi     r6
                phi     r3
                irx
                ldxa
                phi     r6
                ldx
                plo     r6
                glo     rf
                br      sret-1
