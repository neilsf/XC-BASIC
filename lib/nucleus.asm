
reserved0	EQU $fb
reserved1	EQU $fc

reserved2	EQU $fd
reserved3	EQU $fe

reserved4	EQU $02
reserved5	EQU $03

reserved6	EQU $04
reserved7	EQU $05

reserved8	EQU $06
reserved9	EQU $07

reservedA	EQU $08
reservedB	EQU $09


stack 		EQU $0100

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
	
	; Push one word variable on the stack
	MAC pwvar
	lda.w {1}
	pha
	lda.w {1}+1
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
	
	; Add bytes on stack
	MAC addb
	pla
	tsx
	clc
	adc.wx stack+1
	sta.wx stack+1
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
	plw2var reserved0
	plw2var reserved2
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

	; poke routine
	; requires that arguments are pushed backwards (value first)
	MAC poke
	pla
	sta reserved1
	pla
	sta reserved0
	ldy #$00
	pla ;discard high byte
	pla
	sta (reserved0),y
	ENDM

	MAC for
	; max value already pushed
	; push address
	lda #<*
	pha
	lda #>*
	pha
	ENDM

	MAC next
	; usage next variable
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

	MAC peek
	pla
	sta reserved1
	pla
	sta reserved0
	ldy #$00
	lda (reserved0),y
	pha
	pzero
	ENDM

	MAC inkey
	jsr KERNAL_GETIN
	pha
	lda #0
	pha
	ENDM

; init program: save stack pointer and seed rnd
	MAC init_program
	tsx
	stx RESERVED_STACK_POINTER
	seed_rnd
	ENDM

; end program: restorre stack pointer and exit
	MAC halt
	ldx RESERVED_STACK_POINTER
	txs
	rts
	ENDM

	MAC iinc
	inc {1}
	bne .skip
	inc {1}+1
.skip
	ENDM

	MAC idec
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

err_divzero HEX 44 49 56 49 53 49 4F 4E 20 42 59 20 5A 45 52 4F 00

RUNTIME_ERROR	SUBROUTINE
	pla
    tay
    pla
    jsr STDLIB_PRINT
    halt
	
