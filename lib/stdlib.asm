KERNAL_PRINTCHR	EQU $e716
KERNAL_GETIN EQU $ffe4	

RESERVED_STACK_POINTER DC.B 0
FILE_ERROR_MSG		   DC.B 0

; setup default mem layout for xc-basic runtime environment
STDLIB_MEMSETUP SUBROUTINE
	lda #$36
	sta $01
	rts

; print null-terminated petscii string
STDLIB_PRINT SUBROUTINE          
	sta $6f         ; store string start low byte
    sty $70         ; store string start high byte
    ldy #$00		; set length to 0
.1:
    lda ($6f),y     ; get byte from string
    beq .2		    ; exit loop if null byte [EOS] 
    jsr KERNAL_PRINTCHR
    iny             
    bne .1
.2:
	rts
	
; convert byte type decimal petscii
STDLIB_BYTE_TO_PETSCII SUBROUTINE
	ldy #$2f
  	ldx #$3a
  	sec
.1: iny
  	sbc #100
  	bcs .1
.2: dex
  	adc #10
  	bmi .2
  	adc #$2f
  	rts
  	
; print byte type as decimal
STDLIB_PRINT_BYTE SUBROUTINE
	ldy #$00
	sty reserved0 ; has a digit been printed?
	jsr STDLIB_BYTE_TO_PETSCII
	pha
	tya
	cmp #$30
	beq .skip                                      
	jsr KERNAL_PRINTCHR
	inc reserved0
.skip
	txa
	cmp #$30
	bne .printit
	ldy reserved0
	beq .skip2
.printit	
	jsr KERNAL_PRINTCHR
.skip2
	pla
	jsr KERNAL_PRINTCHR
	rts
	
	; opcode for print byte as decimal  	
	MAC stdlib_printb
	pla
	jsr STDLIB_PRINT_BYTE
	ENDM
		
; converts word to string
; input in reserved2
; output on stack
; last char has 7. bit ON
	MAC word_to_string
.number			EQU reserved2
.negative 	 	EQU reserved8
.numchars		EQU reserved9
	lda #$00
	sta .negative ; is it negative?
	sta .numchars
	
	lda .number+1
	bpl .skip1
	; negate number remember it's negative
	twoscomplement reserved2
	lda #$01
	sta .negative
.skip1
	lda #10
	sta reserved0
	lda #$00
	sta reserved0+1
.loop
	jsr NUCL_DIVU16
	lda reserved4 ; remainder
	pha
	inc .numchars
	lda .number
	ora .number+1
	bne .loop
	lda .negative		
	beq .skip2	
	lda #$fd
	pha
	inc .numchars
.skip2
	ENDM
		
; print word as petscii decimal
STDLIB_PRINT_WORD SUBROUTINE
	word_to_string
	ldx reserved9
.loop
	pla
	clc
	adc #$30
	jsr KERNAL_PRINTCHR
	dex
	bne .loop
	rts
	
STDLIB_OUTPUT_WORD SUBROUTINE
	word_to_string	
	ldy #$00
.loop
	pla
	clc
	adc #$30
	sta (reservedA),y
	iny
	cpy reserved9
	bne .loop
	rts
	
STDLIB_OUTPUT_BYTE SUBROUTINE
	ldy #$00
	sty reserved0 ; has a digit been printed?
	jsr STDLIB_BYTE_TO_PETSCII
	pha
	tya
	ldy #$00
	cmp #$30
	beq .skip                                  
	sta (reservedA),y
	inc reserved0
.skip
	txa
	cmp #$30
	bne .printit
	ldx reserved0
	beq .skip2
.printit	
	iny
	sta (reservedA),y
.skip2
	pla
	iny
	sta (reservedA),y
	rts
	
STDLIB_OUTPUT_FLOAT SUBROUTINE
	jsr FOUT
	ldx #$00
	lda $0100
	cmp #$20
	bne .doprint
	inx	
.doprint
	ldy #$00
.loop:	
	lda $0100,x
	beq .end
	sta (reservedA),y
	inx
	iny
	jmp .loop
.end
	rts
	
	; opcode for print word as decimal  	
	MAC stdlib_printw
	pla
	sta reserved2+1
	pla
	sta reserved2
	jsr STDLIB_PRINT_WORD
	ENDM

	MAC stdlib_putstr
    pla
    tay
    pla
    jsr STDLIB_PRINT
	ENDM

	MAC stdlib_putchar
    pla
    jsr KERNAL_PRINTCHR
	ENDM
		
	MAC textat
	pla
	sta reserved3
	pla
	sta reserved2
	pla
	sta reserved1
	pla
	sta reserved0
	ldy #$00
.loop:
	lda (reserved0),y
	beq .end
	sta (reserved2),y
	iny
	jmp .loop
.end:
	ENDM
	
	; Output integer as decimal at col, row
	MAC wat
	pla
	sta reserved3
	pla
	sta reserved2
	pla
	sta reservedB
	pla
	sta reservedA
	jsr STDLIB_OUTPUT_WORD
	ENDM
	
	; Output byte as decimal at col, row
	MAC bat
	pla
	tax
	pla
	sta reservedB
	pla
	sta reservedA
	txa
	jsr STDLIB_OUTPUT_BYTE
	ENDM
	
	; Output float as decimal at col, row
	MAC fat
	basicin
	pullfac
	pla
	sta reservedB
	pla
	sta reservedA
	jsr STDLIB_OUTPUT_FLOAT
	basicout
	ENDM

STDLIB_RND SUBROUTINE

	lda random+1
	sta temp1
	lda random
	asl
	rol temp1
	asl
	rol temp1
	clc
	adc random
	pha
	lda temp1
	adc random+1
	sta random+1
	pla
	adc #$11
	sta random
	lda random+1
	adc #$36
	sta random+1
	rts

temp1:   DC.B $5a
random:  DC.B %10011101,%01011011

	MAC seed_rnd
	lda $a1
	sta random
	lda $a2
	sta random+1
	ENDM
