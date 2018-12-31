;----------------------------------------------------
; Formatted Output Macro
;----------------------------------------------------

IF NOT DEFINED puttext.h
puttext.h	EQU	1

; macro to imbed text messages, adding CRLF
putLine		MACRO	putLineString	;code to print the debug string
		LOCAL	putLineMsg	;be sure we reference forward
		LOCAL	putLineCode	;be sure we reference forward

		jr	putLineCode	;jump over imbedded text
putLineMsg	
		DB	putLineString,CR,LF,00
putLineCode
		push	hl
		push	af

		ld	hl,putLineMsg
IF DEFINED NoJumpVectorMacros
		call	puts
ELSE
		call	@puts
ENDIF

		pop	af
		pop	hl
		ENDM

; macro to imbed text messages, not adding CRLF
putText		MACRO	putTextString	;code to print the debug string
		LOCAL	putTextMsg	;be sure we reference forward
		LOCAL	putTextCode	;be sure we reference forward

		jr	putTextCode	;jump over imbedded text
putTextMsg	
		DB	putTextString,00
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
