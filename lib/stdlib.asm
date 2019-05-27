KERNAL_PRINTCHR	EQU $e716
KERNAL_GETIN EQU $ffe4	
INPUT_MAXCHARS EQU $06

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
; output on stack
; last char has 7. bit ON
	MAC word_to_string
.number			EQU R2
.negative 	 	EQU R8
.numchars		EQU R9
	lda #$00
	sta .negative ; is it negative?
	sta .numchars
	
	lda .number+1
	bpl .skip1
	; negate number remember it's negative
	twoscomplement R2
	lda #$01
	sta .negative
.skip1
	lda #10
	sta R0
	lda #$00
	sta R0+1
.loop
	jsr NUCL_DIVU16
	lda R4 ; remainder
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
	ldx R9
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
	sta (RA),y
	iny
	cpy R9
	bne .loop
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
	pla
	sta R2+1
	pla
	sta R2
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
	sta R3
	pla
	sta R2
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
	pla
	sta R3
	pla
	sta R2
	pla
	sta RB
	pla
	sta RA
	jsr STDLIB_OUTPUT_WORD
	ENDM
	
	; Output byte as decimal at col, row
	MAC bat
	pla
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
	
STDLIB_INPUT SUBROUTINE
	
.init:                                        
	ldx #INPUT_MAXCHARS
	lda #$00
.loop:
	sta input_str,x
	dex
	bpl .loop
	lda #$00
	sta input_counter
	lda #62
	jsr KERNAL_PRINTCHR
.again:
	lda #228
	jsr KERNAL_PRINTCHR
.input:
	jsr KERNAL_GETIN
	beq .input
	
	cmp #$14
	beq .input_delete

	cmp #$0d
	beq .input_done

	ldx input_counter
	cpx #INPUT_MAXCHARS
	beq .input
	
	jmp .input_filter

.reg:
    inc input_counter
	ldx input_counter
	dex
	sta input_str,x
	
.output:	
	pha
	lda #20
	jsr KERNAL_PRINTCHR
	pla
	jsr KERNAL_PRINTCHR
	jmp .again
	
.input_delete:
	pha
	lda input_counter
	bne .skip
	pla
	jmp .input
.skip:
	pla
	dec input_counter
	jmp .output
	
.input_filter:
	cmp #$2d
	beq .minus
	
	cmp #$3a
	bcc .ok1
	jmp .input
.ok1:
	cmp #$30
	bcs .ok2
	jmp .input
.ok2:
	jmp .reg
.minus:
	ldx input_counter
	bne *+5
	jmp .reg
	jmp .input
	
	
.input_done:
	lda #20
	jsr KERNAL_PRINTCHR
	lda input_counter
	jsr STDLIB_STRVAL
	lda input_err
	beq .input_success
	jmp .init
.input_success:
	rts
	
input_counter DC.B $00
input_str HEX 00 00 00 00 00 00 00
input_val HEX 00 00
input_err HEX 00

STDLIB_STRVAL SUBROUTINE
	tax
	beq .error
		
	lda #$00
	sta .digit_counter
	sta input_err
		
	lda input_str-1,x	
	cmp #$2d
	beq .error
	sec
	sbc #$30	
	sta R0
	lda #$00	
	sta R1	
	sta R2	
	sta R3
			
.loop:
	inc .digit_counter
	dex
	beq .done
	lda input_str-1,x
	cmp #$2d
	beq .minus
	sec
	sbc #$30
	sta R2
	lda #$00
	sta R3
	jsr .mult
	clc
	lda R2
	adc R0
	sta R0
	lda R3
	adc R1
	sta R1
	jmp .loop
	
.done:
	rts
.minus
	lda R0
	pha
	lda R1
	pha
	negw
	pla
	sta R1
	pla
	sta R0
	rts
	
.error
	lda #<.redo
	ldy #>.redo
	jsr STDLIB_PRINT
	inc input_err
	rts
	
.mult
	ldy .digit_counter
.mult10
	clc
	rol R2	; x2
	rol R2+1
    
    lda R2	; save to temp
    sta R4
    lda R2+1
    sta R4+1
    
    clc
	rol R2	; x2
	rol R2+1
	
	clc
	rol R2	; x2
	rol R2+1
        
	clc
    lda R4
    adc R2
    sta R2
    lda R4+1
    adc R2+1
    sta R2+1
    
    dey
    bne .mult10
    rts
	
.digit_counter HEX 00
.redo HEX 0d 52 45 44 4F 00

	MAC input
	jsr STDLIB_INPUT
	lda R0
	pha
	lda R1
	pha
	lda #13
	jsr KERNAL_PRINTCHR
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
