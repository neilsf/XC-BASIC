
reserved0	EQU $fb
reserved1	EQU $fc

reserved2	EQU $fd
reserved3	EQU $fe

reserved4	EQU $3f
reserved5	EQU $40

reserved6	EQU $41
reserved7	EQU $42

reserved8	EQU $43                              
reserved9	EQU $44

reservedA	EQU $45
reservedB	EQU $46

stack 		EQU $0100

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
STRVAL			EQU $b7b5

SETNAM		EQU $ffbd
SETLFS		EQU $ffba
LOAD		EQU $ffd5
SAVE		EQU $ffd8
PLOT		EQU $fff0

	PROCESSOR 6502
	
	; Push a zero on the stack
	; EXAMINE REFS BEFORE CHANGING!
	MAC pzero
	lda #$00
	pha
	ENDM

	; Push a one on the stack
	; EXAMINE REFS BEFORE CHANGING!
	MAC pone
	lda #$01
	pha
	ENDM

	; Push one byte on the stack
	MAC pbyte
	lda {1}
	pha
	ENDM

	; Push byte var on the stack
	MAC pbvar
	pbyte {1}
	ENDM

	; Push one byte as a word on the stack
	MAC pbyteasw
	lda {1}
	pha
	lda #$00
	pha
	ENDM

	; Push one word on the stack
	MAC pword
	lda #<{1}
	pha
	lda #>{1}
	pha
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
	lda.w {1}
	pha
	lda.w {1}+1
	pha
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
	pla
	sta reserved1
	pla
	sta reserved0
	lda #<{1}
	clc
	adc reserved0
	sta reserved0
	lda #>{1}
	adc reserved1
	sta reserved1
	ldy #$00
	lda (reserved0),y
	pha
	ENDM

	;Push one word variable (indexed) on the stack
	;Expects array index being on top of stack
	MAC pwarray
	pla
	sta reserved1
	pla
	sta reserved0
	lda #<{1}
	clc
	adc reserved0
	sta reserved0
	lda #>{1}
	adc reserved1
	sta reserved1
	ldy #$00
	lda (reserved0),y
	pha
	iny
	lda (reserved0),y
	pha
	ENDM
	
	;Push one float variable (indexed) on the stack
	;Expects array index being on top of stack
	MAC pfarray
	pla
	sta reserved1
	pla
	sta reserved0
	lda #<{1}
	clc
	adc reserved0
	sta reserved0
	lda #>{1}
	adc reserved1
	sta reserved1
	ldy #$04
.loop	
	lda (reserved0),y
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
	pla
	sta {1}
	ENDM

	; Pull word to variable
	MAC plw2var
	pla
	sta {1}+1
	pla
	sta {1}
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
	pla
	sta reserved1
	pla
	sta reserved0
	lda #<{1}
	clc
	adc reserved0
	sta reserved0
	lda #>{1}
	adc reserved1
	sta reserved1
	ldy #$00
	pla
	sta (reserved0),y
	ENDM	
	
	;Pull one word variable (indexed)
	;Expects array index on top of stack
	MAC plwarray
	pla
	sta reserved1
	pla
	sta reserved0
	lda #<{1}
	clc
	adc reserved0
	sta reserved0
	lda #>{1}
	adc reserved1
	sta reserved1
	ldy #$01
	pla
	sta (reserved0),y
	dey
	pla
	sta (reserved0),y
	ENDM
	
	; Pull one float variable (indexed)
	; Expects array index on top of stack
	MAC plfarray
	pla
	sta reserved1
	pla
	sta reserved0
	lda #<{1}
	clc
	adc reserved0
	sta reserved0
	lda #>{1}
	adc reserved1
	sta reserved1
	ldy #$00
	REPEAT 5	
	pla
	sta (reserved0),y
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
	pla
	sta reserved1
	pla
	cmp reserved1
	bcs .phf
	pone
	jmp *+6
.phf: pzero 
	ENDM

	; Compare two bytes on stack for less than or equal
	MAC cmpblte
	pla
	sta reserved1
	pla
	cmp reserved1
	bcc .pht
	beq .pht
	pzero
	jmp *+6
.pht: pone 
	ENDM

	; Compare two bytes on stack for greater than or equal
	MAC cmpbgte
	pla                 
	sta reserved1
	pla
	cmp reserved1
	bcs .pht
	pzero
	jmp *+6
.pht: pone
	ENDM

	; Compare two bytes on stack for equality
	MAC cmpbeq
	pla
	sta reserved1
	pla
	cmp reserved1
	beq .pht
	pzero
	jmp *+6
.pht: pone
	ENDM

	; Compare two bytes on stack for inequality
	MAC cmpbneq
	pla
	sta reserved1
	pla
	cmp reserved1
	bne .pht
	pzero
	jmp *+6
.pht: pone
	ENDM

	; Compare two bytes on stack for greater than
	MAC cmpbgt
	pla
	sta reserved1
	pla
	cmp reserved1
	bcc .phf
	beq .phf
	pone
	jmp *+6
.phf: pzero
	ENDM

	; Compare two words on stack for equality
	MAC cmpweq
	pla
	sta reserved1
	pla
	sta reserved2
	pla
	cmp reserved1
	bne .phf
	pla
	cmp reserved2
	bne .phf+1
	pone
	jmp *+7
.phf: pla
	pzero
	ENDM
	
	; Compare two words on stack for inequality
	MAC cmpwneq
	pla
	sta reserved1
	pla
	sta reserved2
	pla
	cmp reserved1
	bne .pht
	pla
	cmp reserved2
	bne .pht+1
	pzero
	jmp *+7
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
	jmp *+11
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
	jmp *+11
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
	jmp *+11
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
	jmp *+11
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
	jmp *+11
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
	jmp *+11
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
	jmp *+11
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
	
	; Add bytes on stack
	MAC addb
	pla
	tsx
	clc
	adc.wx stack+1
	sta.wx stack+1
	ENDM

    ; Perform OR on top 2 bytes of stack
    MAC orb
    pla
    sta reserved1
    pla
    ora reserved1
    pha
    ENDM

    ; Perform AND on top 2 bytes of stack
    MAC andb
    pla
    sta reserved1
    pla
    and reserved1
    pha
    ENDM

    ; Perform XOR on top 2 bytes of stack
    MAC xorb
    pla
    sta reserved1
    pla
    eor reserved1
    pha
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
	pla
	sta reserved1
	pla
	sta reserved2
	lda #$00
	beq .enterLoop		
.doAdd:
	clc
	adc reserved1	
.loop:		
	asl reserved1
.enterLoop:
	lsr reserved2
	bcs .doAdd
	bne .loop
.end:	
	pha
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
	lda reserved1
	bpl .skip					; if factor1 is negative
	twoscomplement reserved0	; then factor1 := -factor1
	iny							; and switch sign
.skip
	lda reserved3				
	bpl .skip2					; if factor2 is negative
	twoscomplement reserved2	; then factor2 := -factor2
	iny							; and switch sign
.skip2
	jsr NUCL_MUL16				; do unsigned multiplication
	tya
	and #$01					; if .x is odd
	beq .q
	twoscomplement reserved0	; then product := -product
.q	rts

	;Multiply words at reserved0 and reserved2, with 16-bit result at reserved0
	;and 16-bit overflow at reserved5
NUCL_MUL16	SUBROUTINE
	ldx #$11		
	lda #$00
	sta reserved5
	clc
.1:	ror
	ror reserved5
	ror reserved1
	ror reserved0
	dex
	beq .q
	bcc .1
	sta reserved6
	lda reserved5
	clc
	adc reserved2
	sta reserved5
	lda reserved6
	adc reserved3
	jmp .1
.q:	sta reserved6
	rts
	
	; Multiply words on stack
	MAC mulw
	pla
	sta reserved1
	pla
	sta reserved0
	pla
	sta reserved3
	pla
	sta reserved2
	jsr NUCL_SMUL16
	lda reserved0
	pha
	lda reserved1
	pha
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
	asl reserved0
	lda #$00
	rol

	ldx #$08
.loop1
	cmp reserved1
	bcc *+4
	sbc reserved1
	rol reserved0
	rol
	dex
	bne .loop1
   
	ldx #$08
.loop2
   	cmp reserved1
	bcc *+4
	sbc reserved1
	rol reserved2
	asl
	dex
	bne .loop2
	rts
	
	; Divide two bytes on stack
	MAC divb
	pla
	sta reserved1
	pla
	sta reserved0
	jsr NUCL_DIV8
	lda reserved0
	pha
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
	plw2var reserved0
	plw2var reserved2
	lda reserved0
	bne .ok
	lda reserved1
	bne .ok
	lda #<err_divzero
	pha
	lda #>err_divzero
	pha
	jmp RUNTIME_ERROR
.ok
	jsr NUCL_DIV16
	pwvar reserved2
	ENDM

NUCL_DIV16	SUBROUTINE
	ldx #$00
	lda reserved2+1
	bpl .skip
	twoscomplement reserved2
	inx
.skip
	lda reserved0+1		
	bpl .skip2
	twoscomplement reserved0
	inx
.skip2
	txa
	pha
	jsr NUCL_DIVU16
	pla
	and #$01
	beq .q
	twoscomplement reserved2
.q	rts

	; 16 bit division routine
	; Author: unknown
	
NUCL_DIVU16 SUBROUTINE
.divisor 	EQU reserved0
.dividend 	EQU reserved2
.remainder 	EQU reserved4
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
	pla
	sta reserved1
	pla
	sta reserved0
	ldy #$00
	pla
	sta (reserved0),y
	ENDM

	; poke routine (word type)
	; requires that arguments are pushed backwards (value first)
	MAC pokew
	pla
	sta reserved1
	pla
	sta reserved0
	ldy #$00
	pla ;discard high byte
	pla
	sta (reserved0),y
	ENDM
	
	; doke routine
	; requires that arguments are pushed backwards (value first)
	MAC doke
	pla
	sta reserved1
	pla
	sta reserved0
	ldy #$01
	pla
	sta (reserved0),y
	pla
	dey
	sta (reserved0),y
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
	sta reserved1
	pla
	sta reserved0

	; compare them
	lda reserved0
	cmp {1}
	lda reserved1
	sbc {1}+1
	bcs .jump_back
	jmp .end ;variable is higher, exit loop
.jump_back
	; push max_value back
	lda reserved0
	pha
	lda reserved1
	pha
.selfmod_code
	jmp $0000;                                          
.end
	ENDM

	; Opcode for PEEK! (byte)
	MAC peekb
	pla
	sta reserved1
	pla
	sta reserved0
	ldy #$00
	lda (reserved0),y
	pha
	ENDM

	; Opcode for PEEK (integer)
	MAC peekw
	pla
	sta reserved1
	pla
	sta reserved0
	ldy #$00
	lda (reserved0),y
	pha
	pzero
	ENDM
	
	; Opcode for DEEK (integer)
	MAC deek
	pla
	sta reserved1
	pla
	sta reserved0
	ldy #$00
	lda (reserved0),y
	pha
	iny
	lda (reserved0),y
	pha
	ENDM

	MAC inkeyb
	jsr KERNAL_GETIN
	pha
	ENDM
	
	MAC inkeyw
	inkeyb
	lda #0
	pha
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
    pla
    sta .selfmod+2
    pla
    sta .selfmod+1
.selfmod
    jsr $0000
    ENDM

    MAC usr
    pla                 ; get function address
    sta .selfmod+2
    pla
    sta .selfmod+1
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
	pha
	ENDM
    
    ; Push random integer on stack
    MAC rndw
	jsr STDLIB_RND
	lda random
	pha
	lda random+1
	pha
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
	sta reserved1
	pla
	sta reserved0
	pla
	tay
	pla
	tax
	lda #reserved0
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
	lda #$00
	pha
	ENDM
	
	MAC ferrw
	ferrb
	lda #$00
	pha
	ENDM
	
	MAC curpos
	pla
	tay
	pla
	tax
	clc
	jsr PLOT
	ENDM
	
err_divzero HEX 44 49 56 49 53 49 4F 4E 20 42 59 20 5A 45 52 4F 00

RUNTIME_ERROR	SUBROUTINE
	pla
    tay
    pla
    jsr STDLIB_PRINT
    halt
    
tmp_floatvar HEX 00 00 00 00 00	
