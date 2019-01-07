;-------------------------------------------------------------------------------
; SD I/O Routines
; To support SPI transfers according to SD Physical Layer Simplified Specification
;
; Dependencies:
; 8255 PIO addresses as defined in equates.asm
; PIO already initialized to A=Input, B=Input, C=Output Mode 0
; B2 connected to SDMISO
; C1 connected to SDMOSI
; C2 connected to SDSCK
; C3 connected to SDCS
;
; Setup - once only:
;	call	sdInit
;	
; For each transfer:
;	call	sdSelect
;	call	spiTransfer as required
;	call	sdDeselect
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; SPI Settings
;-------------------------------------------------------------------------------
spiMODE		EQU	0		;compile for the mode you want

spiCPOL		EQU	(spiMODE >> 1)	;clock polarity
spiCPHA		EQU	(spiMODE & 1)	;clock phase

;-------------------------------------------------------------------------------
; sdInit
;-------------------------------------------------------------------------------
sdInit:
	push	af
	call	sdDeselect
	call	spiInit
	pop	af
	ret

;-------------------------------------------------------------------------------
; sdSelect
; sdDeselect
;-------------------------------------------------------------------------------
sdSelect:
	push	af
	ld	a,006h
	out	(PIOCMD),a
	pop	af
	ret

sdDeselect:
	push	af
	ld	a,007h
	out	(PIOCMD),a
	pop	af
	ret

;-------------------------------------------------------------------------------
; spiInit
;-------------------------------------------------------------------------------
spiInit:
	call	spiCLKIdle
	ret

;-------------------------------------------------------------------------------
; spiCLKHigh   - force CLK high (internal)
; spiCLKLow    - force CLK low  (internal)
; spiCLKActive - assert CLK according to CPOL
; spiCLKIdle   - deassert CLK according to CPOL
;-------------------------------------------------------------------------------
spiCLKHigh:
	push	af
	ld	a,005h
	out	(PIOCMD),a
	pop	af
	ret

spiCLKLow:
	push	af
	ld	a,004h
	out	(PIOCMD),a
	pop	af
	ret

IF spiCPOL = 0
	spiCLKActive	EQU spiCLKHigh
	spiCLKIdle	EQU spiCLKLow
ELSE
	spiCLKActive	EQU spiCLKLow
	spiCLKIdle	EQU spiCLKHigh
ENDIF

;-------------------------------------------------------------------------------
; spiTransfer
; bit bang A to MOSI port according to selected SPI mode
; return value read in A
;-------------------------------------------------------------------------------
spiTransfer:
	push	bc		;scratch memory
	ld	b,a		;B=output register
	ld	c,0		;c=input register

	call	spiBitBang	;D7
	call	spiBitBang	;D6
	call	spiBitBang	;D5
	call	spiBitBang	;D4
	call	spiBitBang	;D3
	call	spiBitBang	;D2
	call	spiBitBang	;D1
	call	spiBitBang	;D0

	ld	a,c		;grab input
	pop	bc		;restore scratch memory
	ret

spiBitBang:
	rlc	b		;next output bit to C
	ld	a,1		;proto command
	rla			;merge C into command
	out	(PIOCMD),a	;output the bit

	call	spiCLKActive	;move the clock
IF spiCPHA = 0			;CPHA0 = read on the trailing edge
	call	spiCLKIdle
	in	a,(PIOB)
ELSE				;CPHA1 = read on the raising edge
	in	a,(PIOB)
	call	spiCLKIdle
ENDIF
	rrca			;bit2 to C
	rrca
	rrca
	rl	c		;merge C into result

	ret
	

