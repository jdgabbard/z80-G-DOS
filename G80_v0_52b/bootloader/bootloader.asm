;----------------------------------------------------
; Bootloader
;----------------------------------------------------
; Board Settings
BOARD           EQU     0
SERIAL          EQU     0
SIOA_BAUD       EQU     1
SIOB_BAUD       EQU     1
MAIN_LOOP	EQU	1	;fix me

;-------------------------------------------------------------------------------
; Reserved ROM for bootloader
;-------------------------------------------------------------------------------
BootLow		EQU	07B00H		;start of reserved high ROM
BootHigh	EQU	07F00H		;end of reserved high ROM
PUBLIC		BootLow			;push to external symbol file
PUBLIC		BootHigh		;push to external symbol file

;-------------------------------------------------------------------------------
; Bootloader Jump Vector
; Jump vector symbols will be written to the bootloader.public file
;-------------------------------------------------------------------------------
INCLUDE	bootloader\jumpvector.h

	org		BootLow	
	jumpVectorStart			;set origin of the jump vector

	jumpVector	 0, bootloader	;bootloader.asm
	jumpVector	 1, ihLoad	;ihex.asm
	jumpVector	 2, at28Flash	;at28.asm
	jumpVector	 3, initDART	;serial.asm
	jumpVector	 4, testc	;serial.asm
	jumpVector	 5, getc	;serial.asm
	jumpVector	 6, putc	;serial.asm
	jumpVector	 7, puts	;serial.asm
	jumpVector	 8, flush	;serial.asm
	jumpVector	 9, delay	;delay.asm
	jumpVector	10, delay1ms	;delay.asm
	jumpVector	11, putRegs	;format.asm
	jumpVector	12, putCR	;format.asm
	jumpVector	13, putSP	;format.asm
	jumpVector	14, putHex1	;format.asm
	jumpVector	15, putHex2	;format.asm

	jumpVectorStop	15		;set origin to end of jump vector


;dependencies ---------------------------------------
NoJumpVectorMacros EQU 1		;dont use jumpvector inside bootloader
INCLUDE equates.asm
INCLUDE bootloader\scratchpad.h
INCLUDE bootloader\putText.h
INCLUDE dcall.h

INCLUDE	bootloader\serial.asm	
INCLUDE bootloader\delay.asm
INCLUDE bootloader\ihex.asm
INCLUDE bootloader\at28.asm
INCLUDE bootloader\format.asm

bootloader:				;enter here from hard reset

; initialize ----------------------------------------
	di				;initialize interrupts
	ld	sp,STACK		;initialize stack

	ld	c,SIOA_C		;initialize UARTs
	call	initDART
	ld	c,SIOB_C
	call	initDART
	
; pause one second ----------------------------------
	putText	"Bootloader ..."

	ld	bc,100
	call	delay

; if no character ready continue to the monitor -----
	call	testc
	cp	0
	jp	z,monitor

; otherwise, download a new ROM ---------------------
download:
	call	ihLoad
	cp	0
	jp	nz,download
	;fall through

; if successful, flash the new ROM ------------------
; tbd - flash from download LWM to HWM
flashit:
	call	putCR

	ld	hl,8003h
	ld	de,0003h
	ld	bc,4000H

	call	at28Flash

	cp	0
	jp	nz,download

; and jump to the monitor ---------------------------
monitor:
	;jp	DCALL15			;init
	jp	00100H			;temporary - until G80S upgrades
