; ---------------------------------------------------------
; XC=BASIC
;
; Standard library for Commodore VIC-20
; ---------------------------------------------------------

; KERNAL routines
KERNAL_SETNAM		EQU $ffbd
KERNAL_SETLFS		EQU $ffba
KERNAL_LOAD			EQU $ffd5
KERNAL_SAVE			EQU $ffd8
KERNAL_PLOT			EQU $fff0
KERNAL_PRINTCHR		EQU $e742
KERNAL_GETIN 		EQU $ffe4	
KERNAL_SCREEN_PTR	EQU $0288

; Storage space to save SP 
STDLIB_STACK_POINTER DC.B 0
; Storage space to save File error no
FILE_ERROR_MSG		 DC.B 0
; Temporary storage
temp1:   DC.B $5a
; Random number
random:  DC.B %10011101,%01011011

; ---------------------------------------------------------
; Store stack pointer to memory
; ---------------------------------------------------------

	MAC stdlib_store_sp
	tsx
	stx STDLIB_STACK_POINTER
	ENDM

; ---------------------------------------------------------
; Restore stack pointer from memory
; ---------------------------------------------------------

	MAC stdlib_restore_sp
	ldx STDLIB_STACK_POINTER
	txs
	ENDM

; ---------------------------------------------------------
; Setup default mem layout for xc=basic runtime environment
; ---------------------------------------------------------

STDLIB_MEMSETUP SUBROUTINE
	rts
	
; ---------------------------------------------------------
; Seed randomizer with jiffy clock
; ---------------------------------------------------------
	
STDLIB_SEED_RND SUBROUTINE
	lda $a1
	sta random
	lda $a2
	sta random+1
	rts

; ---------------------------------------------------------
; Bank BASIC in
; Can be empty in platforms that don't support banking
; ---------------------------------------------------------

	MAC basicin
	ENDM

; ---------------------------------------------------------
; Bank BASIC out
; Can be empty in platforms that don't support banking
; ---------------------------------------------------------

	MAC basicout
	ENDM

; ---------------------------------------------------------
; Print null-terminated petscii string
; ---------------------------------------------------------

STDLIB_PRINT SUBROUTINE          
	sta R0          ; store string start low byte
    sty R1          ; store string start high byte
    ldy #$00		; set index to 0
.1:
    lda (R0),y      ; get byte from string
    beq .2		    ; exit loop if null byte [EOS] 
    jsr KERNAL_PRINTCHR
    iny             
    bne .1
.2:
	rts
	
; ---------------------------------------------------------
; Convert byte type to decimal petscii
; Input in A
; Output in YXA
; codebase64.org/doku.php?id=base:tiny_.a_to_ascii_routine
; ---------------------------------------------------------

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

; ---------------------------------------------------------
; Print byte type as decimal using KERNAL
; Input in A
; ---------------------------------------------------------

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
	
; ---------------------------------------------------------
; Convert signed word in R2 to PETSCII string
; output at $0100
; ---------------------------------------------------------
STDLIB_WORD_TO_STRING2 SUBROUTINE
.number			EQU R2
.numchars		EQU R9
.has_output		EQU RA

	lda #$00
	sta .has_output
	sta .numchars
	
	lda .number + 1	; load HB
	bpl .1			; is it positive?
	; no, negate number and output "-"
	twoscomplement R2
	lda #$2d
	sta stack
	inc .numchars
.1
	; loop through powers of 10
		
	lda #<10000
	sta R0
	lda #>10000
	sta R0 + 1
	jsr .cycle
	
	lda #<1000
	sta R0
	lda #>1000
	sta R0 + 1
	jsr .cycle
	
	lda #100
	sta R0
	lda #0
	sta R0 + 1
	jsr .cycle
	
	lda #10
	sta R0
	jsr .cycle
	rts
	
.cycle	
	jsr NUCL_DIVU16	; Divide. Result in R2, remainder in R4
	lda R2
	ora .has_output
	beq .2
	lda R2
	clc
	adc #$30
	ldy .numchars
	sta.wy stack
	inc .numchars
	inc .has_output
	; copy remainder to number
	lda R4
	sta .number	
	lda R4 + 1
	sta .number + 1
.2
	rts
	
; ---------------------------------------------------------
; Convert signed word in R2 to string on stack
; input in R2-R3
; output on stack
; last char has 7. bit ON
; ---------------------------------------------------------
		
STDLIB_WORD_TO_STRING SUBROUTINE	

.number			EQU R2
.negative 	 	EQU R8
.numchars		EQU R9
	
	pull_retaddr STDLIB_WORD_TO_STRING
	
	lda #$00
	sta .negative ; is it negative?
	sta .numchars
	
	lda .number+1
	bpl .skip1
	; negate number & remember it's negative
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

	push_retaddr STDLIB_WORD_TO_STRING

	rts

STDLIB_WORD_TO_STRING_tmp_retaddr
	HEX 00 00

; ---------------------------------------------------------
; Print integer as petscii decimal using KERNAL
; input in R2-R3
; ---------------------------------------------------------

STDLIB_PRINT_WORD SUBROUTINE
	jsr STDLIB_WORD_TO_STRING
	ldx R9
.loop
	pla
	clc
	adc #$30
	jsr KERNAL_PRINTCHR
	dex
	bne .loop
	rts
	
; ---------------------------------------------------------		
; Copy integer as petscii decimal
; input in R2-R3
; Output to address specified in RA-RB
; ---------------------------------------------------------
		
STDLIB_OUTPUT_WORD SUBROUTINE
	jsr STDLIB_WORD_TO_STRING	
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

; ---------------------------------------------------------
; Output byte 
; To screen at 
; Row in R8
; Col in R9
; String length returned in Y 
; ---------------------------------------------------------
	
STDLIB_OUTPUT_BYTE SUBROUTINE
	ldy #$00
	sty R0 ; has a digit been printed?
	jsr STDLIB_BYTE_TO_PETSCII
	pha
	tya
	ldy #$00
	cmp #$30
	beq .skip                                  
	sta.wy stack
	inc R0
.skip
	txa
	cmp #$30
	bne .printit
	ldx R0
	beq .skip2
.printit	
	iny
	sta.wy stack
.skip2
	pla
	iny
	sta.wy stack
	ldx #$00
	stx RA
	inx
	stx RB
	jsr STDLIB_TEXTAT
	rts
	
; ---------------------------------------------------------
; Output float 
; To screen at 
; Row in R8
; Col in R9
; String length returned in Y 
; ---------------------------------------------------------
	
STDLIB_OUTPUT_FLOAT SUBROUTINE
	jsr FOUT
	ldx #$00
	stx RA
	inx
	stx RB
	jsr STDLIB_TEXTAT
	rts
	
; ---------------------------------------------------------
; Output string pointed to by (RA)
; To screen at 
; Row in R8
; Col in R9
; String length returned in Y 
; ---------------------------------------------------------
		
STDLIB_TEXTAT	SUBROUTINE
	; Get screen top pointer
	lda #$00
	sta R6
	lda KERNAL_SCREEN_PTR
	sta R7
	; Add 22 x row
	ldx R8
.again	
	beq .0
	clc
	lda R6
	adc #22
	sta R6
	bcc .skip
	inc R7
.skip
	dex
	jmp .again 
.0
	; Add col
	lda R9
	clc
	adc R6
	sta R6
	bcc .1
	inc R7
	
.1	; Now we have a pointer in R6
	ldy #$00
.loop:
	lda (RA),y
	beq .end
	sta (R6),y
	iny
	jmp .loop
.end:
	rts
	
; ---------------------------------------------------------
; Set color of previously output string
;
; A	   The color
; (R6) Should still hold the start screen address
;      we only need to add an offset to get color
;      address
; Y	   Should still hold the char length
; ---------------------------------------------------------

STDLIB_SETCOLOR SUBROUTINE
	tax
	lda R7
	sec
	sbc KERNAL_SCREEN_PTR
	clc
	adc #$96 ; Color RAM starts at $9600 on the VIC-20
	sta R7
	txa
.loop
	sta (R6),y
	dey
	bpl .loop
	rts
	
; ---------------------------------------------------------	
; Ouput one character	
; Input in {1}	
; ---------------------------------------------------------	
	
	MAC stdlib_printc
	lda {1}
	jsr KERNAL_PRINTCHR
	ENDM
	
; ---------------------------------------------------------	
; Generate a somewhat random repeating sequence.  Uses
; a typical linear congruential algorithm
;      I(n+1) = (I(n)*a + c) mod m
; with m=65536, a=5, and c=13841 ($3611).  c was chosen
; to be a prime number near (1/2 - 1/6 sqrt(3))*m.
;
; Note that in general the higher bits are "more random"
; than the lower bits, so for instance in this program
; since only small integers (0..15, 0..39, etc.) are desired,
; they should be taken from the high byte RANDOM+1, which
; is returned in A.
; Taken from Stephen L. Judd's ffd2.com site :
; http://www.ffd2.com/fridge/math/rand1.s
; CLC Fix by Kweepa
; http://sleepingelephant.com/ipw-web/bulletin/bb/viewtopic.php?f=2&t=2304
; ---------------------------------------------------------	
	
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
	clc					; fix
	adc #$11
	sta random
	lda random+1
	adc #$36
	sta random+1
	rts

; ---------------------------------------------------------	
; Get one character from keyboard buffer
; Output in A
; ---------------------------------------------------------

	MAC stdlib_getin
	jsr KERNAL_GETIN
	ENDM

; ---------------------------------------------------------
; Load routine
; load 1: load at address stored in file
; load 0: load at a specified address 
; arguments on stack: address (if any), device no, 
; 					  filename_length, filename 
; ---------------------------------------------------------

	MAC stdlib_load
	; get filename and length
	pla
	tay
	pla
	tax
	pla
	jsr KERNAL_SETNAM
	; get device no
	pla ; discard high byte
	pla
	tax
	lda #$01
	ldy #{1}
	jsr KERNAL_SETLFS
	; get address
	IF {1} == 0
	pla
	tay
	pla
	tax
	ENDIF
	lda #$00
	jsr KERNAL_LOAD
	bcs .error
	lda #$00
.error
	sta FILE_ERROR_MSG
	ENDM

; ---------------------------------------------------------
; Save routine
; arguments on stack: address_end, address_start
;					  device no, filename_length, filename 
; ---------------------------------------------------------
	MAC stdlib_save
	; get filename and length
	pla
	tay
	pla
	tax
	pla
	jsr KERNAL_SETNAM
	; get device no
	pla ; discard high byte
	pla
	tax
	lda #$00
	ldy #$00
	jsr KERNAL_SETLFS
	; get address
	pla
	sta R1
	pla
	sta R0
	pla
	tay
	pla
	tax
	lda #R0
	jsr KERNAL_SAVE
	bcs .error
	lda #$00
.error
	sta FILE_ERROR_MSG
	ENDM

; ---------------------------------------------------------
; Input string from keyboard
; A/Y pointer to string
; R0/R1 pointer to mask
; R5 maxlength
; ---------------------------------------------------------

STDLIB_STR_INPUT	SUBROUTINE
.cnt	EQU R6
	sta R2
	sty R3
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
	cpy R5
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
	cmp (R0),y
	beq .ok
	iny
	pha
	lda (R0),y
	beq .invalid
	pla
	jmp .checkloop
.ok
	ldy .cnt
	sta (R2),y
	jsr KERNAL_PRINTCHR
	inc .cnt
	rts
.invalid
	pla
	jmp .loop
.end
	ldy .cnt
	lda #$00
	sta (R2),y
	lda #$ff
	sta $cc
	rts
