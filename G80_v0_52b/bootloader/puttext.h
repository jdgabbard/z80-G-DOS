;----------------------------------------------------
; Formatted Output Macro
;----------------------------------------------------

IF NOT DEFINED puttext.h
puttext.h	EQU	1

; macro to imbed text messages
putText		MACRO	putTextString	;code to print the debug string
		LOCAL	putTextMsg	;be sure we reference forward
		LOCAL	putTextCode	;be sure we reference forward

		jr	putTextCode	;jump over imbedded text
putTextMsg	
		DB	putTextString,CR,LF,00
putTextCode
		push	hl
		push	af

		ld	hl,putTextMsg
IF DEFINED NoJumpVectorMacros
		call	puts
ELSE
		call	@puts
ENDIF

		pop	af
		pop	hl
		ENDM

ENDIF
