	PROCESSOR 6502
	
	MAC opt_pbyte_pbyte_addb
	lda {1}
	clc
	adc {2}
	IF !FPUSH
	pha
	ENDIF
	ENDM
	
	MAC opt_pbyte_pbyte_subb
	lda {1}
	sec
	sbc {2}
	IF !FPUSH
	pha
	ENDIF
	ENDM
	
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
	
	MAC opt_pbarray_fast_pbyte_subb
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