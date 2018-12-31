;----------------------------------------------------
; Formatted Serial Output Routines
;----------------------------------------------------

IF NOT DEFINED format.asm
format.asm	EQU	1

;get4Hex-----------------------------------------
; getc 4 hex digits to bc
; C set if character is valid, clear otherwise
get4Hex:
	push	af		;uses af

	call	get2Hex		;status in C
	jr	nc,get4HexRet	;fail
	ld	b,a

	call	get2Hex		;status in C
	jr	nc,get4HexRet	;fail
	ld	c,a

get4HexRet:
	pop	af		;uses af
	ret


;get2Hex-----------------------------------------
; return binary value in A
; C set if character is valid, clear otherwise
get2Hex:
	push	bc		;uses bc

	call	get1Hex		;nybble 1
	jr	nc,get2HexRet
	sla	a		;shift left zero fill
	sla	a
	sla	a
	sla	a
	ld	b,a

	call	get1Hex		;nybble 2
	jr	nc,get2HexRet

	or	b		;join to nybble 1
	ld	a,b

get2HexRet:
	pop	bc		;uses bc
	ret


;get1Hex-----------------------------------------
; get and echo one hex digit
; return binary value in A
; C set if character is valid, clear otherwise
get1Hex:
	call	getc
	call	putc		;tbd - move inside getc

	sub	30h		;0 <= c <= 9 ?
	jr	c,get1HexErr
	cp	0Ah
	ret	c

	sub	07h		;A <= c <= F ?
	jr	c,get1HexErr
	cp	10h
	ret	c

	sub	20h		;a <= c <= a ?
	jr	c,get1HexErr
	cp	10h
	ret	c
	; fall through

get1HexErr:			;return with C clear
	scf			
	ccf
	ret

;put4Hex-----------------------------------------
; putc BC in upper case hex
put4Hex:
	push	af

	ld	a,b
	call	put2Hex
	ld	a,c
	call	put2Hex

	pop	af
	ret

;put2Hex-----------------------------------------
; putc A in upper case hex
put2Hex:
	push	af
	rra
	rra
	rra
	rra
	call	put1Hex

	pop	af
	call	put1Hex
	
	ret

;put1Hex-----------------------------------------
; putc lower half of A in upper case hex
put1Hex:
	and	0Fh
	add	a,30h
	cp	3Ah
	jr	c,put1Hex1
	add	a,07h
put1Hex1:
	call	putc

	ret

;putRegs----------------------------------------
putRegs:
        push	hl			;to restore on exit
        push	bc			;
        push	af			;

        push	hl			;working copies used before exit
        push	bc			;
        push	af			;

	ld	hl,putRegs_m
	call	puts

        pop	bc			;AF
        call	put4Hex
        call	putSP

        pop	bc			;BC
        call	put4Hex
        call	putSP

        ld	b,d			;DE
	ld	c,e
        call	put4Hex
        call	putSP

	pop	bc			;HL
        call	put4Hex
        call	putSP

	push	ix			;IX
	pop	bc
        call	put4Hex
        call	putSP

	push	iy			;IY
	pop	bc
        call	put4Hex
        call	putSP

	ld	hl,6			;SP
	add	hl,sp			;account for 6 bytes on stack
	ld	b,h			;
	ld	c,l			;
        call	put4Hex
        call	putSP

        ld	c,(hl)
	inc	hl
	ld	b,(hl)
        call	put4Hex
        call	putCR

        pop	af			;
        pop	bc			;
        pop	hl			;
        ret

putRegs_m:
	DB	"  AF   BC   DE   HL   IX   IY   SP   PC",CR,LF,00

;putc some useful constants ------------------------------
putSP:
	push	af
        ld	a,20H
        call	putc
	pop	af
        ret

putCR:
	push	af
        ld	a,0Dh
        call	putc
        ld	a,0Ah
        call	putc
	pop	af
        ret

ENDIF
