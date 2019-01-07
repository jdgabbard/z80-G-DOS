;----------------------------------------------------
; testSD
; v0.1 Jan2019 mnv80
;----------------------------------------------------
; Board Settings
BOARD           EQU     1
SERIAL          EQU     0
SIOA_BAUD       EQU     1
SIOB_BAUD       EQU     1
MAIN_LOOP	EQU	1	;fix me

org	08000h
	jp	main

INCLUDE equates.asm
INCLUDE	bootloader\bootloader.h
INCLUDE	bootloader\puttext.h
INCLUDE	sd\sd.asm

main:
	putLine	"SD Test Utility"
	call	sdInit

	call	sdSelect
	call	sdDeselect

	putLine	"Press any key to continue."
	call	@getc
	ret


		
