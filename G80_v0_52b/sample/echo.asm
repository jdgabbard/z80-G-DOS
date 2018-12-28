;----------------------------------------------------
; Test serial i/o routines
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
INCLUDE equates.asm
INCLUDE	bootloader\bootloader.h
INCLUDE bootloader\putText.h

org     08000h
;----------------------------------------------------
; Entry point
;----------------------------------------------------
        putText	"Enter text to echo.  Press reset to exit."
loop:
        call	@getc
        call	@putc
	jr	loop

	END
