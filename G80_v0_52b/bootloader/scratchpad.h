;----------------------------------------------------
; Macros to allocate SCRATCHPAD RAM
;----------------------------------------------------
IF NOT DEFINED scratchpad.asm
scratchpad.asm	EQU	1

; RAM Allocation Macro ------------------------------
; Macro to allocate symbols for space in SCRATCHPAD RAM
; SCRATCHPAD starts at FFC0 and grows upward

spNextFree	DEFL	0FFC0h	;default location for scratchpad

scratchpad	MACRO	spName, spLen
spName		EQU	spNextFree
spNextFree	DEFL	spNextFree+spLen
		ENDM

scratchpadORG	MACRO	spOrigin
spNextFree	DEFL	spOrigin
		ENDM

ENDIF
