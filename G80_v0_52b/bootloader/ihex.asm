;----------------------------------------------------
; Intel Hex Reader
;----------------------------------------------------

;----------------------------------------------------
; Allocate space in SCRATCHPAD memory
;----------------------------------------------------
	scratchpad	ihCount,	1
	scratchpad	ihType,		1
	scratchpad	ihCksum,	1
	scratchpad	ihEOF,		1
	scratchpad	ihResult,	1
	scratchpad	ihAddr,		2
	scratchpad	ihMinAddr,	2
	scratchpad	ihMaxAddr,	2

;----------------------------------------------------
; ihLoad - read intel hex records into RAM
;
; : count(2) addr(4) type(2) data(count) cksum(2) CR/LF/whatever
; repeat:
;    waitfor:    - CKSUM=0
;    count=read2
;    addr=(read4 || 8000h) 
;    type=read2
;    case type:
;       type=0 DATA - for i=0 to count copy data to RAM[addr+i]
;       type=1 EOF  - set flag to return success
;       default     - purge and return failure
;    read2 (for cksum)
;----------------------------------------------------
ihLoad:
	call	ihInit

ihLoop:
	;colon ----------------------------------------------
	call	ihWaitForColon
	ld	a,0			;at start of record:
	ld	(ihCksum),a		;   reset checksum value

	;count ----------------------------------------------
	call	ihRead2
	ld	(ihCount),a

	;addr -----------------------------------------------
	call	ihRead4
	set	7,h			;shift up into RAM space
	ld	(ihAddr),hl

	;type -----------------------------------------------
	call	ihRead2

ihCase0:				;case type=DATA
	cp	0
	jr	nz,ihCase1
	call	ihReadData
	jr	ihChecksum

ihCase1:				;case type=EOF
	cp	1
	jr	nz,ihCaseDefault
	ld	(ihEOF),a		;process cksum then we're done
	jr	ihChecksum

ihCaseDefault:				;case type=unsupported or cksum error
	jr	ihFail
	
	;cksum ----------------------------------------------
ihChecksum:
	call	ihRead2
	ld	a,(ihCksum)
	and	a
	jr	nz,ihFail		;return fail

	ld	a,(ihEOF)		;did we see EOF?
	and	a
	jr	z,ihLoop		;still going

	ld	a,(ihResult)		;return success
	ret

ihFail:
	call	flushr
	ld	a,1
	ld	(ihResult),a		;return fail
	ret


;----------------------------------------------------
; ihInit 
; set ihMinAddr=FFFF, ihMaxAddr=0000
;----------------------------------------------------
ihInit:
	ld	a,0

	; default return value
	ld	(ihResult),a

	; reset EOF flag
	ld	(ihEOF),a

	; reset Extended Segment Address
	ld	hl,0
	ld	(ihMaxAddr),hl
	dec	hl
	ld	(ihMinAddr),hl

	; print iHex prompt
	ld	hl,ihMsg1
	call	puts

	ret
ihMsg1:
	DB	CR,LF,"INTEL HEX LOAD:  ",CR,LF,0

;----------------------------------------------------
; ihWaitForColon
; read and echo characters until finding a :
;----------------------------------------------------
ihWaitForColon:
	call	getc
	call	putc
	cp	':'
	jr	nz,ihWaitForColon

	ret

;----------------------------------------------------
; ihRead1
; read and echo 1 hex digit
;----------------------------------------------------
ihRead1:
	call	getc
	call	putc

	sub	30h		;0 <= c <= 9 ?
	jr	c,ihRead1Err
	cp	0Ah
	ret	c

	sub	07h		;A <= c <= F ?
	jr	c,ihRead1Err
	cp	10h
	ret	c

	sub	20h		;a <= c <= a ?
	jr	c,ihRead1Err
	cp	10h
	ret	c
	; fall through

ihRead1Err:			;return non zero
	ld	a,0FFh
	ld	(ihResult),a
	ret
	

;----------------------------------------------------
; ihRead2
; read and echo 2 hex digits.  update cksum.
;----------------------------------------------------
ihRead2:
	push	bc		;uses bc

	call	ihRead1		;nybble 1
	sla	a		;shift left zero fill
	sla	a
	sla	a
	sla	a
	ld	b,a

	call	ihRead1		;nybble 2
	or	b		;join to nybble 1

	ld	b,a		;update cksum
	ld	a,(ihCksum)
	add	a,b
	ld	(ihCksum),a

	ld	a,b

	pop	bc		;uses bc
	ret

;----------------------------------------------------
; ihRead4
; read and echo 4 hex digits.  update cksum.
;----------------------------------------------------
ihRead4:
	push	af		;uses af

	call	ihRead2
	ld	h,a

	call	ihRead2
	ld	l,a

	pop	af		;uses af
	ret

;----------------------------------------------------
; ihReadData
; read (ihData) bytes to (ihAddr)
;----------------------------------------------------
ihReadData:
	ld	hl,(ihAddr)

	ld	a,(ihCount)
	and	a
	ret	z
	ld	c,a

ihReadData1:
	call	ihRead2
	ld	(hl),a
	inc	hl
	dec	c
	jr	nz,ihReadData1

	ret
