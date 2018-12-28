;----------------------------------------------------
; AT28C256 Flash Writer
;----------------------------------------------------
IF NOT DEFINED at28.asm
at28.asm	EQU	1

; return codes
AT28_OK		EQU	0	;successful
AT28_ERR_PARM	EQU	1	;bad parameter
AT28_ERR_VERIFY	EQU	2	;verification failed

; Scratchpad Memory Allocation ---------------------
scratchpadORG	0FFC0h		
scratchpad	AT28_SRC,	2
scratchpad	AT28_DST,	2
scratchpad	AT28_LEN,	2
scratchpad	AT28_INT,	2
scratchpad	AT28_RAM_UTIL,	32

;----------------------------------------------------
; at28Util - copy RAM buffer into ROM
; input from scratchpad
;
; while (bytecount != 0)
;    unlock ROM
;    repeat
;       LDI 
;    until (bytecount == 0) or (end of ROM page)
;    wait for write to complete
;    
; WARNING - 
; This routine MUST run from any location in RAM without
; relocation.  i.e. Only relative references within itself
; and only absolute references externally.
;
; This routine MUST execte from RAM. Attempting to use
; it from ROM will corrupt the ROM.  Copy to anywhere
; in RAM before executing.
;----------------------------------------------------

;----------------------------------------------------
; Protect against execution falling through here
;----------------------------------------------------
	halt

at28Util:
	ld	hl,(AT28_SRC)	;src
	ld	de,(AT28_DST)	;dest
	ld	bc,(AT28_LEN)	;len

at28UtilLoop:
	ld	a,b		;while (bytecount != 0)
	or	c
	ret	z

	ld	a,0AAH		;unlock ROM
	ld	(05555H),a
	ld	a,055h
	ld	(02AAAH),a
	ld	a,0A0H
	ld	(05555H),a

at28UtilCopy:
	ldi			;move bytes

	ld	a,b		;   until bytecount=0
	or	c
	jr	z,at28UtilWait

	ld	a,e		;   or we hit a ROM page boundary
	and	03FH
	jr	z,at28UtilWait

	jr	at28UtilCopy

at28UtilWait:			;wait for write to complete based on toggling
	ex	de,hl		;breaks if we write to the last ROM location!
	ld	a,(hl)		;(since hl will have been incremented into RAM)
	cp	(hl)
	ex	de,hl
	jr	nz,at28UtilWait

	jr	at28UtilLoop

at28UtilEnd:

;----------------------------------------------------
; at28Prologue
; HL - input - Source Address in RAM
; DE - input - Destination Address in ROM
; BC - input - Number of bytes to copy
;
; Save input parameters to scratchpad area
; Copy flash manager routine to scratchpad area
; Save flag indicating if interrupts are enabled
; Disable interrupts
;----------------------------------------------------
AT28_RELOC_LEN	EQU	(at28UtilEnd - at28Util + 1) & 0FFFEh

at28Prologue:
; Save input parameters -----------------------------
	ld	(AT28_SRC),hl	;src
	ld	(AT28_DST),de	;dest
	ld	(AT28_LEN),bc	;len

; Copy util to the scratchpad -----------------------
	ld	hl,at28Util	
	ld	de,AT28_RAM_UTIL
	ld	bc,AT28_RELOC_LEN

	ldir			

; Are interrupts currently enabled? -----------------
	ld	a,i		;IFF2 -> P/V, af->(SP)->bc, mask P/V
	push	af 		;all because there is no relative jump
	pop	bc		;based on P/V - only absolute.
	ld	a,c
	and	04h
	ld	(AT28_INT),a	;save interrupt state to restore later

	di			;disable interrupts

	ret

;----------------------------------------------------
; at28Epilog
; Restore interrupts to state stored in scratchpad
; Stomp on util code in the scratchpad
;----------------------------------------------------
at28Epilog:

; Stomp on scratchpad code --------------------------
	ld	a,0
	ld	(AT28_RAM_UTIL),a
	ld	hl,AT28_RAM_UTIL+1
	ld	de,AT28_RAM_UTIL
	ld	bc,AT28_RELOC_LEN
	ldir			

; Restore Interrupts --------------------------------
	ld	a,(AT28_INT)
	and	a
	jr	z,at28NoEI
	ei
at28NoEI:

	ret

;----------------------------------------------------
; at28Chk - check input parameters
; input parameters taken from scratchpad
; AF - output - 0=OK, 1=Parameter error
;
; Check:
; Start of RAM <= Source Address <= End of RAM
; Start of ROM <= Destination Address <= End of ROM
;----------------------------------------------------
at28Chk:
	and	a		;clear CY flag
	ld	a,AT28_OK	;default return OK

	ld	hl,(AT28_DST)	;dest starts in ROM?
	ld	de,ROM_BOT
	sbc	hl,de
	jr	c,at28ChkFail

	IF DEFINED AT28_ROM_TOP	;dest ends in ROM?
	ld	hl,AT28_ROM_TOP	;allow override by BurnBootLoader
	ELSE
	ld	hl,BootLow	;limit to non-reserved ROM by default
	ENDIF

	ld	de,(AT28_DST)
	sbc	hl,de
	ld	de,(AT28_LEN)
	sbc	hl,de
	jr	c,at28ChkFail

	ld	hl,(AT28_SRC)	;src starts in RAM?
	ld	de,RAM_BOT
	sbc	hl,de
	jr	c,at28ChkFail

	ld	hl,RAM_TOP	;src ends in RAM?
	ld	de,(AT28_SRC)
	sbc	hl,de
	ld	de,(AT28_LEN)
	sbc	hl,de
	jr	c,at28ChkFail

	ld	a,AT28_OK
	jr	at28ChkOK

at28ChkFail:
	ld	a,AT28_ERR_PARM	;bad parameter 
	;fall through

at28ChkOK:
	ret

;----------------------------------------------------
; at28Verify - compare RAM buffer to ROM buffer
; input parameters taken from scratchpad RAM
; AF - output - 0=OK.  2=Not OK
;----------------------------------------------------
at28Verify:
	ld	hl,(AT28_SRC)
	ld	de,(AT28_DST)
	ld	bc,(AT28_LEN)

at28Vloop:
	ld	a,b		;if (bytecount==0) exit 0
	or	c
	ret	z		;returns 0

	ld	a,(de)		;if (buffers not equal) exit non-zero
	sub	(hl)
	jr	nz,at28Vfail

	inc	de
	inc	hl
	dec	bc
	jr	at28Vloop

at28Vfail:
	ld	a,AT28_ERR_VERIFY ;verification failed
	ret

;----------------------------------------------------
; at28Flash - write RAM buffer to ROM buffer
; entry point if called from some other subsystem
;
; HL - input - Source Address in RAM
; DE - input - Destination Address in ROM
; BC - input - Number of bytes to copy
;
; AF - output -0 OK.  !=0 Not OK
; DE - output -ROM location of first difference, if any
; HL - output -RAM location of first difference, if any
;----------------------------------------------------
at28Flash:

; Get Organized -------------------------------------
	call	at28Prologue

; Check input parameters ----------------------------
	call	at28Chk	;can return error
	and	a
	jr	nz,at28DoEpilog

; Do the copy ---------------------------------------
	call	AT28_RAM_UTIL


; Verify the results --------------------------------
	call	at28Verify	;can return error

; Clean up stack ------------------------------------
at28DoEpilog:
	push	af		;get here with result in a
	call	at28Epilog
	pop	af

	ret
ENDIF
