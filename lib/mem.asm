	PROCESSOR 6502

	; Fills memory area
	;
	; derived from Practical Memory Move Routines
	; by Bruce Clark 
	;
	; R0: destination address
	; A: fill byte
	; R2: number of bytes to copy
	
mem_memset	SUBROUTINE
.dst	EQU R0
.siz	EQU R2
		ldy #0
        ldx .siz+1
        beq .md2
.md1    
        sta (.dst),Y
        iny
        bne .md1
        inc .dst+1
        dex
        bne .md1
.md2    ldx .siz
        beq .md4
.md3
        sta (.dst),Y
        iny
        dex
        bne .md3
.md4    rts

	MAC memset
	IF !FPULL
	pla
	sta R1
	pla
	sta R0
	ELSE
	sta R0
	sty R1
	ENDIF
	pla
	sta R3
	pla
	sta R2
	pla
	jsr mem_memset
	ENDM
			
	; Copies memory area downwards
	; from Practical Memory Move Routines
	; by Bruce Clark
	;
	; R0: source address
	; R2: destination address
	; R4: number of bytes to copy
	;
	; overlapping safe downwards only
	
mem_memcpy	SUBROUTINE
.src	EQU R0
.dst	EQU R2
.siz	EQU R4
		ldy #0
        ldx .siz+1
        beq .md2
.md1    lda (.src),Y
        sta (.dst),Y
        iny
        bne .md1
        inc .src+1
        inc .dst+1
        dex
        bne .md1
.md2    ldx .siz
        beq .md4
.md3    lda (.src),Y
        sta (.dst),Y
        iny
        dex
        bne .md3
.md4    rts
	
	MAC memcpy
	IF !FPULL
	pla
	sta R1
	pla
	sta R0
	ELSE
	sta R0
	sty R1
	ENDIF
	pla
	sta R3
	pla
	sta R2
	pla
	sta R5
	pla
	sta R4
	jsr mem_memcpy
	ENDM
	
	; Copies memory area upwards
	;
	; from Practical Memory Move Routines
	; by Bruce Clark
	;
	; FROM = source start address
	; TO = destination start address
	; SIZE = number of bytes to move
	
mem_memshift SUBROUTINE
.FROM	EQU R0
.TO		EQU R2
.SIZE	EQU R4

	ldx .SIZE+1
    clc          ; start at the final pages of FROM and TO
 	txa
	adc .FROM+1
	sta .FROM+1
    clc
	txa
	adc .TO+1
	sta .TO+1
	inx
	ldy .SIZE
	beq .mu3
    dey
    beq .mu2
.mu1    
	lda (.FROM),y
	sta (.TO),y
	dey
	bne .mu1
.mu2      
    lda (.FROM),y
    sta (.TO),Y
.mu3     
	dey
    dec .FROM+1
    dec .TO+1
    dex
    bne .mu1
    rts
    
    MAC memshift
	IF !FPULL
	pla
	sta R1
	pla
	sta R0
	ELSE
	sta R0
	sty R1
	ENDIF
	pla
	sta R3
	pla
	sta R2
	pla
	sta R5
	pla
	sta R4
	jsr mem_memshift
	ENDM
	
