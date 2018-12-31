;----------------------------------------------------
; Standalone Intel-Hex Loader
;----------------------------------------------------

; Board Settings
BOARD           EQU     0
SERIAL          EQU     0
SIOA_BAUD       EQU     1
SIOB_BAUD       EQU     1
MAIN_LOOP	EQU	1	;fix me

;dependancies ---------------------------------------
INCLUDE equates.asm
INCLUDE	bootloader\bootloader.h
INCLUDE dcall.h

	org	0D000H
; download a new image ------------------------------
download:
	call	@ihLoad
	push	af
	call	@flush
	ld	hl,msg1
	call	@puts
	pop	af
	call	@put2Hex
	ld	hl,msg2
	call	@puts

; back to monitor -----------------------------------
	call	@getc
	ret

msg1:
	DB	CR,"Done (",00
msg2:
	DB	")",CR,"Press any key to continue",CR,00
