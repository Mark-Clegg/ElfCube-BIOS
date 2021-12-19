;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; IDE.ASM
;;
;; IDE Interface routines
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Registers                         ; Read          Write

IDE_Reg_Data               equ $00   ; Data          Data
IDE_Reg_Error_Feature      equ $01   ; Error         Feature
IDE_Reg_SectorCount        equ $02   ; -             Sector Count
IDE_Reg_StartSector        equ $03   ; -             Start Sector
IDE_Reg_CylinderLow        equ $04   ; -             Cylinder Low
IDE_Reg_CylinderHigh       equ $05   ; -             Cylinder High
IDE_Reg_HeadDevice         equ $06   ;               Head Device
IDE_Reg_Status_Command     equ $07   ; Status        Command
IDE_Reg_AltStatus_IRQReset equ $0e   ; Alt Status    IRQ Reset
IDE_Reg_ActiveStatus       equ $0f   ; Active Status -

;; Command Codes

IDE_Cmd_ReadSector         equ $20   ; Read Sector
IDE_Cmd_WriteSector        equ $30   ; Write Sector
IDE_Cmd_Identify           equ $ec   ; Identify drive.
IDE_Cmd_SetFeatures        equ $ef   ; Set Features

;; Head / Device Mask

IDE_HeadDevice_Head        equ $0f   ; Head Number
IDE_HeadDevice_Device      equ $10   ; Master (0) / Slave (1) Select
IDE_HeadDevice_SectorMode  equ $e0   ; 512 Bytes per Sector LBA mode

;; Features

IDE_Feature_8Bit           equ $01   ; 8 Bit Mode

;; Status Register BitField

IDE_SR_BSY                 equ $80   ; Busy
IDE_SR_DRDY                equ $40   ; Drive ready
IDE_SR_DF                  equ $20   ; Drive write fault
IDE_SR_DSC                 equ $10   ; Drive seek complete
IDE_SR_DRQ                 equ $08   ; Data request ready
IDE_SR_CORR                equ $04   ; Corrected data
IDE_SR_IDX                 equ $02   ; Index
IDE_SR_ERR                 equ $01   ; Error

;; Error Register BitField

IDE_ER_BBK                 equ $80   ; Bad block
IDE_ER_UNC                 equ $40   ; Uncorrectable data
IDE_ER_MC                  equ $20   ; Media changed
IDE_ER_IDNF                equ $10   ; ID mark not found
IDE_ER_MCR                 equ $08   ; Media change request
IDE_ER_ABRT                equ $04   ; Command aborted
IDE_ER_TK0NF               equ $02   ; Track 0 not found
IDE_ER_AMNF                equ $01   ; No address mark

                seg     bios_data

IDE_Model       ds      41           ; ASCIIZ String
IDE_SectorCount ds      4            ; 32 bit integer

                seg     bios_code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ide_waitready
;;
;; Wait for the IDE chipset to be READY
;;
;; Returns:
;; DF=0 - Success, D=IDE Status Register
;; DF=1 - Error, D=IDE Error Register
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                subroutine ide_waitready
ide_waitready   sex     r3                      ; Select Status Register
                out     IDE_Address
                db      IDE_Reg_Status_Command
                sex     r2

                ldi     $0                      ; Setup timeout counter
                plo     rf
                phi     rf

.wait           dec     rf                      ; Decrement timeout loop
                glo     rf
                bnz     .testFlags
                ghi     rf
                bnz     .testFlags

.ideError       sex     r3                      ; Return Error Register with DF=1
                out     IDE_Address
                db      IDE_Reg_Error_Feature
                sex     r2
                inp     IDE_Data
                smi     $00
                return

.testFlags      inp     IDE_Data                ; Read Status Register
                shr                             ; Check Error Flag
                bdf     .ideError
                shlc
                ani     IDE_SR_DRDY | IDE_SR_BSY
                smi     IDE_SR_DRDY
                bnz     .wait
                ldn     r2                      ; Return Status Register with DF=0
                adi     $00
                return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ide_checksectorvalid
;;
;; Internal routine, check that the sector number
;; pointed to by RD is in range
;;
;; Parameters
;; RD:      Pointer to 32 bit LBA Address
;;
;; Returns
;; DF=0 - Sector OK
;; DF=1 - Sector Number Out of Range
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                subroutine ide_checksectorvalid
ide_checksectorvalid
                ldi     high(IDE_SectorCount + 3)
                phi     rf
                ldi     low(IDE_SectorCount + 3)
                plo     rf
                inc     rd
                inc     rd
                inc     rd

                sex     rd                      ; Check the sector is in range
                ldn     rf
                sd
                dec     rf
                dec     rd
                ldn     rf
                sdb
                dec     rf
                dec     rd
                ldn     rf
                sdb
                dec     rf
                dec     rd
                ldn     rf
                sdb
                sex     r2
                return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ide_sendcommand
;;
;; Send a Read or Write command to the IDE Controller
;;
;; Parameters
;; Immediate: Command ($20 Read, $30 Write)
;; RD:        Address of a 28 bit LBA Address
;; RC.0:      Number of sectors
;; RC.1:      Drive, 0 = Master, 1 = Slave
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                subroutine ide_sendcommand
ide_sendcommand                                 ; Load LBA Address to drive registers
                lda     r6                      ; and send Read/Write Sector command
                stxd
                ldi     IDE_Reg_Status_Command
                stxd
                glo     rc                      ; Sector Count
                stxd
                ldi     IDE_Reg_SectorCount
                stxd
                ghi     rc                      ; Select LBA Mode ($e0)
                ani     $01                     ; Drive Number (RC.1 = 0 or 1)
                shl                             ; High LBA Byte (LSB 4 bits)
                shl                             ; into HeadDevice Register
                shl
                shl
                str     r2
                lda     rd
                ani     $0f
                ori     $e0
                or
                stxd
                ldi     IDE_Reg_HeadDevice
                stxd
                lda     rd
                stxd
                ldi     IDE_Reg_CylinderHigh
                stxd
                lda     rd
                stxd
                ldi     IDE_Reg_CylinderLow
                stxd
                ldn     rd
                stxd
                ldi     IDE_Reg_StartSector
                str     r2
                ldi     $06
.regSetupLoop   out     IDE_Address
                out     IDE_Data
                smi     $01
                bnz     .regSetupLoop
                dec     r2
                dec     rd
                dec     rd
                dec     rd

.waitDRQ        inp     IDE_Data                ; Wait for Data Ready
                shr
                bdf     .ideerror
                shlc
                ani     IDE_SR_DRQ
                bz      .waitDRQ
                return                          ; Return with DF = 0

.ideerror       sex     r3                      ; Return Error Register
                out     IDE_Address             ; and set DF = 1
                db      $01
                sex     r2
                inp     IDE_Data
                smi     $00
                return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ide_init
;;
;; Initialise the IDE chipset
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                subroutine ide_init
ide_init        call    ide_waitReady

                ldi     IDE_Cmd_SetFeatures         ; Send Set Features Command
                stxd
                ldi     IDE_Reg_Status_Command      ; Select Command Status Register
                stxd
                ldi     IDE_Feature_8Bit            ; Set 8 bit mode
                stxd
                ldi     IDE_Reg_Error_Feature       ; Select Feature Register
                stxd
                ldi     IDE_HeadDevice_SectorMode   ; Select LBA Mode
                stxd
                ldi     IDE_Reg_HeadDevice          ; Select Head Device Register
                str     r2
                out     IDE_Address
                out     IDE_Data
                out     IDE_Address
                out     IDE_Data
                out     IDE_Address
                out     IDE_Data
                dec     r2

                call    ide_waitReady

                ldi     IDE_Cmd_Identify            ; Send Identify Command
                stxd
                ldi     IDE_Reg_Status_Command      ; Select Command Status Register
                str     r2
                out     IDE_Address
                out     IDE_Data
                dec     r2

.waitDRQ        inp     IDE_Data                    ; Command / Status Register is already selected
                ani     IDE_SR_BSY | IDE_SR_DRQ     ; Read Status and wait for Data Request Ready
                smi     IDE_SR_DRQ
                bnz     .waitDRQ

                ldi     IDE_Reg_Data                ; Select Data Register
                str     r2
                out     IDE_Address
                dec     r2

                ldi     $36                         ; Read and ignore the first 54 bytes
                plo     re
.skip36         inp     IDE_Data
                dec     re
                glo     re
                bnz     .skip36

                ldi     high(IDE_Model)             ; Read the Model Name
                phi     rf
                ldi     low(IDE_Model)
                plo     rf
                sex     rf

                ldi     $14                         ; Next 40 bytes are the Model Number
                plo     re
.readModel      inc     rf
                inp     IDE_Data
                dec     rf
                inp     IDE_Data
                inc     rf
                inc     rf
                dec     re
                glo     re
                bnz    .readModel
                ldi     $0                          ; Zero Terminate the string
                str     rf

.trim           dec     rf                          ; Trim trailing spaces
                glo     rf
                smi     low(IDE_Model)
                bm      .trimmed
                ldn     rf
                smi     $20
                bnz     .trimmed
                str     rf
                br      .trim

.trimmed        ldi     $1a                         ; Read and ignore the next 26 bytes
                plo     re
                sex     r2
.skip1a         inp     IDE_Data
                dec     re
                glo     re
                bnz     .skip1a

                ldi     high(IDE_SectorCount+3)
                phi     rf
                ldi     low(IDE_SectorCount+3)
                plo     rf
                sex     rf

                ldi     $04                         ; Read the sector count
                plo     re
.readCount      inp     IDE_Data
                dec     rf
                dec     re
                glo     re
                bnz     .readCount

                sex     r2                          ; Read and ignore the remainder of the sector
                ldi     $c2
                plo     re
.skip184        inp     IDE_Data
                inp     IDE_Data
                dec     re
                glo     re
                bnz     .skip184

                return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ide_identity_string
;;
;; Returns
;; RE: Address of the ASCIIZ IDE Model String
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                subroutine ide_identity_string
ide_identity_string
                ldi     high(IDE_Model)
                phi     re
                ldi     low(IDE_Model)
                plo     re
                return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ide_sector_count
;;
;; Returns
;; RE: Address of the IDE Sector Count DWORD
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                subroutine ide_sector_count
ide_sector_count
                ldi     high(IDE_SectorCount)
                phi     re
                ldi     low(IDE_SectorCount)
                plo     re
                return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ide_read_sector
;;
;; Read sectors from the drive
;;
;; Parameters
;; RE:      Pointer to memory block to read the sector into
;; RD:      Pointer to 28 bit sector number
;; RC.0     Number of sectors to read
;; RC.1     Drive 0 = Master, 1 = Slave
;;
;; Returns
;; DF=0:    OK
;; DF=1:    D = IDE Error Register
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                subroutine  ide_read_sector
ide_read_sector call    ide_checksectorvalid
                lbdf     ide_fail_return

                call    ide_waitready           ; Wait for drive to be ready
                call    ide_sendcommand         ; and send Read/Write Sector command
                db      IDE_Cmd_ReadSector

                sex     r3                      ; Select Data Register
                out     IDE_Address
                db      IDE_Reg_Data

                ldi     $80
                plo     rf

                sex     re
.readData       inp     IDE_Data                ; Read sector (4 bytes at a time)
                inc     re
                inp     IDE_Data
                inc     re
                inp     IDE_Data
                inc     re
                inp     IDE_Data
                inc     re
                dec     rf
                glo     rf
                bnz     .readData

ide_rw_return   sex     r2
                call    ide_waitready           ; Wait for drive to be ready

                ghi     re                      ; Return RE to start of data
                smi     $02
                phi     re

                sex     r3                      ; return the IDE Error Register
                out     IDE_Address
                db      IDE_Reg_Error_Feature
                sex     r2
                inp     IDE_Data
ide_fail_return return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ide_write_sector
;;
;; Write sectors to the drive
;;
;; Parameters
;; RE:      Pointer to memory block to read the sector into
;; RD:      Pointer to 28 bit sector number
;; RC.0     Number of sectors to read
;; RC.1     Drive 0 = Master, 1 = Slave
;;
;; Returns
;; DF=0:    OK
;; DF=1:    D = IDE Error Register
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                subroutine  ide_write_sector
ide_write_sector
                call    ide_checksectorvalid
                bdf     ide_fail_return

                call    ide_waitready           ; Wait for drive to be ready
                call    ide_sendcommand         ; Load LBA Address to drive registers
                db      IDE_Cmd_WriteSector

                sex     r3                      ; Select Data Register
                out     IDE_Address
                db      IDE_Reg_Data

                ldi     $80
                plo     rf

                sex     re
.writeData      out     IDE_Data                ; Write sector (4 bytes at a time)
                out     IDE_Data
                out     IDE_Data
                out     IDE_Data
                dec     rf
                glo     rf
                bnz     .writeData

                lbr     ide_rw_return
