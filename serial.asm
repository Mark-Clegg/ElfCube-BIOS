;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; SERIAL.ASM
;;
;; Serial API functions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

serial_bufsize  equ     $10                     ; Defines the size of the Serial Input FIFO (power of 2)

                seg     bios_data
                align   serial_bufsize          ; Align the Serial Buffer to it's size
serial_buffer   ds      serial_bufsize          ; serial input FIFO
serial_head     ds      1                       ; next read location
serial_tail     ds      1                       ; next write location

                assert  high(serial_buffer) = high(serial_head) && high(serial_buffer) = high(serial_tail)

                seg     bios_code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; serial_init
;;
;; Initialise the 1854 UART,setup the
;; interrupt handler and enable interrupts
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                subroutine serial_init
serial_init     ldi     high(interrupt)         ; Initialise Interrupt handler (R1)
                phi     r1
                ldi     low(interrupt)
                plo     r1

                seq
                ldi     $39                     ; No parity, 8 Data, 1 Stop
                str     r2
                out     UART
                dec     r2
                ori     $80                     ; RTS on and lock config
                str     r2
                out     UART
                req
                dec     r2

                ldi     high(serial_tail)       ; Set serial_head and serial_tail
                phi     rf                      ; to make the buffer empty
                ldi     low(serial_tail)
                plo     rf
                sex     rf
                ldi     low(serial_buffer)
                stxd
                stxd
                return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; INTERRUPT Service routine
;;
;; Check and read a character from the 1854 UART and store
;; in the serial_buffer at serial_tail
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                subroutine interrupt
                ret
interrupt       dec     r2
                sav                             ; Save X,P
                dec     r2
                stxd                            ; Save D
                shlc                            ; Save DF,Q
                ani     1
                lsnq
                ori     2
                stxd
                ghi     rf                      ; Save RF
                stxd
                glo     rf
                stxd

                seq                             ; Read UART Status Register
                inp     UART
                req
                shrc                            ; Check for Data Available
                bnf     .nodata

                ldi     high(serial_tail)       ; Read the character from the UART
                phi     rf                      ; and store it at serial_tail
                ldi     low(serial_tail)        ; then increment serial_tail wrapping
                plo     rf                      ; round ot stay within the buffer
                ldn     rf
                plo     rf
                sex     rf
                inp     UART
                ldi     low(serial_tail)
                plo     rf
                ldn     rf
                adi     1
                ani     serial_bufsize - 1
                ori     low(serial_buffer) & ~(serial_bufsize - 1)
                str     rf

.nodata         sex     r2
                irx
                ldxa                            ; Restore RF
                plo     rf
                ldxa
                phi     rf
                ldxa                            ; Restore DF,Q
                shr
                bz      .qoff
                seq
.qoff           ldxa                            ; Restore D
                br      interrupt - 1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; serial_read
;;
;; Return the next character from the serial buffer
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                subroutine serial_read
serial_read     ldi     high(serial_head)
                phi     rf
                ldi     low(serial_head)
                plo     rf
                sex     rf
                skp
.wait           idl                             ; Wait for an interrupt
                ldxa                            ; Check for Head != Tail
                sm
                dec     rf
                bz      .wait

                ldx
                str     r2
                adi     1
                ani     serial_bufsize - 1
                ori     low(serial_buffer) & ~(serial_bufsize - 1)
                str     rf

                sex     r2
                ldx
                plo     rf
                ldn     rf
                return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; serial_count
;;
;; Return the number of characters in the buffer
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                subroutine serial_count
serial_count    ldi     high(serial_head)
                phi     rf
                ldi     low(serial_head)
                plo     rf
                lda     rf
                sex     rf
                sd
                sex     r2
                lsdf
                ani     serial_bufsize - 1
                return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; serial_write
;; serial_write_immediate
;;
;; Write the character in D to the UART
;; Returns the character written
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                subroutine serial_write
serial_write_immediate
                lda     r6
serial_write    stxd
                seq
.loop           inp     UART                    ; Wait for THRE
                shlc
                bnf     .loop
                req
                irx
                out     UART
                dec     r2
                return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; serial_write_hex
;; serial_write_hex_immediate
;;
;; Write a byte as 2 hex digits
;; Returns the character written
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                subroutine serial_write_hex
serial_write_hex_immediate
                lda     r6
serial_write_hex
                stxd
                stxd
                shr                             ; High nibble
                shr
                shr
                shr
                smi     $0a
                lsnf
                adi     $07
                adi     $3a
                stxd
                seq
.loop1          inp     UART                    ; Wait for THRE
                shlc
                bnf     .loop1
                req
                irx
                out     UART
                ldx                             ; Low nibble
                ani     $0f
                smi     $0a
                lsnf
                adi     $07
                adi     $3a
                stxd
                seq
.loop2          inp     UART                    ; Wait for THRE
                shlc
                bnf     .loop2
                req
                irx
                out     UART
                ldx
                return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; serial_write_string
;; serial_write_string_at
;;
;; Write a null terminated string stored at RE
;; Returns with RE pointing to next byte after
;; the string
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                subroutine serial_write_string
serial_write_string_at
                lda     r6
                phi     re
                lda     r6
                plo     re
serial_write_string
.next_char      ldn     re
                bz      .exit
                seq
.wait_thre      inp     UART
                shlc
                bnf     .wait_thre
                req
                sex     re
                out     UART
                sex     r2
                br      .next_char
.exit           inc     re
                return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; serial_write_string_immediate
;;
;; Write the null terminated string immediately
;; following the call
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                subroutine serial_write_string_immediate
serial_write_string_immediate
.next_char      ldn     r6
                bz      .exit
                seq
.wait_thre      inp     UART
                shlc
                bnf     .wait_thre
                req
                sex     r6
                out     UART
                sex     r2
                br      .next_char
.exit           inc     r6
                return
