	PROCESSOR 6502

	INCDIR "/home/neils/Workspace/XC-BASIC/examples/plazma/."
	SEG UPSTART
	ORG $0801
	DC.W next_line
	DC.W 2018
	HEX 9e
	IF prg_start
	DC.B [prg_start]d
	ENDIF
	HEX 00
next_line:
	HEX 00 00
	;--------------------
	ECHO "Memory information:"
	ECHO "==================="
	ECHO "BASIC loader: $801 -", *-1
library_start:

	PROCESSOR 6502
	LIST OFF	
		
; Pseudo-registers
	
R0	EQU $fb
R1	EQU $fc

R2	EQU $fd
R3	EQU $fe

R4	EQU $3f
R5	EQU $40

R6	EQU $41
R7	EQU $42

R8	EQU $43                              
R9	EQU $44

RA	EQU $45
RB	EQU $46

stack 		EQU $0100

; Floating point routines
MOVFM		EQU $bba2
CONUPK		EQU $ba8c
MOVMF		EQU $bbd4
FCOMP		EQU	$bc5b
FOUT		EQU $bddd
FOUTDIRECT	EQU $aabc
GIVAYF		EQU $b391
FACINX		EQU	$b1bf
FMULT		EQU $ba28
FDIV		EQU $bb0f
FADDT		EQU $b86a
FSUBT		EQU $b853
FRAND		EQU $e097
FABS		EQU $bc58
FSIN		EQU $e26b
FCOS		EQU $e264
FATN		EQU $e30e
FTAN		EQU $e2b4
BYTETOF		EQU $bc3c
SQR			EQU $bf71
SGN			EQU $bc39
STRVAL		EQU $b7b5

; KERNAL routines
SETNAM		EQU $ffbd
SETLFS		EQU $ffba
LOAD		EQU $ffd5
SAVE		EQU $ffd8
PLOT		EQU $fff0

	; Push a zero on the stack
	; EXAMINE REFS BEFORE CHANGING!
	MAC pzero
	lda #$00
	IF !FPUSH
	pha
	ENDIF
	ENDM
	
	; Push a one on the stack
	; EXAMINE REFS BEFORE CHANGING!
	MAC pone
	lda #$01
	IF !FPUSH
	pha
	ENDIF
	ENDM

	; Push one byte on the stack
	MAC pbyte
	lda {1}
	IF !FPUSH
	pha
	ENDIF
	ENDM

	; Push byte var on the stack
	MAC pbvar
	pbyte {1}
	ENDM

	; Push one byte as a word on the stack
	; TODO - is this deprecated?
	MAC pbyteasw
	lda {1}
	pha
	lda #$00
	pha
	ENDM

	; Push one word on the stack
	MAC pword
	IF !FPUSH
	lda #<{1}
	pha
	lda #>{1}
	pha
	ELSE
	lda #<{1}
	ldy #>{1}
	ENDIF
	ENDM
	
	; Push a float on the stack (floats go reversed!)
	MAC pfloat
	lda #{5}
	pha
	lda #{4}
	pha
	lda #{3}
	pha
	lda #{2}
	pha
	lda #{1}
	pha
	ENDM
	
	; Push one word variable on the stack
	MAC pwvar
	IF !FPUSH
	lda.w {1}
	pha
	lda.w {1}+1
	pha
	ELSE
	lda.w {1}
	ldy.w {1}+1
	ENDIF
	ENDM
	
	MAC psvar
	pwvar {1}
	ENDM
	
	; Push one float variable on the stack (floats go reversed!)
	MAC pfvar
	ldy #$04
.loop	
	lda.wy {1}
	pha
	dey
	bpl .loop
	ENDM

	;Push one byte variable (indexed) on the stack
	;Expects array index being on top of stack
	MAC pbarray
	IF !FPULL
	pla
	sta R1
	pla
	sta R0
	ELSE
	sta R0
	sty R1
	ENDIF
	lda #<{1}
	clc
	adc R0
	sta R0
	lda #>{1}
	adc R1
	sta R1
	ldy #$00
	lda (R0),y
	IF !FPUSH	
	pha
	ENDIF
	ENDM
	
	;Push one byte variable (indexed) on the stack
	;Expects array index being on top of stack
	;Used in case both variable and index are bytes
	MAC pbarray_fast
	IF !FPULL
	pla
	ENDIF
	tax
	lda.wx {1}
	IF !FPUSH
	pha
	ENDIF
	ENDM

	;Push one word variable (indexed) on the stack
	;Expects array index being on top of stack
	MAC pwarray
	IF !FPULL
	pla
	sta R1
	pla
	sta R0
	ELSE
	sta R0
	sty R1
	ENDIF
	lda #<{1}
	clc
	adc R0
	sta R0
	lda #>{1}
	adc R1
	sta R1
	IF !FPUSH
	ldy #$00
	lda (R0),y
	pha
	iny
	lda (R0),y
	pha
	ELSE
	ldy #$00
	lda (R0),y
	tax
	iny
	lda (R0),y
	tay
	txa
	ENDIF
	ENDM
	
	;Push one float variable (indexed) on the stack
	;Expects array index being on top of stack
	MAC pfarray
	pla
	sta R1
	pla
	sta R0
	lda #<{1}
	clc
	adc R0
	sta R0
	lda #>{1}
	adc R1
	sta R1
	ldy #$04
.loop	
	lda (R0),y
	pha
	dey
	bpl .loop
	ENDM

	MAC psvar
	pwvar {1}
	ENDM
	
	; Push address on stack
	MAC paddr
	pword {1}
	ENDM

	; Pull byte to variable
	MAC plb2var
	IF !FPULL
	pla
	ENDIF
	sta {1}
	ENDM

	; Pull word to variable
	MAC plw2var
	IF !FPULL
	pla
	sta {1}+1
	pla
	sta {1}
	ELSE
	sta {1}
	sty {1}+1
	ENDIF
	ENDM
	
	; Pull float to variable
	MAC plf2var
	pla
	sta {1}
	pla
	sta {1}+1
	pla
	sta {1}+2
	pla
	sta {1}+3
	pla
	sta {1}+4
	ENDM

	;Pull one byte variable (indexed)
	;Expects array index on top of stack
	MAC plbarray
	IF !FPULL
	pla
	sta R1
	pla
	sta R0
	ELSE
	sta R0
	sty R1
	ENDIF
	lda #<{1}
	clc
	adc R0
	sta R0
	lda #>{1}
	adc R1
	sta R1
	ldy #$00
	pla
	sta (R0),y
	ENDM	
	
	;Pull one byte variable (indexed)
	;Expects array index being on top of stack
	;
	;Used in case both variable and index are bytes
	MAC plbarray_fast
	IF !FPULL
	pla
	ENDIF
	tax
	pla
	sta.wx {1}
	ENDM
	
	;Pull one word variable (indexed)
	;Expects array index on top of stack
	MAC plwarray
	IF !FPULL
	pla
	sta R1
	pla
	sta R0
	ELSE
	sta R0
	sty R1
	ENDIF
	lda #<{1}
	clc
	adc R0
	sta R0
	lda #>{1}
	adc R1
	sta R1
	ldy #$01
	pla
	sta (R0),y
	dey
	pla
	sta (R0),y
	ENDM
	
	; Pull one float variable (indexed)
	; Expects array index on top of stack
	MAC plfarray
	IF !FPULL
	pla
	sta R1
	pla
	sta R0
	ELSE
	lda R0
	ldy R1
	ENDIF
	lda #<{1}
	clc
	adc R0
	sta R0
	lda #>{1}
	adc R1
	sta R1
	ldy #$00
	REPEAT 5	
	pla
	sta (R0),y
	iny
	REPEND
	ENDM
	
	; Move float on stack to FAC
	; Call basicin first!
	MAC pullfac
	tsx
	inx
	txa
	ldy #$01
	jsr MOVFM
	tsx
	REPEAT 5
	inx
	REPEND
	txs
	ENDM
	
	; Move float on stack to ARG
	; Call basicin first!
	MAC pullarg
	tsx
	inx
	txa
	ldy #$01
	jsr CONUPK
	tsx
	REPEAT 5
	inx
	REPEND
	txs
	ENDM
	
	; Move float in FAC to stack
	; Call basicin first!
	MAC pushfac
	ldx #<tmp_floatvar
	ldy #>tmp_floatvar
	jsr MOVMF
	lda tmp_floatvar+4
	pha
	lda tmp_floatvar+3
	pha
	lda tmp_floatvar+2
	pha
	lda tmp_floatvar+1
	pha
	lda tmp_floatvar
	pha
	ENDM
	
	; Compare two bytes on stack for less than
	MAC cmpblt
	IF !FPULL
	pla
	ENDIF
	sta R1
	pla
	cmp R1
	bcs .phf
	pone
	IF !FPUSH
	jmp *+6
	ELSE
	jmp *+5
	ENDIF
.phf: pzero 
	ENDM

	; Compare two bytes on stack for less than or equal
	MAC cmpblte
	IF !FPULL
	pla
	ENDIF
	sta R1
	pla
	cmp R1
	bcc .pht
	beq .pht
	pzero
	IF !FPUSH
	jmp *+6
	ELSE
	jmp *+5
	ENDIF
.pht: pone 
	ENDM

	; Compare two bytes on stack for greater than or equal
	MAC cmpbgte
	IF !FPULL
	pla
	ENDIF                 
	sta R1
	pla
	cmp R1
	bcs .pht
	pzero
	IF !FPUSH
	jmp *+6
	ELSE
	jmp *+5
	ENDIF
.pht: pone
	ENDM

	; Compare two bytes on stack for equality
	MAC cmpbeq
	IF !FPULL
	pla
	ENDIF                 
	sta R1
	pla
	cmp R1
	beq .pht
	pzero
	IF !FPUSH
	jmp *+6
	ELSE
	jmp *+5
	ENDIF
.pht: pone
	ENDM

	; Compare two bytes on stack for inequality
	MAC cmpbneq
	IF !FPULL
	pla
	ENDIF                 
	sta R1
	pla
	cmp R1
	bne .pht
	pzero
	IF !FPUSH
	jmp *+6
	ELSE
	jmp *+5
	ENDIF
.pht: pone
	ENDM

	; Compare two bytes on stack for greater than
	MAC cmpbgt
	IF !FPULL
	pla
	ENDIF                 
	sta R1
	pla
	cmp R1
	bcc .phf
	beq .phf
	pone
	IF !FPUSH
	jmp *+6
	ELSE
	jmp *+5
	ENDIF
.phf: pzero
	ENDM

	; Compare two words on stack for equality
	MAC cmpweq
	IF !FPULL
	pla
	sta R2
	pla
	sta R1
	ELSE
	sta R1
	sty R2
	ENDIF
	pla
	cmp R2
	bne .phf
	pla
	cmp R1
	bne .phf+1
	pone
	IF !FPUSH
	jmp *+7
	ELSE
	jmp *+6
	ENDIF
.phf: 
	pla
	pzero
	ENDM
	
	; Compare two words on stack for inequality
	MAC cmpwneq
	IF !FPULL
	pla
	sta R2
	pla
	sta R1
	ELSE
	sta R1
	sty R2
	ENDIF
	pla
	cmp R2
	bne .pht
	pla
	cmp R1
	bne .pht+1
	pzero
	IF !FPUSH
	jmp *+7
	ELSE
	jmp *+6
	ENDIF
.pht: pla
	pone
	ENDM

	; Compare two words on stack for less than (Higher on stack < Lower on stack)
	; unsigned version
	MAC cmpuwlt
	tsx
	lda.wx stack+4
	cmp.wx stack+2
	lda.wx stack+3
	sbc.wx stack+1
	bcs .phf			
	inx
	inx
	inx
	inx
	txs
	pone
	IF !FPUSH
	jmp *+11
	ELSE
	jmp *+10
	ENDIF
.phf: inx
	inx
	inx
	inx
	txs
	pzero
	ENDM

	; Compare two words on stack for less than (Higher on stack < Lower on stack)
	; signed version
	MAC cmpwlt
	tsx
	lda.wx stack+4
	cmp.wx stack+2
	lda.wx stack+3
	sbc.wx stack+1
	bpl .phf			
	inx
	inx
	inx
	inx
	txs
	pone
	IF !FPUSH
	jmp *+11
	ELSE
	jmp *+10
	ENDIF
.phf: inx
	inx
	inx
	inx
	txs
	pzero
	ENDM

	; Compare two words on stack for greater than or equal (H >= L)
	; Unsigned version
	MAC cmpuwgte
	tsx
	lda.wx stack+4
	cmp.wx stack+2
	lda.wx stack+3
	sbc.wx stack+1
	bcs .pht	
	inx
	inx
	inx
	inx
	txs
	pzero
	IF !FPUSH
	jmp *+11
	ELSE
	jmp *+10
	ENDIF
.pht: inx
	inx
	inx
	inx
	txs
	pone
	ENDM

	; Compare two words on stack for greater than or equal (H >= L)
	; Signed version
	MAC cmpwgte
	tsx
	lda.wx stack+4
	cmp.wx stack+2
	lda.wx stack+3
	sbc.wx stack+1
	bpl .pht			
	inx
	inx
	inx
	inx
	txs
	pzero
	IF !FPUSH
	jmp *+11
	ELSE
	jmp *+10
	ENDIF
.pht: inx
	inx
	inx
	inx
	txs
	pone
	ENDM

	; Compare two words on stack for greater than (H > L)
	; unsigned version
	MAC cmpuwgt
	tsx
	lda.wx stack+2
	cmp.wx stack+4
	lda.wx stack+1
	sbc.wx stack+3
	bcc .pht	
	inx
	inx
	inx
	inx
	txs
	pzero
	IF !FPUSH
	jmp *+11
	ELSE
	jmp *+10
	ENDIF
.pht: inx
	inx
	inx
	inx
	txs
	pone
	ENDM

	; Compare two words on stack for greater than (H > L)
	; signed version
	MAC cmpwgt
	tsx
	lda.wx stack+2
	cmp.wx stack+4
	lda.wx stack+1
	sbc.wx stack+3
	bmi .pht	
	inx
	inx
	inx
	inx
	txs
	pzero
	IF !FPUSH
	jmp *+11
	ELSE
	jmp *+10
	ENDIF
.pht: inx
	inx
	inx
	inx
	txs
	pone
	ENDM

	; Compare two words on stack for less than or equals (H <= L)
	; signed version
	MAC cmpwlte
	tsx
	lda.wx stack+2
	cmp.wx stack+4
	lda.wx stack+1
	sbc.wx stack+3
	bmi .phf
	inx
	inx
	inx
	inx
	txs
	pone
	IF !FPUSH
	jmp *+11
	ELSE
	jmp *+10
	ENDIF
.phf: inx
	inx
	inx
	inx
	txs
	pzero
	ENDM
	
	; Common macro for floa comparisons
	; Must call basicout afterwards!
	MAC floatcmp
	plf2var tmp_floatvar
	pullfac
	lda #<tmp_floatvar
	ldy #>tmp_floatvar
	jsr FCOMP
	ENDM
	
	; Compare two floats on stack for equality
	MAC cmpfeq
	basicin
	floatcmp
	eor #%11111111
	and #%00000001
	pha
	basicout
	ENDM

	; Compare two floats on stack for inequality
	MAC cmpfneq
	basicin
	floatcmp
	and #%00000001
	pha
	basicout
	ENDM
	
	; Compare two floats on stack for greater than (first on stack > second on stack)
	MAC cmpfgt
	basicin
	floatcmp
	bpl .skip
	eor #%11111111
.skip
	pha
	basicout
	ENDM
	
	; Compare two floats on stack for less than (first on stack < second on stack)
	MAC cmpflt
	basicin
	floatcmp
	lsr
	and #%00000001
	pha
	basicout
	ENDM
	
	; Compare two floats on stack for greater than or equal (first on stack >= second on stack)
	MAC cmpfgte
	basicin
	floatcmp
	eor #%11111111
	lsr
	and #%00000001
	pha
	basicout
	ENDM
	
	; Compare two floats on stack for less than or equal (first on stack <= second on stack)
	MAC cmpflte
	basicin
	floatcmp
	bmi .skip
	eor #%11111111
.skip
	and #%00000001
	pha
	basicout
	ENDM
	
	MAC addb
	IF !FPULL
	pla
	ENDIF
	sta R0
	pla
	clc
	adc R0
	IF !FPUSH
	pha
	ENDIF
	ENDM

    ; Perform OR on top 2 bytes of stack
    MAC orb
    IF !FPULL
    pla
    ENDIF
    sta R1
    pla
    ora R1
    IF !FPUSH
    pha
    ENDIF
    ENDM

    ; Perform AND on top 2 bytes of stack
    MAC andb
     IF !FPULL
    pla
    ENDIF
    sta R1
    pla
    and R1
    IF !FPUSH
    pha
    ENDIF
    ENDM

    ; Perform XOR on top 2 bytes of stack
    MAC xorb
     IF !FPULL
    pla
    ENDIF
    sta R1
    pla
    eor R1
    IF !FPUSH
    pha
    ENDIF
    ENDM
    
    ; Perform OR on top 2 words of stack
    MAC orw
    pla
    tay
    pla
    tsx
    ora.wx stack+2
    sta.wx stack+2
    tya
    ora.wx stack+3
    sta.wx stack+3
    ENDM

    ; Perform AND on top 2 words of stack
    MAC andw
    pla
    tay
    pla
    tsx
    and.wx stack+2
    sta.wx stack+2
    tya
    and.wx stack+3
    sta.wx stack+3
    ENDM

    ; Perform XOR on top 2 words of stack
    MAC xorw
    pla
    tay
    pla
    tsx
    eor.wx stack+2
    sta.wx stack+2
    tya
    eor.wx stack+3
    sta.wx stack+3
    ENDM

	; Add words on stack
	MAC addw
	tsx
	lda.wx stack+2
	clc
	adc.wx stack+4
	sta.wx stack+4
	pla
	adc.wx stack+3
	sta.wx stack+3
	pla
	ENDM
	
	; Substract bytes on stack
	MAC subb
	tsx
	lda.wx stack+2
	sec
	sbc.wx stack+1
	sta.wx stack+2
	pla
	ENDM

	; Substract words on stack
	MAC subw
	tsx
	lda.wx stack+4
	sec
	sbc.wx stack+2
	sta.wx stack+4
	lda.wx stack+3
	sbc.wx stack+1
	sta.wx stack+3
	inx
	inx
	txs
	ENDM
	
	; Convert byte on stack to float
	MAC btof
	basicin
	pla
	jsr BYTETOF
	pushfac
	ENDM
	
	; Convert word on stack to float
	MAC wtof
	basicin
	pla
	tax
	pla
	tay
	txa
	jsr GIVAYF
	pushfac
	basicout
	ENDM
	
	; Convert byte on stack to word
	MAC btow
	lda #$00
	pha
	ENDM
	
	; Convert word on stack to byte
	; (truncate)
	MAC wtob
	pla
	ENDM
	
	; Convert float on stack to word
	MAC ftow
	basicin
	pullfac
	jsr FACINX
	lda $65
	pha
	lda $64
	pha
	basicout
	ENDM
	
	; Convert float on stack to byte
	MAC ftob
	basicin
	pullfac
	jsr FACINX
	lda $65
	pha
	basicout
	ENDM
	
	; Add floats on stack
	MAC addf
	basicin
	pullfac
	pullarg
	jsr FADDT
	pushfac
	basicout
	ENDM
	
	; Substract floats on stack
	MAC subf
	basicin
	pullfac
	pullarg
	jsr FSUBT
	pushfac
	basicout
	ENDM
	
	; Multiply bytes on stack
	; by White Flame 20030207
	MAC mulb
	IF !FPULL
	pla
	ENDIF
	sta R1
	pla
	sta R2
	lda #$00
	beq .enterLoop		
.doAdd:
	clc
	adc R1	
.loop:		
	asl R1
.enterLoop:
	lsr R2
	bcs .doAdd
	bne .loop
.end:	
	IF !FPUSH
	pha
	ENDIF
	ENDM
	
	MAC twoscomplement
	lda {1}+1
	eor #$ff
	sta {1}+1
	lda {1}
	eor #$ff
	clc
	adc #$01
	sta {1}
	bne .skip
	inc {1}+1
.skip
	ENDM
	
	; Signed 16-bit multiplication
NUCL_SMUL16
	ldy #$00					; .y will hold the sign of product
	lda R1
	bpl .skip					; if factor1 is negative
	twoscomplement R0	; then factor1 := -factor1
	iny							; and switch sign
.skip
	lda R3				
	bpl .skip2					; if factor2 is negative
	twoscomplement R2	; then factor2 := -factor2
	iny							; and switch sign
.skip2
	jsr NUCL_MUL16				; do unsigned multiplication
	tya
	and #$01					; if .x is odd
	beq .q
	twoscomplement R0	; then product := -product
.q	rts

	;Multiply words at R0 and R2, with 16-bit result at R0
	;and 16-bit overflow at R5
NUCL_MUL16	SUBROUTINE
	ldx #$11		
	lda #$00
	sta R5
	clc
.1:	ror
	ror R5
	ror R1
	ror R0
	dex
	beq .q
	bcc .1
	sta R6
	lda R5
	clc
	adc R2
	sta R5
	lda R6
	adc R3
	jmp .1
.q:	sta R6
	rts
	
	; Multiply words on stack
	MAC mulw
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
	jsr NUCL_SMUL16
	IF !FPUSH
	lda R0
	pha
	lda R1
	pha
	ELSE
	lda R0
	ldy R1
	ENDIF
	ENDM
	
	; Multiply floats on stack
	MAC mulf
	basicin
	plf2var tmp_floatvar
	pullfac
	lda #<tmp_floatvar
	ldy #>tmp_floatvar
	jsr FMULT
	pushfac
	basicout
	ENDM
	
	; Divide floats on stack
	MAC divf
	basicin
	pullfac
	plf2var tmp_floatvar
	lda #<tmp_floatvar
	ldy #>tmp_floatvar
	jsr FDIV
	pushfac
	basicout
	ENDM
	
	; 8 bit division routine
	; submitted by Graham at CSDb forum
	
NUCL_DIV8	SUBROUTINE
	asl R0
	lda #$00
	rol
	ldx #$08
.loop1
	cmp R1
	bcc *+4
	sbc R1
	rol R0
	rol
	dex
	bne .loop1
	ldx #$08
.loop2
   	cmp R1
	bcc *+4
	sbc R1
	rol R2
	asl
	dex
	bne .loop2
	rts
	
	; Divide two bytes on stack
	MAC divb
	IF !FPULL
	pla
	ENDIF
	sta R1
	pla
	sta R0
	jsr NUCL_DIV8
	lda R0
	IF !FPUSH
	pha
	ENDIF
	ENDM
	
	; Invert true/false value on top byte of stack
	MAC notbool
	pla
	beq .skip
	pzero
	jmp *+6
.skip:
	pone			
	ENDM
	
	; Negate byte on stack (return twos complement)
	MAC negbyte
	pla
	eor #$FF
	clc
	adc #$01
	pha
	ENDM
	
	; Negate word on stack (return twos complement)
	MAC negw
	tsx
	lda.wx stack+1
	eor #$ff
	sta.wx stack+1
	lda.wx stack+2
	eor #$ff
	clc
	adc #$01
	sta.wx stack+2
	bcc *+5
	inc.wx stack+1
	ENDM
	
	; TODO
	; Negate int on stack
	MAC negint
	tsx
	lda.wx stack+1
	eor #$ff
	sta.wx stack+1
	lda.wx stack+2
	eor #$ff
	clc
	adc #$01
	sta.wx stack+2
	bcc *+5
	inc.wx stack+1
	ENDM

	; Divide integers on stack
	MAC divw
	plw2var R0
	plw2var R2
	lda R0
	bne .ok
	lda R1
	bne .ok
	lda #<err_divzero
	pha
	lda #>err_divzero
	pha
	jmp RUNTIME_ERROR
.ok
	jsr NUCL_DIV16
	pwvar R2
	ENDM

NUCL_DIV16	SUBROUTINE
	ldx #$00
	lda R2+1
	bpl .skip
	twoscomplement R2
	inx
.skip
	lda R0+1		
	bpl .skip2
	twoscomplement R0
	inx
.skip2
	txa
	pha
	jsr NUCL_DIVU16
	pla
	and #$01
	beq .q
	twoscomplement R2
.q	rts

	; 16 bit division routine
	; Author: unknown
	
NUCL_DIVU16 SUBROUTINE
.divisor 	EQU R0
.dividend 	EQU R2
.remainder 	EQU R4
.result 	EQU .dividend ; save memory by reusing divident to store the result

	lda #0	        ;preset remainder to 0
	sta .remainder
	sta .remainder+1
	ldx #16	        ;repeat for each bit: ...
.divloop:
	asl .dividend	;dividend lb & hb*2, msb -> Carry
	rol .dividend+1	
	rol .remainder	;remainder lb & hb * 2 + msb from carry
	rol .remainder+1
	lda .remainder
	sec
	sbc .divisor	;substract divisor to see if it fits in
	tay	        	;lb result -> Y, for we may need it later
	lda .remainder+1
	sbc .divisor+1
	bcc .skip		;if carry=0 then divisor didn't fit in yet

	sta .remainder+1	;else save substraction result as new remainder,
	sty .remainder	
	inc .result		;and INCrement result cause divisor fit in 1 times
.skip:
	dex
	bne .divloop	
	rts

	; poke routine (byte type)
	; requires that arguments are pushed backwards (value first)
	MAC pokeb
	IF !FPULL
	pla
	sta .selfmod_code+2
	pla
	sta .selfmod_code+1
	ELSE
	sta .selfmod_code+1
	sty .selfmod_code+2
	ENDIF
	pla
.selfmod_code:
	sta.w $0000
	ENDM

	; poke routine (word type)
	; requires that arguments are pushed backwards (value first)
	MAC pokew
	IF !FPULL
	pla
	sta .selfmod_code+2
	pla
	sta .selfmod_code+1
	ELSE
	sta .selfmod_code+1
	sty .selfmod_code+2
	ENDIF
	pla ; discard HB
	pla
.selfmod_code:
	sta.w $0000
	ENDM
	
	; doke routine
	; requires that arguments are pushed backwards (value first)
	MAC doke
	IF !FPULL
	pla
	sta R1
	pla
	sta R0
	ELSE
	sta R0
	sty R1
	ENDIF
	ldy #$01
	pla
	sta (R0),y
	pla
	dey
	sta (R0),y
	ENDM

	MAC for
	; max value already pushed
	; push address
.addr
	lda #<.addr
	pha
	lda #>.addr
	pha
	ENDM

	; NEXT routine (integer index)
	; usage next variable
	MAC nextw
	; increment variable
	clc
	inc {1}
	bne .skip
	inc {1}+1
.skip
	; pull address
	pla
	sta .selfmod_code+2
	pla
	sta .selfmod_code+1
	; pull max_value
	pla
	sta R1
	pla
	sta R0
	; compare them
	lda R0
	cmp {1}
	lda R1
	sbc {1}+1
	bcs .jump_back
	jmp .end ;variable is higher, exit loop
.jump_back
	; push max_value back
	lda R0
	pha
	lda R1
	pha
.selfmod_code
	jmp $0000;                                          
.end
	ENDM
	
	; NEXT routine (byte index)
	; usage next variable
	MAC nextb
	; increment variable
	inc {1}
	; don't roll over
	beq .end
.skip
    ; pull address
    pla
    sta .selfmod_code+2
    pla
    sta .selfmod_code+1
    ; pull max_value
    pla
    cmp {1}
    bcs .jump_back
    jmp .end
.jump_back
    ; push max_value back
    pha
.selfmod_code
    jmp $0000;
.end
    ENDM

	; Opcode for PEEK! (byte)
	MAC peekb
	IF !FPULL
	pla
	sta .selfmod_code+2
	pla
	sta .selfmod_code+1
	ELSE
	sta .selfmod_code+1
	sty .selfmod_code+2
	ENDIF
.selfmod_code:
	lda.w $0000
	IF !FPUSH
	pha
	ENDIF
	ENDM

	; Opcode for PEEK (integer)
	MAC peekw
	IF !FPULL
	pla
	sta .selfmod_code+2
	pla
	sta .selfmod_code+1
	ELSE
	sta .selfmod_code+1
	sty .selfmod_code+2
	ENDIF
.selfmod_code:
	lda.w $0000
	IF !FPUSH
	pha
	pzero
	ELSE
	ldy #$00
	ENDIF
	ENDM
	
	; Opcode for DEEK (integer)
	MAC deek
	IF !FPULL
	pla
	sta R1
	pla
	sta R0
	ELSE
	sta R0
	sty R1
	ENDIF
	IF !FPUSH
	ldy #$00
	lda (R0),y
	pha
	iny
	lda (R0),y
	pha
	ELSE
	ldy #$00
	lda (reserved0),y
	tax
	iny
	lda (reserved0),y
	tay
	txa
	ENDIF
	ENDM

	MAC inkeyb
	jsr KERNAL_GETIN
	IF !FPUSH
	pha
	ENDIF
	ENDM
	
	MAC inkeyw
	inkeyb
	IF !FPUSH
	lda #0
	pha
	ELSE
	ldy #0
	ENDIF
	ENDM

	MAC incb
	inc {1}
	ENDM

	MAC decb
	dec {1}
	ENDM

	MAC incw
	inc {1}
	bne .skip
	inc {1}+1
.skip
	ENDM

	MAC decw
	dec {1}
	lda #$ff
	cmp {1}
	bne .skip
	dec {1}+1
.skip
	ENDM

    MAC sys
    IF !FPULL
    pla
    sta .selfmod+2
    pla
    sta .selfmod+1
    ELSE
    sta .selfmod+1
    sty .selfmod+2
    ENDIF
.selfmod
    jsr $0000
    ENDM

    MAC usr
    IF !FPULL
    pla
    sta .selfmod+2
    pla
    sta .selfmod+1
    ELSE
    sta .selfmod+1
    sty .selfmod+2
    ENDIF
    lda #<.return_addr
    sta $02fe
    lda #>.return_addr
    sta $02ff
.selfmod
    jmp $0000
.return_addr
    ENDM
    
    ; Push random byte on stack
    MAC rndb
	jsr STDLIB_RND
	lda random+1
	IF !FPUSH
	pha
	ENDIF
	ENDM
    
    ; Push random integer on stack
    MAC rndw
	jsr STDLIB_RND
	IF !FPUSH
	lda random
	pha
	lda random+1
	pha
	ELSE
	lda random
	ldy random+1
	ENDIF
	ENDM
	
	; Push random float on stack
	MAC rndf
	basicin
	jsr FRAND
	pushfac
	basicout
	ENDM
	
	; Absolute value of integer
	MAC absw
	tsx
	lda.wx stack+1
	bpl .skip
	eor #$ff
	sta.wx stack+1
	lda.wx stack+2
	eor #$ff
	clc
	adc #$01
	sta.wx stack+2
	bne .skip
	inc.wx stack+1
.skip
	ENDM
	
	; Absolute value of float
	MAC absf
	basicin
	pullfac
	jsr FABS
	pushfac
	basicout
	ENDM
	
	; Sine of float
	MAC sinf
	basicin
	pullfac
	jsr FSIN
	pushfac
	basicout
	ENDM
	
	; Cosine of float
	MAC cosf
	basicin
	pullfac
	jsr FCOS
	pushfac
	basicout
	ENDM
	
	; Tangent of float
	MAC tanf
	basicin
	pullfac
	jsr FTAN
	pushfac
	basicout
	ENDM
	
	; Arc tangent of float
	MAC atnf
	basicin
	pullfac
	jsr FATN
	pushfac
	basicout
	ENDM
	
	; Square root of float
	MAC sqrf
	basicin
	pullfac
	jsr SQR
	pushfac
	basicout
	ENDM
	
	; Sign of float
	MAC sgnf
	basicin
	pullfac
	jsr SGN
	pushfac
	basicout
	ENDM

	MAC basicin
	lda $01
	ora #%00000001         
	sta $01
	ENDM
	
	MAC basicout
	lda $01
	and #%11111110
	sta $01
	ENDM
	
	; print float as decimal
	MAC stdlib_printf
	basicin
	pullfac
	jsr FOUT
	ldx $0100
	cpx #$20
	bne .doprint
	lda #$01	
.doprint
	jsr STDLIB_PRINT
	basicout
	ENDM
	
	; init program: save stack pointer and seed rnd
	MAC init_program
	tsx
	stx RESERVED_STACK_POINTER
	seed_rnd
	basicout
	ENDM

	; end program: restore stack pointer and exit
	MAC halt
	basicin
	ldx RESERVED_STACK_POINTER
	txs
	rts
	ENDM

	; Load routine
	; load 1: load at address stored in file
	; load 0: load at a specified address 
	; arguments on stack: address (if any), device no, filename_length, filename 
	MAC load
	; get filename and length
	pla
	tay
	pla
	tax
	pla
	jsr SETNAM
	; get device no
	pla ; discard high byte
	pla
	tax
	lda #$01
	ldy #{1}
	jsr SETLFS
	; get address
	IF {1} == 0
	pla
	tay
	pla
	tax
	ENDIF
	lda #$00
	jsr LOAD
	bcs .error
	lda #$00
.error
	sta FILE_ERROR_MSG
	ENDM
	
	; Save routine
	; arguments on stack: address_end, address_start, device no, filename_length, filename 
	MAC save
	; get filename and length
	pla
	tay
	pla
	tax
	pla
	jsr SETNAM
	; get device no
	pla ; discard high byte
	pla
	tax
	lda #$00
	ldy #$00
	jsr SETLFS
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
	jsr SAVE
	bcs .error
	lda #$00
.error
	sta FILE_ERROR_MSG
	ENDM
	
	; Get error code after file i/o
	MAC ferrb
	lda FILE_ERROR_MSG
	pha
	ENDM
	
	MAC ferrw
	ferrb
	lda #$00
	pha
	ENDM
	
	; From the book
	; 6502 Software Design by Leo J. Scanlon
	
NUCL_SQRW	SUBROUTINE
	lda R1
	bpl .ok
	lda #<err_illegal_quantity
	pha
	lda #>err_illegal_quantity
	pha
	jmp RUNTIME_ERROR
.ok	
	ldy #$01
	sty R2
	dey
	sty R3
.again
	sec
	lda R0
	tax
	sbc R2
	sta R0
	lda R1
	sbc R3
	sta R1
	bcc .nomore
	iny
	lda R2
	adc #$01
	sta R2
	bcc .again
	inc R3
	jmp .again
.nomore
	tya
	rts
	
	MAC sqrw
	IF !FPULL
	pla
	sta R1
	pla
	sta R0
	ELSE
	sta R0
	sty R1
	ENDIF
	jsr NUCL_SQRW
	IF !FPUSH
	pha
	pzero
	ELSE
	ldy #$00
	ENDIF
	ENDM
	
	MAC sgnw
	pla
	bmi .neg
	beq .plz
	pla
.pos
	pword #1
	jmp .end
.plz
	pla
	bne .pos
	pword #0
	jmp .end
.neg
	pla
	pword #65535
.end	
	ENDM

	MAC curpos
	pla
	tay
	pla
	tax
	clc
	jsr PLOT
	ENDM
	
	; {1} points to the list of
	;     low bytes of addresses
	; {2} points to the list of
	;     high bytes of addresses
	; index on top of stack
	MAC ongoto
	IF !FPULL
	pla
	ENDIF
	tax
	lda.wx {1}
	sta .selfmod_code+1
	lda.wx {2}
	sta .selfmod_code+2
.selfmod_code	
	jmp $0000
	ENDM
	
	; {1} points to the list of
	;     low bytes of addresses
	; {2} points to the list of
	;     high bytes of addresses
	; index on top of stack
	MAC ongosub
	IF !FPULL
	pla
	ENDIF
	tax
	lda.wx {1}
	sta .selfmod_code+1
	lda.wx {2}
	sta .selfmod_code+2
.selfmod_code	
	jsr $0000
	ENDM
	
	MAC lshiftb
	IF !FPULL
	pla
	ENDIF
	clc
	asl
	IF !FPUSH
	pha
	ENDIF
	ENDM
	
	MAC rshiftb
	IF !FPULL
	pla
	ENDIF
	lsr
	IF !FPUSH
	pha
	ENDIF
	ENDM
	
	MAC wait
.MASK EQU R2
.TRIG EQU R3
	IF !FPULL
	pla
	sta .selfmod_code+2
	pla
	sta .selfmod_code+1
	ELSE
	sta .selfmod_code+1
	sty .selfmod_code+2
	ENDIF
	pla
	sta .MASK
	pla
	sta .TRIG
.selfmod_code
	lda.w $0000
	eor .TRIG
	and .MASK
	beq .selfmod_code
	ENDM
	
	MAC WATCH
	IF !FPULL
	pla
	sta .selfmod_code+2
	pla
	sta .selfmod_code+1
	ELSE
	sta .selfmod_code+1
	sty .selfmod_code+2
	ENDIF
	pla
	sta R0
.selfmod_code
	lda.w $0000
	cmp R0
	bne .selfmod_code
	ENDM
		
	MAC while
	pla
	bne *+5
	jmp _EW_{1}
	ENDM
	
	MAC until
	pla
	bne *+5
	jmp _RP_{1}
	ENDM
	
	MAC ifstmt
	pla
	bne *+5
	IFCONST _EL_{1}
	jmp _EL_{1}
	ELSE
	jmp _EI_{1}
	ENDIF
	ENDM
	
err_divzero HEX 44 49 56 49 53 49 4F 4E 20 42 59 20 5A 45 52 4F 00
err_illegal_quantity HEX 49 4C 4C 45 47 41 4C 20 51 55 41 4E 54 49 54 59 00

RUNTIME_ERROR	SUBROUTINE
	pla
    tay
    pla
    jsr STDLIB_PRINT
    halt
    
tmp_floatvar HEX 00 00 00 00 00	

	LIST ON
KERNAL_PRINTCHR	EQU $e716
KERNAL_GETIN EQU $ffe4	

	LIST OFF

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

temp1:   DC.B $5a
random:  DC.B %10011101,%01011011

	MAC seed_rnd
	lda $a1
	sta random
	lda $a2
	sta random+1
	ENDM

	LIST ON
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
	
	ECHO "Library     :",library_start,"-", *-1
prg_start:
FPUSH	SET 0
FPULL	SET 0
	init_program
FPUSH	SET 1
	pbyte #0
FPULL	SET 1
FPUSH	SET 0
	plb2var _c1A
FPULL	SET 0
FPUSH	SET 1
	pbyte #0
FPULL	SET 1
FPUSH	SET 0
	plb2var _c1B
FPULL	SET 0
FPUSH	SET 1
	pbyte #0
FPULL	SET 1
FPUSH	SET 0
	plb2var _c2A
FPULL	SET 0
FPUSH	SET 1
	pbyte #0
FPULL	SET 1
FPUSH	SET 0
	plb2var _c2B
	jmp _Pdoplasma_end
_Pdoplasma:
FPULL	SET 0
FPUSH	SET 1
	pbvar _c1A
FPULL	SET 1
FPUSH	SET 0
	plb2var _doplasma.c1a
FPULL	SET 0
FPUSH	SET 1
	pbvar _c1B
FPULL	SET 1
FPUSH	SET 0
	plb2var _doplasma.c1b
FPULL	SET 0
FPUSH	SET 1
	pbyte #0
FPULL	SET 1
FPUSH	SET 0
	plb2var _doplasma.i
FPULL	SET 0
	pbyte #24
	for
	pbvar _doplasma.c1a
	pbarray_fast _sntable
	pbvar _doplasma.c1b
FPUSH	SET 1
	pbarray_fast _sntable
FPULL	SET 1
FPUSH	SET 0
	addb
FPULL	SET 0
FPUSH	SET 1
	pbvar _doplasma.i
FPULL	SET 1
FPUSH	SET 0
	plbarray_fast _doplasma.ybuf
	incb _doplasma.c1a
	incb _doplasma.c1a
	incb _doplasma.c1a
	incb _doplasma.c1a
FPULL	SET 0
	pbvar _doplasma.c1b
FPUSH	SET 1
	pbyte #9
FPULL	SET 1
	addb
FPUSH	SET 0
	plb2var _doplasma.c1b
	nextb _doplasma.i
	incb _c1A
	incb _c1A
	incb _c1A
	decb _c1B
	decb _c1B
	decb _c1B
	decb _c1B
	decb _c1B
FPULL	SET 0
FPUSH	SET 1
	pbvar _c2A
FPULL	SET 1
FPUSH	SET 0
	plb2var _doplasma.c2a
FPULL	SET 0
FPUSH	SET 1
	pbvar _c2B
FPULL	SET 1
FPUSH	SET 0
	plb2var _doplasma.c2b
FPULL	SET 0
FPUSH	SET 1
	pbyte #0
FPULL	SET 1
FPUSH	SET 0
	plb2var _doplasma.i
FPULL	SET 0
	pbyte #39
	for
	pbvar _doplasma.c2a
	pbarray_fast _sntable
	pbvar _doplasma.c2b
FPUSH	SET 1
	pbarray_fast _sntable
FPULL	SET 1
FPUSH	SET 0
	addb
FPULL	SET 0
FPUSH	SET 1
	pbvar _doplasma.i
FPULL	SET 1
FPUSH	SET 0
	plbarray_fast _doplasma.xbuf
	incb _doplasma.c2a
	incb _doplasma.c2a
	incb _doplasma.c2a
FPULL	SET 0
	pbvar _doplasma.c2b
FPUSH	SET 1
	pbyte #7
FPULL	SET 1
	addb
FPUSH	SET 0
	plb2var _doplasma.c2b
	nextb _doplasma.i
	incb _c2A
	incb _c2A
	decb _c2B
	decb _c2B
FPULL	SET 0
FPUSH	SET 1
	pbyte #0
FPULL	SET 1
FPUSH	SET 0
	plb2var _doplasma.y
FPULL	SET 0
	pbyte #24
	for
FPUSH	SET 1
	pbyte #0
FPULL	SET 1
FPUSH	SET 0
	plb2var _doplasma.x
FPULL	SET 0
	pbyte #39
	for
	pbvar _doplasma.x
	pbarray_fast _doplasma.xbuf
	pbvar _doplasma.y
FPUSH	SET 1
	pbarray_fast _doplasma.ybuf
FPULL	SET 1
FPUSH	SET 0
	addb
FPULL	SET 0
	pwvar _doplasma.screen
	pbvar _doplasma.x
	btow
	addw
	pokeb
	nextb _doplasma.x
	pwvar _doplasma.screen
	pbyte #40
	btow
	addw
	plw2var _doplasma.screen
	nextb _doplasma.y
	rts
_Pdoplasma_end:
	jmp _Pmakecharset_end
_Pmakecharset:
	paddr _S1
	stdlib_putstr
	lda #13
	jsr KERNAL_PRINTCHR
	paddr _S2
	pbyte #10
	btow
FPUSH	SET 1
	pword #40
FPULL	SET 1
FPUSH	SET 0
	mulw
FPULL	SET 0
	pbyte #15
	btow
	addw
	pword #1024
	addw
	textat
FPUSH	SET 1
	pbyte #0
FPULL	SET 1
FPUSH	SET 0
	plb2var _makecharset.c
_Lmakecharset.loop:
FPULL	SET 0
	pbvar _makecharset.c
FPUSH	SET 1
	pbarray_fast _sntable
FPULL	SET 1
FPUSH	SET 0
	plb2var _makecharset.s
FPULL	SET 0
FPUSH	SET 1
	pbyte #0
FPULL	SET 1
FPUSH	SET 0
	plb2var _makecharset.i
FPULL	SET 0
	pbyte #7
	for
FPUSH	SET 1
	pbyte #0
FPULL	SET 1
FPUSH	SET 0
	plb2var _makecharset.b
FPULL	SET 0
FPUSH	SET 1
	pbyte #0
FPULL	SET 1
FPUSH	SET 0
	plb2var _makecharset.ii
FPULL	SET 0
	pbyte #7
	for
	rndb
FPUSH	SET 1
	pbyte #255
FPULL	SET 1
FPUSH	SET 0
	andb
FPULL	SET 0
FPUSH	SET 1
	pbvar _makecharset.s
FPULL	SET 1
FPUSH	SET 0
	cmpbgt
	pla
	bne *+5
	jmp _J1
FPULL	SET 0
	pbvar _makecharset.b
	pbvar _makecharset.ii
FPUSH	SET 1
	pbarray_fast _bittab
FPULL	SET 1
	orb
FPUSH	SET 0
	plb2var _makecharset.b
_J1:
	nextb _makecharset.ii
FPULL	SET 0
	pbvar _makecharset.b
	pwvar _makecharset.address
	pbvar _makecharset.c
	btow
	pbyte #8
	btow
	mulw
	addw
	pbvar _makecharset.i
	btow
	addw
	pokeb
	nextb _makecharset.i
	incb _makecharset.c
	pbvar _makecharset.c
FPUSH	SET 1
	pbyte #0
FPULL	SET 1
FPUSH	SET 0
	cmpbgt
	pla
	bne *+5
	jmp _J2
	jmp _Lmakecharset.loop
_J2:
	rts
_Pmakecharset_end:
	; Inline ASM start

    sei
	; Inline ASM end
FPULL	SET 0
	pbyte #6
FPUSH	SET 1
	pword #53280
FPULL	SET 1
FPUSH	SET 0
	pokeb
FPULL	SET 0
	pbyte #6
FPUSH	SET 1
	pword #53281
FPULL	SET 1
FPUSH	SET 0
	pokeb
FPULL	SET 0
	pbyte #0
	pword #1000
	pword #55296
	memset
FPUSH	SET 1
	pword #8192
FPULL	SET 1
FPUSH	SET 0
	plw2var _makecharset.address
	jsr _Pmakecharset
_Lloop:
FPULL	SET 0
FPUSH	SET 1
	pword #10240
FPULL	SET 1
FPUSH	SET 0
	plw2var _doplasma.screen
	jsr _Pdoplasma
FPULL	SET 0
	pbyte #168
FPUSH	SET 1
	pword #53272
FPULL	SET 1
FPUSH	SET 0
	pokeb
FPULL	SET 0
FPUSH	SET 1
	pword #11264
FPULL	SET 1
FPUSH	SET 0
	plw2var _doplasma.screen
	jsr _Pdoplasma
FPULL	SET 0
	pbyte #184
FPUSH	SET 1
	pword #53272
FPULL	SET 1
FPUSH	SET 0
	pokeb
	jmp _Lloop
prg_end:
	halt
	ECHO "Code        :",prg_start,"-", *-1
data_start:
_bittab	DC.B #1, #2, #4, #8, #16, #32, #64, #128
_sntable	DC.B #127, #130, #133, #136, #139, #143, #146, #149, #152, #155, #158, #161, #164, #167, #170, #173
	DC.B #176, #179, #182, #184, #187, #190, #193, #195, #198, #200, #203, #205, #208, #210, #213, #215
	DC.B #217, #219, #221, #224, #226, #228, #229, #231, #233, #235, #236, #238, #239, #241, #242, #244
	DC.B #245, #246, #247, #248, #249, #250, #251, #251, #252, #253, #253, #254, #254, #254, #254, #254
	DC.B #255, #254, #254, #254, #254, #254, #253, #253, #252, #251, #251, #250, #249, #248, #247, #246
	DC.B #245, #244, #242, #241, #239, #238, #236, #235, #233, #231, #229, #228, #226, #224, #221, #219
	DC.B #217, #215, #213, #210, #208, #205, #203, #200, #198, #195, #193, #190, #187, #184, #182, #179
	DC.B #176, #173, #170, #167, #164, #161, #158, #155, #152, #149, #146, #143, #139, #136, #133, #130
	DC.B #127, #124, #121, #118, #115, #111, #108, #105, #102, #99, #96, #93, #90, #87, #84, #81
	DC.B #78, #75, #72, #70, #67, #64, #61, #59, #56, #54, #51, #49, #46, #44, #41, #39
	DC.B #37, #35, #33, #30, #28, #26, #25, #23, #21, #19, #18, #16, #15, #13, #12, #10
	DC.B #9, #8, #7, #6, #5, #4, #3, #3, #2, #1, #1, #0, #0, #0, #0, #0
	DC.B #0, #0, #0, #0, #0, #0, #1, #1, #2, #3, #3, #4, #5, #6, #7, #8
	DC.B #9, #10, #12, #13, #15, #16, #18, #19, #21, #23, #25, #26, #28, #30, #33, #35
	DC.B #37, #39, #41, #44, #46, #49, #51, #54, #56, #59, #61, #64, #67, #70, #72, #75
	DC.B #78, #81, #84, #87, #90, #93, #96, #99, #102, #105, #108, #111, #115, #118, #121, #124
_S1	HEX 93 00
_S2	HEX 0C 0F 01 04 09 0E 07 2E 2E 2E 00
data_end:
	ECHO "Data        :",data_start,"-", *-1
	;--------------
	SEG.U variables
	ORG data_end+1
_c1A	DS.B 1
_c1B	DS.B 1
_c2A	DS.B 1
_c2B	DS.B 1
_doplasma.screen	DS.B 2
_doplasma.xbuf	DS.B 40
_doplasma.ybuf	DS.B 25
_doplasma.c1a	DS.B 1
_doplasma.c1b	DS.B 1
_doplasma.i	DS.B 1
_doplasma.c2a	DS.B 1
_doplasma.c2b	DS.B 1
_doplasma.y	DS.B 1
_doplasma.x	DS.B 1
_makecharset.address	DS.B 2
_makecharset.c	DS.B 1
_makecharset.s	DS.B 1
_makecharset.i	DS.B 1
_makecharset.b	DS.B 1
_makecharset.ii	DS.B 1
	ECHO "Variables*  :",data_end,"-", *
	ECHO "==================="
	ECHO "*: uninitialized segment"

