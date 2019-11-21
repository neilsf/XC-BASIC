	PROCESSOR 6502
	
	; STRLEN routine
	; A/X - pointer to string
	; Returns string length in A
STR_STRLEN	SUBROUTINE	
	sta R0
	stx R1
	ldy #$00
.loop
	lda (R0),y
	beq .exit
	iny
	bne .loop
.exit
	tya
	rts
	
	; Opcode for STRLEN
	MAC strlen
	pla
	tax
	pla
	jsr STR_STRLEN
	pha
	ENDM
	
STR_STRCMP	SUBROUTINE
	; STRCMP routine
	; A/X - pointer to string1
	; pointer to string2 must already be in R2/3
	; Returns result in A
	sta R0
	stx R1
	ldy #$00
	sec
.loop
	lda (R0),y
	sbc (R2),y
	bne .exit
	lda (R0),y
	beq .exit
	iny
	bne .loop
.exit
	rts

	; Opcode for strcmp
	MAC strcmp
	pla
	sta R3
	pla
	sta R2
	pla
	tax
	pla
	jsr STR_STRCMP
	pha
	lda #$00
	sbc #$00
	pha
	ENDM
	
STR_STRCPY	SUBROUTINE
	; STRCPY routine
	; A/X - pointer to string1
	; pointer to string2 in R2/3
	sta R0
	stx R1
	ldy #$00
.loop
	lda (R2),y
	sta (R0),y
	beq	 .exit
	iny
	bne .loop
.exit
	rts
	
	; Opcode for STRCPY
	MAC strcpy
	pla
	sta R3
	pla
	sta R2
	pla
	tax
	pla
	jsr STR_STRCPY
	ENDM

STR_STRNCPY	SUBROUTINE
	; STRNCPY routine
	; A/X - pointer to string1
	; pointer to string2 in R2/3
	; Length in R4
	sta R0
	stx R1
	ldy #$00
.loop
	lda (R2),y
	sta (R0),y
	beq	 .exit
	iny
	cpy R4
	bne .loop
	lda #$00
	sta (R0),y
.exit
	rts
	
	; Opcode for strncpy
	MAC strncpy
	pla
	sta R4
	pla
	sta R3
	pla
	sta R2
	pla
	tax
	pla
	jsr STR_STRNCPY
	ENDM

	; PETSCII to screencode conversion
	; By Mace
STR_PET2SC	SUBROUTINE
	cmp #$20
	bcc .ddRev
	cmp #$60
	bcc .dd1
	cmp #$80
	bcc .dd2
	cmp #$a0
	bcc .dd3
	cmp #$c0
	bcc .dd4
	cmp #$ff
	bcc .ddRev
	lda #$7e
	bne .ddEnd
.dd2:
	and #$5f
	bne .ddEnd
.dd3:
	ora #$40
	bne .ddEnd
.dd4:	
	eor #$c0
	bne .ddEnd
.dd1:
	and #$3f
	bpl .ddEnd
.ddRev:
	eor #$80
.ddEnd:
	rts
	
STR_COPY_STRING_TO_SCREEN	SUBROUTINE
	ldy #$00
.loop:
	lda (R0),y
	beq .end
	jsr STR_PET2SC
	sta (R2),y
	iny
	jmp .loop
.end:
	rts
	
	; This opcode is identical to textat
	; except that it translates the
	; input string to screencodes
	MAC stringat
	pla
	sta R3
	pla
	sta R2
	pla
	sta R1
	pla
	sta R0
	jsr STR_COPY_STRING_TO_SCREEN
	ENDM
	
STR_STRPOS	SUBROUTINE
	; A/X - pointer to haystack
	; pointer to needle must already be in R2/3
	; Returns result in A
	sta R0
	stx R1
	ldx #$00
.again
	ldy #$00
.loop
	lda (R0),y	
	beq .notfound
	lda (R2),y
	beq .found
	cmp (R0),y
	bne	 .next
	iny
	bne .loop
	jmp .notfound		
.next
	inx
	inc R0
	bne .again
	inc R1
	jmp .again
.notfound
	lda (R2),y
	beq .found
	lda #$ff
	rts
.found
	txa
	rts
	
	; Opcode for strpos
	MAC strpos
	pla
	sta R3
	pla
	sta R2
	pla
	tax
	pla
	jsr STR_STRPOS
	pha
	ENDM
	
	; Opcode for input
	MAC input
	; mask address
	pla
	sta R1
	pla
	sta R0
	; max length
	pla
	sta R5
	; destination
	pla
	tay
	pla
	jsr STDLIB_STR_INPUT
	ENDM
	
str_default_mask
	HEX 20 21 22 23 24 25 26 27 28 29 2A 2B 2C 2D 2E 2F
	HEX 30 31 32 33 34 35 36 37 38 39 3A 3B 3C 3D 3E 3F
	HEX 40 41 42 43 44 45 46 47 48 49 4A 4B 4C 4D 4E 4F
	HEX 50 51 52 53 54 55 56 57 58 59 5A 5B 5C 5D 5E 5F
	HEX A0 A1 A2 A3 A4 A5 A6 A7 A8 A9 AA AB AC AD AE AF
	HEX B0 B1 B2 B3 B4 B5 B6 B7 B8 B9 BA BB BC BD BE BF
	HEX C0 C1 C2 C3 C4 C5 C6 C7 C8 C9 CA CB CC CD CE CF
	HEX D0 D1 D2 D3 D4 D5 D6 D7 D8 D9 DA DB DC DD DE DF
	HEX FF 00
	
	; Numeric value of a byte
	;
STR_VALB	SUBROUTINE
	; A/X: pointer to string
.ret	EQU	R2
.ptr	EQU R0
	jsr STR_STRLEN
	cmp #4
	bcc .length_ok
	jmp .invalid
.length_ok	
	tay
	dey
	bmi .invalid
	lda #$00
	sta .ret
	lda (.ptr),y
	jsr STR_CHARISNUMERIC
	bcc .invalid
	sbc #$30
	clc
	adc .ret
	sta .ret
	dey
	bmi .end
	lda (.ptr),y
	jsr STR_CHARISNUMERIC
	bcc .invalid
	sbc #$30
	tax
	lda btens,x
	clc
	adc .ret
	sta .ret
	dey
	bmi .end
	lda (.ptr),y
	jsr STR_CHARISNUMERIC
	bcc .invalid
	sbc #$30
	cmp #3
	bcs .invalid
	tax
	lda bthous,x
	clc
	adc .ret
	bcs .invalid
	rts
.end
	lda .ret
	rts
.invalid
	lda #$00
	rts
	
btens  DC.B 0, 10, 20, 30, 40, 50, 60, 70, 80, 90
bthous DC.B 0, 100, 200

STR_CHARISNUMERIC	SUBROUTINE
	; char in A
	; carry set means true
	cmp #$30
	bcc .false+1
	cmp #$3a
	bcs .false
	sec
	rts
.false
	clc
	rts

	; Numeric value of a signed word	
STR_VALW	SUBROUTINE
	; A/X: pointer to string
.ret	EQU	RA		
.ptr	EQU R8
.neg	EQU R4
.acc1	EQU R0
.acc2	EQU R2
	sta .ptr
	stx .ptr+1
	ldy #$00
	; reset temp regs
	sty .ret
	sty .ret+1
	sty .poft
	; check if negative
	lda (.ptr),y
	cmp #$2d
	bne .positive
	lda #$01
	sta .neg
	inc .ptr
	bne .positive
	inc .ptr+1
.positive
.cloop
	lda (.ptr),y
	beq .exit
	iny
	bne .cloop
.exit
	cpy #7
	bcc .length_ok
	jmp .invalid
.length_ok
.loop
	dey
	bmi .end
	lda (.ptr),y
	jsr STR_CHARISNUMERIC
	bcc .invalid
	sbc #$30
	sta .acc1
	lda #$00
	sta .acc1+1
	lda .poft
	tax
	lda lwone,x
	sta .acc2
	lda hwone,x
	sta .acc2+1
	jsr NUCL_MUL16
	clc
	lda .acc1
	adc .ret
	sta .ret
	lda .acc1+1
	adc .ret+1
	sta .ret+1
	bmi .invalid 
	inc .poft
	jmp .loop
	
.end
	lda .neg
	beq .skip
	twoscomplement RA
.skip	
	lda .ret
	ldx .ret+1
	rts
.invalid
	lda #$00
	ldx #$00
	rts
.poft 	DC.B 0

lwone	DC.B 1	
lwten	DC.B 10	
lwhund	DC.B 100	
lwthou	DC.B <1000	
lwtthou	DC.B <10000

hwone	DC.B 0	
hwten	DC.B 0	
hwhund	DC.B 0	
hwthou	DC.B >1000	
hwtthou	DC.B >10000

	MAC valw
	pla
	tax
	pla
	jsr STR_VALW
	pha
	txa
	pha
	ENDM
	
	MAC valb
	pla
	tax
	pla
	jsr STR_VALB
	pha
	ENDM
	
	MAC valf
	basicin
	pla
	sta $23
	tax
	pla
	sta $22
	jsr STR_STRLEN
	jsr STRVAL
	pushfac
	basicout
	ENDM
	
