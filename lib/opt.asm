	
	LIST OFF
	
	; --------------------------------
	; Optimized sequences for ADDITION
	; --------------------------------
	
	; [OPT_MACRO]
	MAC opt_pbyte_pbyte_add
	; > pbyte+pbyte+addb
	; > pbyte+pbvar+addb
	; > pbvar+pbyte+addb
	; > pbvar+pbvar+addb
	; [/OPT_MACRO]
	lda {1}
	clc
	adc {2}
	IF !FPUSH
	pha
	ENDIF
	ENDM
	
	; [OPT_MACRO]
	MAC opt_pword_pwvar_add	
	; > pword+pwvar+addw
	; > pbyte+btow+pwvar+addw
	; [/OPT_MACRO]
	lda <{1}
	clc
	adc {2}
	IF !FPUSH
	pha
	ELSE
	tax
	ENDIF
	lda >{1}
	adc {2}+1
	IF !FPUSH
	pha
	ELSE
	tay
	txa
	ENDIF
	ENDM
	
	; [OPT_MACRO]
	MAC opt_pwvar_pword_add	
	; > pwvar+pword+addw
	; > pwvar+pbyte+btow+addw
	; [/OPT_MACRO]
	lda {1}
	clc
	adc <{2}
	IF !FPUSH
	pha
	ELSE
	tax
	ENDIF
	lda {1}+1
	adc >{2}
	IF !FPUSH
	pha
	ELSE
	tay
	txa
	ENDIF
	ENDM
	
	; [OPT_MACRO]
	MAC opt_pwvar_pwvar_add	
	; > pwvar+pwvar+addw
	; [/OPT_MACRO]
	lda {1}
	clc
	adc {2}
	IF !FPUSH
	pha
	ELSE
	tax
	ENDIF
	lda {1}+1
	adc {2}+1
	IF !FPUSH
	pha
	ELSE
	tay
	txa
	ENDIF
	ENDM
	
	; ------------------------------------
	; Optimized sequences for SUBSTRACTION
	; ------------------------------------
	
	; [OPT_MACRO]
	MAC opt_pbyte_pbyte_sub
	; > pbyte+pbyte+subb
	; > pbyte+pbvar+subb
	; > pbvar+pbyte+subb
	; > pbvar+pbvar+subb
	; [/OPT_MACRO]
	lda {1}
	sec
	sbc {2}
	IF !FPUSH
	pha
	ENDIF
	ENDM
	
	; [OPT_MACRO]
	MAC opt_pword_pwvar_sub
	; > pword+pwvar+subw
	; > pbyte+btow+pwvar+subw
	; [/OPT_MACRO]
	lda <{1}
	sec
	sbc {2}
	IF !FPUSH
	pha
	ELSE
	tax
	ENDIF
	lda >{1}
	sbc {2}+1
	IF !FPUSH
	pha
	ELSE
	tay
	txa
	ENDIF
	ENDM
	
	; [OPT_MACRO]
	MAC opt_pwvar_pword_sub
	; > pwvar+pword+subw
	; > pwvar+pbyte+btow+subw
	; [/OPT_MACRO]
	lda {1}
	sec
	sbc <{2}
	IF !FPUSH
	pha
	ELSE
	tax
	ENDIF
	lda {1}+1
	sbc >{2}
	IF !FPUSH
	pha
	ELSE
	tay
	txa
	ENDIF
	ENDM
	
	; [OPT_MACRO]
	MAC opt_pwvar_pwvar_sub
	; > pwvar+pwvar+subw
	; [/OPT_MACRO]
	lda {1}
	sec
	sbc {2}
	IF !FPUSH
	pha
	ELSE
	tax
	ENDIF
	lda {1}+1
	sbc {2}+1
	IF !FPUSH
	pha
	ELSE
	tay
	txa
	ENDIF
	ENDM
	
	; ----------------------------------
	; Optimized sequences for LOGICAL OR
	; ----------------------------------
	
	; [OPT_MACRO]
	MAC opt_pbyte_pbyte_or
	; > pbyte+pbyte+orb
	; > pbyte+pbvar+orb
	; > pbvar+pbyte+orb
	; > pbvar+pbvar+orb
	; [/OPT_MACRO]
	lda {1}
	ora {2}
	IF !FPUSH
	pha
	ENDIF
	ENDM
	
	; -----------------------------------
	; Optimized sequences for LOGICAL AND
	; -----------------------------------
	
	; [OPT_MACRO]
	MAC opt_pbyte_pbyte_and
	; > pbyte+pbyte+andb
	; > pbyte+pbvar+andb
	; > pbvar+pbyte+andb
	; > pbvar+pbvar+andb
	; [/OPT_MACRO]
	lda {1}
	and {2}
	IF !FPUSH
	pha
	ENDIF
	ENDM
	
	; -----------------------------------
	; Optimized sequences for LOGICAL XOR
	; -----------------------------------
	
	; [OPT_MACRO]
	MAC opt_pbyte_pbyte_xor
	; > pbyte+pbyte+xorb
	; > pbyte+pbvar+xorb
	; > pbvar+pbyte+xorb
	; > pbvar+pbvar+xorb
	; [/OPT_MACRO]
	lda {1}
	eor {2}
	IF !FPUSH
	pha
	ENDIF
	ENDM
	
	; ------------------------------------
	; Optimized sequences for ARRAY ACCESS
	; ------------------------------------
	
	; [OPT_MACRO]	
	MAC opt_pbyte_pbarray_fast
	; > pbyte+pbarray_fast
	; > pbvar+pbarray_fast
	; [/OPT_MACRO]
	ldx {1}
	lda {2},x
	IF !FPUSH
	pha
	ENDIF
	ENDM
	
	; [OPT_MACRO]
	MAC opt_pbyte_pbyte_plbarray_fast
	; > pbyte+pbyte+plbarray_fast
	; > pbvar+pbyte+plbarray_fast
	; [/OPT_MACRO]
	lda {1}
	ldx {2}
	sta {3},x
	ENDM
	
	; ----------------------------
	; Optimized sequences for POKE
	; ----------------------------
	
	; [OPT_MACRO]
	MAC poke_const_addr
	; > pword+poke
	; > paddr+poke
	; [/OPT_MACRO]
.ad EQU {1}
	IF !FPULL
	pla
	ENDIF
	sta .ad
	ENDM
	
	; ----------------------------
	; Optimized sequences for PEEK
	; ----------------------------
	
	; [OPT_MACRO]
	MAC peekb_const_addr
	; > pword+peekb
	; > paddr+peekb
	; [/OPT_MACRO]
.ad EQU {1}
	lda .ad
	IF !FPUSH
	pha
	ENDIF
	ENDM
	
	; [OPT_MACRO]
	MAC peekw_const_addr
	; > pword+peekw
	; > paddr+peekw
	; [/OPT_MACRO]
.ad EQU {1}
	lda .ad
	IF !FPUSH
	pha
	lda #$00
	pha
	ELSE
	ldy #$00
	ENDIF
	ENDM
	
	; ----------------------------------
	; Optimized sequences for COMPARISON
	; ----------------------------------

	; [OPT_MACRO]
	MAC pbyte_pbyte_cmpbeq
	; > pbyte+pbyte+cmpbeq
	; > pbyte+pbvar+cmpbeq
	; > pbvar+pbyte+cmpbeq
	; > pbvar+pbvar+cmpbeq
	; [/OPT_MACRO]
	lda {1}
	cmp {2}
	beq .true
	pzero
	IF !FPUSH
	jmp *+6	
	ELSE
	jmp *+5
	ENDIF
.true:
	pone
	ENDM
	
	; [OPT_MACRO]
	MAC pbyte_pbyte_cmpbneq
	; > pbyte+pbyte+cmpbneq
	; > pbyte+pbvar+cmpbneq
	; > pbvar+pbyte+cmpbneq
	; > pbvar+pbvar+cmpbneq
	; [/OPT_MACRO]
	lda {1}
	cmp {2}
	bne .true
	pzero
	IF !FPUSH
	jmp *+6
	ELSE
	jmp *+5
	ENDIF
.true:
	pone
	ENDM
	
	; [OPT_MACRO]
	MAC pbyte_pbyte_cmpblt
	; > pbyte+pbyte+cmpblt
	; > pbyte+pbvar+cmpblt
	; > pbvar+pbyte+cmpblt
	; > pbvar+pbvar+cmpblt
	; [/OPT_MACRO]
	lda {1}
	cmp {2}
	bcs .false
	pone
	IF !FPUSH
	jmp *+6
	ELSE
	jmp *+5
	ENDIF
.false:
	pzero
	ENDM
	
	; [OPT_MACRO]
	MAC pbyte_pbyte_cmpblte
	; > pbyte+pbyte+cmpblte
	; > pbyte+pbvar+cmpblte
	; > pbvar+pbyte+cmpblte
	; > pbvar+pbvar+cmpblte
	; [/OPT_MACRO]
	lda {1}
	cmp {2}
	bcc .true
	beq .true
	pzero
	IF !FPUSH
	jmp *+6
	ELSE
	jmp *+5
	ENDIF
.true:
	pone
	ENDM
	
	; [OPT_MACRO]
	MAC pbyte_pbyte_cmpbgte
	; > pbyte+pbyte+cmpbgte
	; > pbyte+pbvar+cmpbgte
	; > pbvar+pbyte+cmpbgte
	; > pbvar+pbvar+cmpbgte
	; [/OPT_MACRO]
	lda {1}
	cmp {2}
	bcs .true
	pzero
	IF !FPUSH
	jmp *+6
	ELSE
	jmp *+5
	ENDIF
.true:
	pone
	ENDM
	
	; [OPT_MACRO]
	MAC pbyte_pbyte_cmpbgt
	; > pbyte+pbyte+cmpbgt
	; > pbyte+pbvar+cmpbgt
	; > pbvar+pbyte+cmpbgt
	; > pbvar+pbvar+cmpbgt
	; [/OPT_MACRO]
	lda {1}
	cmp {2}
	bcc .false
	beq .false
	pone
	IF !FPUSH
	jmp *+6
	ELSE
	jmp *+5
	ENDIF
.false:
	pzero
	ENDM

	; [OPT_MACRO]
	MAC pbyte_pbyte_cmpbeq_cond
	; > pbyte_pbyte_cmpbeq+cond_stmt
	; [/OPT_MACRO]
	lda {1}
	cmp {2}
	beq *+5
	IFCONST {4}
	jmp {4}
	ELSE
	jmp {3}
	ENDIF
	ENDM

	; [OPT_MACRO]
	MAC pbyte_pbyte_cmpbneq_cond
	; > pbyte_pbyte_cmpbneq+cond_stmt
	; [/OPT_MACRO]
	lda {1}
	cmp {2}
	bne *+5
	IFCONST {4}
	jmp {4}
	ELSE
	jmp {3}
	ENDIF
	ENDM
	
	; [OPT_MACRO]
	MAC pbyte_pbyte_cmpblt_cond
	; > pbyte_pbyte_cmpblt+cond_stmt
	; [/OPT_MACRO]
	lda {1}
	cmp {2}
	bcc *+5	; true
	IFCONST {4}
	jmp {4}
	ELSE
	jmp {3}
	ENDIF
	ENDM

	; [OPT_MACRO]
	MAC pbyte_pbyte_cmpblte_cond
	; > pbyte_pbyte_cmpblte+cond_stmt
	; [/OPT_MACRO]
	lda {1}
	cmp {2}
	bcc *+7	; true
	beq *+5	; true
	IFCONST {4}
	jmp {4}
	ELSE
	jmp {3}
	ENDIF
	ENDM
	
	; [OPT_MACRO]
	MAC pbyte_pbyte_cmpbgt_cond
	; > pbyte_pbyte_cmpbgt+cond_stmt
	; [/OPT_MACRO]
	lda {2}
	cmp {1}
	bcc *+5	; true
	IFCONST {4}
	jmp {4}
	ELSE
	jmp {3}
	ENDIF
	ENDM
	
	; [OPT_MACRO]
	MAC pbyte_pbyte_cmpbgte_cond
	; > pbyte_pbyte_cmpbgte+cond_stmt
	; [/OPT_MACRO]
	lda {1}
	cmp {2}
	bcs *+5	; true
	IFCONST {4}
	jmp {4}
	ELSE
	jmp {3}
	ENDIF
	ENDM

	LIST ON
