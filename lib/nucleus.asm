
	PROCESSOR 6502
	LIST OFF	
		
stack 		EQU $0100

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
	lda {1}
	pha
	lda {1}+1
	pha
	ELSE
	lda {1}
	ldy {1}+1
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
	lda {1},x
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
	
	MAC psarray
	pwarray {1}
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
	
	; Pull string pointer to variable
    MAC pls2var
    plw2var {1}
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
	sta {1},x
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
	
	MAC plsarray
	plwarray {1}
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
	tay
	lda #$00
	jsr GIVAYF
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
	; https://codebase64.org/doku.php?id=base:16bit_division_16-bit_result
	
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

	; poke pseudo-op (byte type)
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
	
	; poke pseudo-op (byte type)
	; used when the address is constant
	MAC pokeb_c
	IF !FPULL
	pla
	ENDIF
	sta.w {1}
	ENDM

	; poke pseudo.op (word type)
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
	
	; poke pseudo-op (word type)
	; used when the address is constant
	MAC pokew_c
	IF !FPULL
	pla
	pla
	ENDIF
	sta.w {1}
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

	; Entry of FOR loop (integer index)
	; Usage: forw <for identifier>, <index_var>
	MAC forw
	IFCONST XFOR_step_{1}
	; need to check if step is negative
	lda XFOR_step_{1} + 1
	; it is positive: do the regular comparison
	bpl .cmp
.neg
	; compare index to max
	lda {2}
	cmp XFOR_max_{1}
	lda {2}+1
	sbc XFOR_max_{1}+1
	bpl .enter					; Enter the code block
	jmp _ENDFOR_{1}				; Exit loop
	ENDIF
.cmp
	; compare index to max
	lda XFOR_max_{1}
	cmp {2}
	lda XFOR_max_{1}+1
	sbc {2}+1
	bpl .enter					; Enter the code block
	jmp _ENDFOR_{1}				; Exit loop
.enter
	ENDM

	; NEXT routine (integer index)
	; Usage: nextw <for identifier>, <index_var>
	MAC nextw
	; increment index variable
	IFCONST XFOR_step_{1}
	; increment with step
	clc
	lda XFOR_step_{1}
	adc {2}
	sta {2}
	lda XFOR_step_{1}+1
	adc {2}+1
	sta {2}+1
	ELSE
	; increment with 1
	inc {2}
	bne .skip
	inc {2}+1
	ENDIF
.skip
	; Jump back to loop entry
	jmp _FOR_{1}
	ENDM
	
	; Entry of FOR loop (byte index)
	; Usage: forb <for identifier>, <index_var>
	MAC forb
	; compare index to max
	lda XFOR_max_{1}
	cmp {2}
	bcs .enter
	;index is gte, exit loop
	jmp _ENDFOR_{1}
.enter
	ENDM
	
	; NEXT routine (byte index)
	; Usage: nextb <for identifier>, <index_var>
	MAC nextb
	; increment index variable
	IFCONST XFOR_step_{1}
	; increment with step
	clc
	lda XFOR_step_{1}
	adc {2}
	sta {2}
	; don't roll over
	bcs _ENDFOR_{1}
	ELSE
	; increment with one
	inc {2}
	; don't roll over
	beq _ENDFOR_{1}
	ENDIF
	jmp _FOR_{1}
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
	lda (R0),y
	tax
	iny
	lda (R0),y
	tay
	txa
	ENDIF
	ENDM

	MAC inkeyb
	stdlib_getin
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
	
	MAC incbarrb
	IF !FPULL
	pla
	ENDIF
	tax
	inc.wx {1}
	ENDM
	
	MAC decbarrb
	IF !FPULL
	pla
	ENDIF
	tax
	dec.wx {1}
	ENDM
	
	MAC incbarr
	IF !FPULL
	pla
	sta .selfmod_code + 2
	pla
	sta .selfmod_code + 1
	ELSE
	sta .selfmod_code + 1
	sty .selfmod_code + 2
	ENDIF
.selfmod_code:
	inc $0000
	ENDM
	
	MAC decbarr
	IF !FPULL
	pla
	sta .selfmod_code + 2
	pla
	sta .selfmod_code + 1
	ELSE
	sta .selfmod_code + 1
	sty .selfmod_code + 2
	ENDIF
.selfmod_code:
	inc $0000
	ENDM
	
	; These two are very much not effective :-(
	
	MAC incwarr
	IF !FPULL
	pla
	sta R1
	pla
	sta R0
	ELSE
	sta R0
	sty R1
	ENDIF
	
	lda #>{1}
	sta R3
	lda #<{1}
	clc
	adc R0
	sta R2
	lda R1
	adc R3
	sta R3
	
	ldy #$00
	lda (R2),y
	clc
	adc #$01
	sta (R2),y
	iny
	lda (R2),y
	adc #$00
	sta (R2),y 
	
	ENDM
	
	MAC decwarr
	IF !FPULL
	pla
	sta R1
	pla
	sta R0
	ELSE
	sta R0
	sty R1
	ENDIF
	
	lda #>{1}
	sta R3
	lda #<{1}
	clc
	adc R0
	sta R2
	lda R1
	adc R3
	sta R3
	
	ldy #$00
	lda (R2),y
	sec
	sbc #$01
	sta (R2),y
	iny
	lda (R2),y
	sbc #$00
	sta (R2),y 
	
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
	
	; print byte as decimal  	
	MAC printb
	pla
	jsr STDLIB_PRINT_BYTE
	ENDM
	
	; print word as decimal  	
	MAC printw
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
	
	; print float as decimal
	MAC printf
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
	stx STDLIB_STACK_POINTER
	jsr STDLIB_SEED_RND
	jsr STDLIB_MEMSETUP
	basicout
	ENDM

	; end program: restore stack pointer and exit
	MAC halt
	basicin
	ldx STDLIB_STACK_POINTER
	txs
	rts
	ENDM

	MAC load
	stdlib_load {1}
	ENDM
	
	MAC save
	stdlib_save {1}
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
	tay
	pla
.loop
	asl
	dey
	bne .loop
	IF !FPUSH
	pha
	ENDIF
	ENDM
	
	MAC rshiftb
	IF !FPULL
	pla
	ENDIF
	tay
	pla
.loop
	lsr
	dey
	bne .loop
	IF !FPUSH
	pha
	ENDIF
	ENDM
	
	; Doubles word on stack
	MAC dblw
	tsx
	asl.wx stack+2
	rol.wx stack+1
	ENDM
	
	MAC lshiftw
	IF !FPULL
	pla
	ENDIF
	tay
	tsx
.loop
	asl.wx stack+2
	rol.wx stack+1
	dey
	bne .loop
	ENDM
	
	MAC rshiftw
	IF !FPULL
	pla
	ENDIF
	tay
	tsx
.loop
	lsr.wx stack+1
	ror.wx stack+2
	dey
	bne .loop
	ENDM
	
	; LSHIFT!() function
	; with constant argument
	MAC lshiftbc
	IF !FPULL
	pla
	ENDIF
	REPEAT {1}
	asl
	REPEND
	IF !FPUSH
	pha
	ENDIF
	ENDM

	; LSHIFT() function
	; with constant argument
	MAC lshiftwc
	tsx
	REPEAT {1}
	asl.wx stack+2
	rol.wx stack+1
	REPEND
	ENDM
	
	; RSHIFT!() function
	; with constant argument
	MAC rshiftbc
	IF !FPULL
	pla
	ENDIF
	REPEAT {1}
	lsr
	REPEND
	IF !FPUSH
	pha
	ENDIF
	ENDM

	; RSHIFT() function
	; with constant argument
	MAC rshiftwc
	tsx
	REPEAT {1}
	lsr.wx stack+1
	ror.wx stack+2
	REPEND
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
	
	; WATCH command with
	; constant address
	MAC watchc
	IF !FPULL
	pla
	ENDIF
.again
	cmp {1}
	bne .again
	ENDM
	
	MAC ifstmt
	IF !FPULL
	pla
	ENDIF
	bne *+5
	IFCONST _EL_{1}
	jmp _EL_{1}
	ELSE
	jmp _EI_{1}
	ENDIF
	ENDM
		
	MAC while
	IF !FPULL
	pla
	ENDIF
	bne *+5
	jmp _EW_{1}
	ENDM
	
	MAC until
	IF !FPULL
	pla
	ENDIF
	bne *+5
	jmp _RP_{1}
	ENDM
	
	; This universal macro
	; can be used for if, while, until
	; usage:
	; cond_stmt <false_label> [, <else_label>]
	MAC cond_stmt
	IF !FPULL
	pla
	ENDIF
	bne *+5
	IFCONST {2}
	jmp {2}
	ELSE
	jmp {1}
	ENDIF
	ENDM
	
	; Pulls the function return address
	; and stores it to temporary location
	;
	MAC pull_retaddr
	pla
	sta {1}_tmp_retaddr+1
	pla
	sta {1}_tmp_retaddr
	ENDM
	
	; Restores the function return address
	; from temporary location
	;
	MAC push_retaddr
	lda {1}_tmp_retaddr
	pha
	lda {1}_tmp_retaddr+1
	pha
	ENDM
		
	; Print a string pointed to
	; by top 2 bytes on stack
	MAC prints
    pla
    tay
    pla
    jsr STDLIB_PRINT
	ENDM
	
	; Print one character
	MAC printc
	stdlib_printc {1}
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
	sta R9
	pla
	sta R8
	txa
	jsr STDLIB_OUTPUT_BYTE
	ENDM
	
	; Output float as decimal at col, row
	; args on stack:
	; color (if {1} EQ 1)
	; then COL, ROW
	MAC fat
	basicin
	pullfac
	pla
	sta R9
	pla
	sta R8
	jsr STDLIB_OUTPUT_FLOAT
	basicout
	IF {1}
	pla
	jsr STDLIB_SETCOLOR
	ENDIF
	ENDM
	
	; TEXTAT - output string at col, row
	; args on stack:
	; color (if {1} EQ 1)
	; top 2 - string addr
	; then COL, ROW
	; {1} color is set
	MAC textat
	IF !FPULL
	pla
	sta RB
	pla
	sta RA
	ELSE
	sta RA
	sty RB
	ENDIF
	pla
	sta R9 ; col
	pla
	sta R8 ; row
	jsr STDLIB_TEXTAT
	IF {1}
	pla
	jsr STDLIB_SETCOLOR
	ENDIF
	ENDM

	; Swap byte and word on top of stack
	MAC swapb
	tsx
	lda.wx stack+1
	tay
	lda.wx stack+2
	sta.wx stack+1
	lda.wx stack+3
	sta.wx stack+2
	tya
	sta.wx stack+3
	ENDM
	
	; Swap two words on top of stack
	; sp H L H L
	MAC swapw
	tsx
	lda.wx stack+1
	tay
	lda.wx stack+3
	sta.wx stack+1
	tya
	sta.wx stack+3
	
	lda.wx stack+2
	tay
	lda.wx stack+4
	sta.wx stack+2
	tya
	sta.wx stack+4
	ENDM
	
	MAC swaps
	swapw
	ENDM
	
	; Swap float and word on stack
	; sp f1 f2 f3 f4 f5 H L
	MAC swapf
	tsx
	lda.wx stack+7
	tay
	lda.wx stack+6
	sta R0
	lda.wx stack+5
	sta.wx stack+7
	lda.wx stack+4
	sta.wx stack+6
	lda.wx stack+3
	sta.wx stack+5
	lda.wx stack+2
	sta.wx stack+4
	lda.wx stack+1
	sta.wx stack+3
	lda R0
	sta.wx stack+1
	tya
	sta.wx stack+2
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
