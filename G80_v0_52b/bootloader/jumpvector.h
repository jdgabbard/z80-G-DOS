;----------------------------------------------------
; Jump vector assignments for routines in the bootloader
;----------------------------------------------------
IF NOT DEFINED jumpvector.asm
jumpvector.asm	EQU	1

; Declare start of Jump Vector ----------------------
jumpVectorStart	MACRO
JUMP_VECTOR	EQU	$
		ENDM

; Jump Vector Allocation Macro ----------------------
; Macro to allocate and initialize slots in the jump vector
; Starts at JUMP_VECTOR and grows upward.  
; -Initializes the jump vector and makes @<symbol> PUBLIC
; -Maintains high water mark of jump vector

jumpVector	MACRO	jvNum, jvAddr
		LOCAL	jvorg			;in case this is called inline
jvorg		EQU	$

		ORG	JUMP_VECTOR+(3*jvNum)	;definitions can be in any order
@##jvAddr	jp	jvAddr
		PUBLIC	@##jvAddr

		ORG	jvorg
		ENDM

; Declare end of Jump Vector ------------------------
jumpVectorStop	MACRO	jvNum
		ORG	JUMP_VECTOR+(3*(jvNum+1))
		ENDM
ENDIF
