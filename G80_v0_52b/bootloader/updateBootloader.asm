;----------------------------------------------------
; Utility to update the bootloader
; call at 8000
;----------------------------------------------------
; Board Settings
BOARD           EQU     0
SERIAL          EQU     0
SIOA_BAUD       EQU     1
SIOB_BAUD       EQU     1
MAIN_LOOP	EQU	1	;fix me

	org	08000H
	jp	updateBootLoader

;dependencies ---------------------------------------
; no calls through jumpvector while we are updating it...
NoJumpVectorMacros	EQU	1

INCLUDE	equates.asm	
INCLUDE bootloader\bootloader.h
INCLUDE	bootloader\scratchpad.h	
INCLUDE bootloader\puttext.h
INCLUDE dcall.h

INCLUDE	bootloader\serial.asm	
INCLUDE	bootloader\delay.asm	
INCLUDE bootloader\ihex.asm
AT28_ROM_TOP	EQU	ROM_TOP		;allows at28 to flash reserved ROM
INCLUDE bootloader\at28.asm
INCLUDE bootloader\format.asm

updateBootLoader:			;enter here

; initialize ----------------------------------------
	di				;initialize interrupts
	ld	sp,newStack		;move stack to low RAM

	ld	c,SIOA_C		;initialize UARTs
	call	initDART
	ld	c,SIOB_C
	call	initDART

	ld	a,0			;clear RAM corresponding to
	ld	hl,BootLow+08000H	;the reserved ROM
	ld	de,BootLow+08001H
	ld	bc,BootHigh-BootLow-1
	ld	(hl),a
	ldir

	putLine	"Update Bootloader:"

; download a new bootloader image -------------------
download:
	call	ihLoad
	cp	0
	jp	z,flashit
	
	call	putCR
	putLine	"Download failure.  Retry..."
	jp	download

; if successful, flash the bootloader ---------------
flashit:
	call	putCR
	;putLine	"Flash..."

	ld	hl,BootLow+08000H
	ld	de,BootLow
	ld	bc,BootHigh-BootLow
	call	at28Flash
	cp	0
	jp	nz,unhook
	; fall through

; if successful, hook bootloader into reset sequence--
hook:
	;putLine	"Hook..."
	ld	hl,hookTemplate
	ld	de,0
	ld	bc,00003H
	call	at28Flash
	cp	0
	jr	nz,unhook
	putLine	"Update OK"
	; fall through

; if successful, back to the monitor ----------------
outahere:
	ld	bc,100
	call	delay

	jp	00100h			;use DCALL15 some day

;----------------------------------------------------
; serious problem!  try to minimize the grief
;----------------------------------------------------
unhook:
	putLine	"Update failure"
	ld	hl,unhookTemplate
	ld	de,0
	ld	bc,00003H
	call	at28Flash
	cp	0
	jr	z,outahere
	; fall through

	putLine	"Bootloader corrupted" 
	jp	outahere

;----------------------------------------------------
; templates used to hook and unhook bootloader to the reset sequence
; copy these to 0000h 
;----------------------------------------------------
unhookTemplate:
	jp	0100H			;fix me!

hookTemplate:
	jp	BootLow

;----------------------------------------------------
; stack moves here during the update
;----------------------------------------------------
stackSpace:
	DS	00100H
newStack:	EQU	$
