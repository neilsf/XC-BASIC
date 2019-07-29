	PROCESSOR 6502
	
	; [OPT_MACRO]
	MAC opt_pbyte_plbtovar
	; > pbyte+plb2var
	; > pbvar+plb2var
	; [/OPT_MACRO]
	lda {1}
	sta {2}
	ENDM
	
	
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
	; pbarray_fast+pbyte+addb
	; pbarray_fast+pbvar+addb
	; [/OPT_MACRO]
	MAC opt_pbarray_fast_pbyte_addb
	IF !FPULL
	pla
	ENDIF
	tax
	lda.wx {1}
	clc
	adc {2}
	IF !FPUSH
	pha
	ENDIF
	ENDM
	
	; [OPT_MACRO]
	; pbyte+pbarray_fast+addb
	; pbvar+pbarray_fast+addb
	; [/OPT_MACRO]
	MAC opt_pbyte_pbarray_fast_subb
	IF !FPULL
	pla
	ENDIF
	tax
	lda.wx {1}
	sec
	sbc {2}
	IF !FPUSH
	pha
	ENDIF
	ENDM
	
	MAC opt_pbyte_pbyte_cmpblt
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
	
	MAC opt_pbyte_pbyte_cmpblte
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
	
	MAC opt_pword_pword_addw
	lda #<{1}
	clc
	adc #<{2}
	pha
	lda #>{1}
	adc #>{2}
	IF !FPUSH
	pha
	ELSE
	tay
	pla
	ENDIF
	ENDM
	
	MAC opt_pword_pword_subw
	lda #<{1}
	sec
	sbc #<{2}
	pha
	lda #>{1}
	sbc #>{2}
	IF !FPUSH
	pha
	ELSE
	tay
	pla
	ENDIF
	ENDM
