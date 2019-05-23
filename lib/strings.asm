	PROCESSOR 6502
	
	; STRLEN routine
	; A/X - pointer to string
	; Returns string length in A
STR_STRLEN	SUBROUTINE	
	sta reserved0
	stx reserved1
	ldy #$00
.loop
	lda (reserved0),y
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
	; pointer to string2 must already be in reserved2/3
	; Returns result in A
	sta reserved0
	stx reserved1
	ldy #$00
	sec
.loop
	lda (reserved0),y
	sbc (reserved2),y
	bne .exit
	lda (reserved0),y
	beq .exit
	iny
	bne .loop
.exit
	rts

	MAC strcmp
	pla
	sta reserved3
	pla
	sta reserved2
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
	; pointer to string2 must already be in reserved2/3
	; Returns result in A
	sta reserved0
	stx reserved1
	ldy #$00
.loop
	lda (reserved2),y
	sta (reserved0),y
	beq	 .exit
	iny
	bne .loop
.exit
	rts
	
	MAC strcpy
	pla
	sta reserved3
	pla
	sta reserved2
	pla
	tax
	pla
	jsr STR_STRCPY
	ENDM

STR_STNRCPY	SUBROUTINE
	; STRNCPY routine
	; A/X - pointer to string1
	; pointer to string2 must already be in reserved2/3
	; Returns result in A
	sta reserved0
	stx reserved1
	ldy #$00
.loop
	lda (reserved2),y
	sta (reserved0),y
	beq	 .exit
	iny
	bne .loop
.exit
	rts
	
	MAC strncpy
	pla
	sta reserved3
	pla
	sta reserved2
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
	lda (reserved0),y
	beq .end
	jsr STR_PET2SC
	sta (reserved2),y
	iny
	jmp .loop
.end:
	rts
	
	; This opcode is identical to textat
	; except that it translates the
	; input string to screencodes
	MAC stringat
	pla
	sta reserved3
	pla
	sta reserved2
	pla
	sta reserved1
	pla
	sta reserved0
	jsr STR_COPY_STRING_TO_SCREEN
	ENDM