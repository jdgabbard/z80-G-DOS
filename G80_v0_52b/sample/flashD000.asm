;----------------------------------------------------
; Standalone Flash Utility
; Copy 8003-C000 to ROM at 0003
;----------------------------------------------------

; Board Settings
BOARD           EQU     0
SERIAL          EQU     0
SIOA_BAUD       EQU     1
SIOB_BAUD       EQU     1
MAIN_LOOP	EQU	1	;fix me

;----------------------------------------------------
; Load dependencies
;----------------------------------------------------
INCLUDE	equates.asm
INCLUDE	bootloader/bootloader.h
INCLUDE	bootloader/putText.h

org     0D000h
;----------------------------------------------------
; Entry point
;----------------------------------------------------
flash:
        putText	"Copy RAM 8003-C000 to ROM at 0003"

	ld	hl,08003H		;source
	ld	de,00003H		;destination
	ld	bc,03FFDH		;byte count

	call	@at28Flash		;call the burner

	call	@putHex2
	call	@putSP
	putText	"Done"

	; ROM has changed - can't return
HCF:	putText	"Press reset to continue"
	halt
	jr	HCF

	END
