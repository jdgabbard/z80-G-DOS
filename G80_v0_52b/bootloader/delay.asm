;----------------------------------------------------
; Spin-loop delay routines
; Should be common, in Monitor 
;----------------------------------------------------
IF NOT DEFINED delay.asm
delay.asm	EQU	1

;----------------------------------------------------
; delay - spin loop for variable (bc) time 
;----------------------------------------------------
delay:
	push	af
	push	bc
delayloop:
	call	delay1ms
	dec	bc
	ld	a,b
	and	a
	jr	nz,delayloop
	ld	a,c
	and	a
	jr	nz,delayloop

	pop	bc
	pop	af
	ret

;----------------------------------------------------
; delay1ms - spin loop for 1ms
; at 6MHz that's about 6070 T-states
; this totals 6105 T-states
;----------------------------------------------------
delay1ms:				;17T for the call to get here
	push	bc			;11T
	ld	b,90			; 7T

delay_1ms1:
	call	delay100us
	djnz	delay_1ms1		;605T*10=6050T

	pop	bc			;10
	ret				;10T

;----------------------------------------------------
; delay100us - spin loop for 100us
; at 6MHz that's about 607 T-states
; this totals 605 T-states
;----------------------------------------------------
delay100us:				;17T for the call to get here
	push	bc			;11T
	ld	b,41			; 7T

delay_100us1:
	djnz	delay_100us1		;13T*42=546T

	nop				; 4T
	pop	bc			;10
	ret				;10T

;----------------------------------------------------
; delay10us - spin loop for 10us
; at 6MHz that's about 61 T-states
; this totals 66 T-states
;----------------------------------------------------
delay10us:				;17T for the call to get here

	ex	(sp),hl			;19T
	ex	(sp),hl			;19T

	ret				;10T

ENDIF
