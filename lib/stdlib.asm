
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
	sty R0 ; has a digit been printed?
	jsr STDLIB_BYTE_TO_PETSCII
	pha
	tya
	cmp #$30
	beq .skip                                      
	jsr KERNAL_PRINTCHR
	inc R0
.skip
	txa
	cmp #$30
	bne .printit
	ldy R0
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
; input in R2
; output on stdlib_string_workspace (backwards)
; number of chars in X
word_to_string SUBROUTINE
;.number		EQU R2
;.negative 	 	EQU R8
;.numchars		EQU R9
	lda #$00
	sta R8 ; is it negative?
	sta R9
	
	lda R2+1
	bpl .skip1
	; negate number remember it's negative
	twoscomplement R2
	inc R8
.skip1
	lda #10
	sta R0
	lda #$00
	sta R0+1
.loop
	jsr NUCL_DIVU16
	lda R4 ; remainder
	ldx R9
	sta.wx stdlib_string_workspace
	inc R9
	lda R2
	ora R2+1
	bne .loop
	lda R8		
	beq .skip2	
	lda #$fd
	inx
	sta.wx stdlib_string_workspace
.skip2
	rts
		
; print string workspace using KERNAL
; in number of chars in X
stdlib_print_string_workspace SUBROUTINE
.loop
	lda.wx stdlib_string_workspace
	clc
	adc #$30
	jsr KERNAL_PRINTCHR
	dex
	bpl .loop
	rts
		
; print word as petscii decimal
STDLIB_PRINT_WORD SUBROUTINE
	jsr word_to_string
	jsr stdlib_print_string_workspace
	rts
	
STDLIB_OUTPUT_WORD SUBROUTINE
	jsr word_to_string	
	ldy #$00
.loop
	lda.wx stdlib_string_workspace
	clc
	adc #$30
	sta (RA),y
	iny
	dex
	bpl .loop
	rts
	
; converts word to string
; input in R2
; output on stdlib_string_workspace (backwards)
; number of chars in X
long_to_string SUBROUTINE
;.number		EQU R4
;.negative 	 	EQU RA
;.numchars		EQU RB
	lda #10
	sta R7
	lda #$00
	sta R7+1
	sta R7+2
	sta RA
	sta RB
	
	lda R4 + 2
	bpl .loop
	; negate number and remember it's negative
	twoscomplementl R4
	inc RA
.loop
	jsr NUCL_DIVU24
	lda R0 ; remainder
	ldx RB
	sta.wx stdlib_string_workspace
	inc RB
	lda R4
	ora R4+1
	ora R4+2
	bne .loop
	lda RA		
	beq .skip2	
	lda #$fd
	inx
	sta.wx stdlib_string_workspace
.skip2
	rts
	
; print word as petscii decimal
STDLIB_PRINT_LONG SUBROUTINE
	jsr long_to_string
	jsr stdlib_print_string_workspace
	rts
	
STDLIB_OUTPUT_BYTE SUBROUTINE
	ldy #$00
	sty R0 ; has a digit been printed?
	jsr STDLIB_BYTE_TO_PETSCII
	pha
	tya
	ldy #$00
	cmp #$30
	beq .skip                                  
	sta (RA),y
	inc R0
.skip
	txa
	cmp #$30
	bne .printit
	ldx R0
	beq .skip2
.printit	
	iny
	sta (RA),y
.skip2
	pla
	iny
	sta (RA),y
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
	sta (RA),y
	inx
	iny
	jmp .loop
.end
	rts
	
	; opcode for print word as decimal  	
	MAC stdlib_printw
	IF !FPULL
	pla
	sta R3
	pla
	sta R2
	ELSE
	sta R2
	sty R3
	ENDIF
	jsr STDLIB_PRINT_WORD
	ENDM
	
	; opcode for print word as decimal  	
	MAC stdlib_printl
	IF !FPULL
	pla
	sta R4+2
	pla
	sta R4+1
	pla
	sta R4
	ELSE
	sta R4
	sty R4+1
	stx R4+2
	ENDIF
	jsr STDLIB_PRINT_LONG
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
	IF !FPULL
	pla
	sta R3
	pla
	sta R2
	ELSE
	sta R2
	sty R3
	ENDIF
	pla
	sta R1
	pla
	sta R0
	ldy #$00
.loop:
	lda (R0),y
	beq .end
	sta (R2),y
	iny
	jmp .loop
.end:
	ENDM
	
	; Output integer as decimal at col, row
	MAC wat
	IF !FPULL
	pla
	sta R3
	pla
	sta R2
	ELSE
	sta R2
	sty R3
	ENDIF
	pla
	sta RB
	pla
	sta RA
	jsr STDLIB_OUTPUT_WORD
	ENDM
	
	; Output byte as decimal at col, row
	MAC bat
	IF !FPULL
	pla
	ENDIF
	tax
	pla
	sta RB
	pla
	sta RA
	txa
	jsr STDLIB_OUTPUT_BYTE
	ENDM
	
	; Output float as decimal at col, row
	MAC fat
	basicin
	pullfac
	pla
	sta RB
	pla
	sta RA
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
	
	; LFSR 24-bit pseudo-random generator
	; by Brad Smith
	; 
STDLIB_RND24 SUBROUTINE
	; rotate the middle byte left
	ldy random+1 ; will move to seed+2 at the end
	; compute seed+1 ($1B>>1 = %1101)
	lda random+2
	lsr
	lsr
	lsr
	lsr
	sta random+1 ; reverse: %1011
	lsr
	lsr
	eor random+1
	lsr
	eor random+1
	eor random+0
	sta random+1
	; compute seed+0 ($1B = %00011011)
	lda random+2
	asl
	eor random+2
	asl
	asl
	eor random+2
	asl
	eor random+2
	sty random+2 ; finish rotating byte 1 into 2
	sta random+0
	rts

temp1:   DC.B $5a
random:  DS.B 3

stdlib_string_workspace: DS.B 8

	MAC seed_rnd
	lda $a0
	sta random
	lda $a1
	sta random+1
	lda $a2
	sta random+2
	ENDM
