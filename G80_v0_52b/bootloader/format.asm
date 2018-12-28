;----------------------------------------------------
; Formatted Serial Output Routines
;----------------------------------------------------

IF NOT DEFINED format.asm
format.asm	EQU	1

;putHex2-----------------------------------------
; putc BC in upper case hex

putHex2:
	push	af

	ld	a,b
	call	putHex1
	ld	a,c
	call	putHex1

	pop	af
	ret

;putHex1-----------------------------------------
; putc A in upper case hex

putHex1:
	push	af
	rra
	rra
	rra
	rra
	and	0Fh
	call	putHalfHex

	pop	af
	and	0Fh
	call	putHalfHex
	
	ret

putHalfHex:
	add	a,30h
	cp	3Ah
	jr	c,putHalfHex1
	add	a,07h
putHalfHex1:
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
        call	putHex2
        call	putSP

        pop	bc			;BC
        call	putHex2
        call	putSP

        ld	b,d			;DE
	ld	c,e
        call	putHex2
        call	putSP

	pop	bc			;HL
        call	putHex2
        call	putSP

	push	ix			;IX
	pop	bc
        call	putHex2
        call	putSP

	push	iy			;IY
	pop	bc
        call	putHex2
        call	putSP

	ld	hl,6			;SP
	add	hl,sp			;account for 6 bytes on stack
	ld	b,h			;
	ld	c,l			;
        call	putHex2
        call	putSP

        ld	c,(hl)
	inc	hl
	ld	b,(hl)
        call	putHex2
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
