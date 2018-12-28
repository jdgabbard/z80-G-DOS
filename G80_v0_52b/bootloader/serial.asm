;----------------------------------------------------
; Serial Port Routines
; Should be common, in Monitor 
;----------------------------------------------------

IF NOT DEFINED serial.asm
serial.asm	EQU	1

;----------------------------------------------------
; initDART
; C - input - I/O address of control port
; A - working register
;
; set port to 57.6KB, one stop, no parity
;----------------------------------------------------
initDART:
	ld	b,8
	ld	a,000h
	out	(c),a
	ld	a,018h
	out	(c),a

	ld	a,004h
	out	(c),a
	ld	a,084h
	out	(c),a

	ld	a,003h
	out	(c),a
	ld	a,0C1h
	out	(c),a

	ld	a,005h
	out	(c),a
	ld	a,068h
	out	(c),a

	ret

;----------------------------------------------------
; testc  - test for RxRDY on SOI_A
; return 0=not ready, 1=ready
;----------------------------------------------------
testc:
        ld	a,00h			;test for RxRDY
        out	(SIOA_C),a
        in	a,(SIOA_C)
        and	01h

        ret

;----------------------------------------------------
; getc  - wait for RxRDY on SOI_A, return it in A
;----------------------------------------------------
getc:
        ld	a,00h			;wait for RxRDY
        out	(SIOA_C),a
        in	a,(SIOA_C)
        and	01h
        jr	z,getc

        in	a,(SIOA_D)		;read char

        ret

;----------------------------------------------------
; putc  - wait for TxRDY on SIO_A, send A to it
;----------------------------------------------------
putc:
	push	af
putc2:
        ld	a,00h			;wait for TxRDY
        out	(SIOA_C),a
        in	a,(SIOA_C)
        and	04h
        jr	z,putc2

	pop	af
        out	(SIOA_D),a		;write char

        ret

;----------------------------------------------------
; puts  - write a null terminated string to SIOA
; HL - input - pointer to start of string.  Altered.
;----------------------------------------------------
puts:
	ld	a,(hl)
	and	a
	ret	z

	call	putc
	inc	hl
	jr	puts

;----------------------------------------------------
; flushr - read and ignore until there is no more
; delay 100ms. check for character.
; read and repeat until none found
;----------------------------------------------------
flushr:
	push	af
	push	bc

flushr2:
	ld	bc,10
	call	delay
	
	call	testc
	and	a
	jr	z,flushr3

        call	getc
	jr	flushr2

flushr3:
	pop	bc
	pop	af
	ret

;----------------------------------------------------
; flushw - wait until any serial output is complete
;----------------------------------------------------
flushw:
	push	af

        ld	a,00h			;wait for TxRDY?
        out	(SIOA_C),a
        in	a,(SIOA_C)
        and	04h

	pop	af
	ret

;----------------------------------------------------
; flush - wait until any serial i/o is complete
;----------------------------------------------------
flush:
	call	flushw
	call	flushr
	ret

ENDIF
