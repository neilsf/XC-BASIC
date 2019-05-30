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
	; pointer to string2 in reserved2/3
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

STR_STRNCPY	SUBROUTINE
	; STRNCPY routine
	; A/X - pointer to string1
	; pointer to string2 in reserved2/3
	; Length in reserved4
	sta reserved0
	stx reserved1
	ldy #$00
.loop
	lda (reserved2),y
	sta (reserved0),y
	beq	 .exit
	iny
	cpy reserved4
	bne .loop
	lda #$00
	sta (reserved0),y
.exit
	rts
	
	MAC strncpy
	pla
	sta reserved4
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
	
STR_STRPOS	SUBROUTINE
	; A/X - pointer to haystack
	; pointer to needle must already be in reserved2/3
	; Returns result in A
	sta reserved0
	stx reserved1
	ldx #$00
.again
	ldy #$00
.loop
	lda (reserved0),y	
	beq .notfound
	lda (reserved2),y
	beq .found
	cmp (reserved0),y
	bne	 .next
	iny
	bne .loop
	jmp .notfound		
.next
	inx
	inc reserved0
	bne .again
	inc reserved1
	jmp .again
.notfound
	lda (reserved2),y
	beq .found
	lda #$ff
	rts
.found
	txa
	rts
	
	MAC strpos
	pla
	sta reserved3
	pla
	sta reserved2
	pla
	tax
	pla
	jsr STR_STRPOS
	pha
	ENDM
	
STR_INPUT	SUBROUTINE
	; INPUT routine
	; A/Y pointer to string
	; R0/R1 pointer to mask
	; R5 maxlength
.cnt	EQU reserved6
	sta reserved2
	sty reserved3
	lda #$00
	sta $cc	; turn on cursor
	sta .cnt
.loop
	jsr KERNAL_GETIN
	beq .loop
	cmp #$14
	beq .delete
	cmp #$0d
	beq .end
	ldy .cnt
	cpy reserved5
	beq .loop
	jsr .checkmask	
	jmp .loop	
.delete 
	ldx .cnt
	beq .loop
 	dec .cnt
 	jsr KERNAL_PRINTCHR
 	jmp .loop
.checkmask
	ldy #$00
.checkloop
	cmp (reserved0),y
	beq .ok
	iny
	pha
	lda (reserved0),y
	beq .invalid
	pla
	jmp .checkloop
.ok
	ldy .cnt
	sta (reserved2),y
	jsr KERNAL_PRINTCHR
	inc .cnt
	rts
.invalid
	pla
	jmp .loop
.end
	ldy .cnt
	lda #$00
	sta (reserved2),y
	lda #$ff
	sta $cc
	rts
	
	MAC input
	; mask address
	pla
	sta reserved1
	pla
	sta reserved0
	; max length
	pla
	sta reserved5
	; destination
	pla
	tay
	pla
	jsr STR_INPUT
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
