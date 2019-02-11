;           JULY 5, 1976
;     BASIC FLOATING POINT ROUTINES
;       FOR 6502 MICROPROCESSOR
;       BY R. RANKIN AND S. WOZNIAK
;
;     CONSISTING OF:
;        NATURAL LOG
;        COMMON LOG
;        EXPONENTIAL (E**X)
;        FLOAT      FIX
;        FADD       FSUB
;        FMUL       FDIV
;
;
;     FLOATING POINT REPRESENTATION (4-BYTES)
;                    EXPONENT BYTE 1
;                    MANTISSA BYTES 2-4
;
;     MANTISSA:    TWO'S COMPLIMENT REPRESENTATION WITH SIGN IN
;       MSB OF HIGH-ORDER BYTE.  MANTISSA IS NORMALIZED WITH AN
;       ASSUMED DECIMAL POINT BETWEEN BITS 5 AND 6 OF THE HIGH-ORDER
;       BYTE.  THUS THE MANTISSA IS IN THE RANGE 1. TO 2. EXCEPT
;       WHEN THE NUMBER IS LESS THAN 2**(-128).
;
;     EXPONENT:    THE EXPONENT REPRESENTS POWERS OF TWO.  THE
;       REPRESENTATION IS 2'S COMPLIMENT EXCEPT THAT THE SIGN
;       BIT (BIT 7) IS COMPLIMENTED.  THIS ALLOWS DIRECT COMPARISON
;       OF EXPONENTS FOR SIZE SINCE THEY ARE STORED IN INCREASING
;       NUMERICAL SEQUENCE RANGING FROM $00 (-128) TO $FF (+127)
;       ($ MEANS NUMBER IS HEXADECIMAL).
;
;     REPRESENTATION OF DECIMAL NUMBERS:    THE PRESENT FLOATING
;       POINT REPRESENTATION ALLOWS DECIMAL NUMBERS IN THE APPROXIMATE
;       RANGE OF 10**(-38) THROUGH 10**(38) WITH 6 TO 7 SIGNIFICANT
;       DIGITS.
;
	PROCESSOR 6502

SIGN	EQU	$57
X2		EQU $58
M2		EQU	$59 ; 5a 5b 5c
X1		EQU	$5d
M1		EQU	$5e ; 5f 60 61
E		EQU	$62 ; 63 64 65
Z		EQU $66 ; 67 68 69
T		EQU	$6a ; 6b 6c 6d
SEXP	EQU $6e ; 6f 70 71
INT		EQU $72

LOG    lda M1
       beq ERROR
       bpl CONT    
ERROR  brk         
;
CONT   jsr SWAP    
       lda X2      
       ldy #$80
       sty X2      
       eor #$80    
       sta M1+1    
       lda #0
       sta M1      
       jsr FLOAT   
       ldx #3      
SEXP1  lda X2,x
       sta Z,x     
       lda X1,x
       sta SEXP,x  
       lda R22,x   
       sta X1,x
       dex
       bpl SEXP1
       jsr FSUB    
       ldx #3      
SAVET  lda X1,x    
       sta T,x
       lda Z,x     
       sta X1,x
       lda R22,x   
       sta X2,x
       dex
       bpl SAVET
       jsr FADD    
       ldx #3      
TM2    lda T,x
       sta X2,x    
       dex
       bpl TM2
       jsr FDIV    
       ldx #3      
MIT    lda X1,x
       sta T,x     
       sta X2,x    
       dex
       bpl MIT
       jsr FMUL    
       jsr SWAP    
       ldx #3      
MIC    lda C,x
       sta X1,x    
       dex
       bpl MIC
       jsr FSUB    
       ldx #3      
M2MB   lda MB,x
       sta X2,x    
       dex
       bpl M2MB
       jsr FDIV    
       ldx #3
M2A1   lda A1,x
       sta X2,x    
       dex
       bpl M2A1
       jsr FADD    
       ldx #3      
M2T    lda T,x
       sta X2,x    
       dex
       bpl M2T
       jsr FMUL    
       ldx #3      
M2MHL  lda MHLF,x
       sta X2,x    
       dex
       bpl M2MHL
       jsr FADD    
       ldx #3      
LDEXP  lda SEXP,x
       sta X2,x    
       dex
       bpl LDEXP
       jsr FADD    
       ldx #3      
MLE2   lda LE2,x
       sta X2,x    
       dex
       bpl MLE2
       jsr FMUL    
       rts         
;
;     COMMON LOG OF MANT/EXP1 RESULT IN MANT/EXP1
;
LOG10  jsr LOG     
       ldx #3
L10    lda LN10,x
       sta X2,x    
       dex
       bpl L10
       jsr FMUL    
       rts
;
LN10   HEX 7e 6f 2d ed
R22    HEX 80 5a 02 7a
LE2    HEX 7f 58 b9 0c
A1     HEX 80 52 80 40
MB     HEX 81 ab 86 49
C      HEX 80 6a 08 66
MHLF   HEX 7f 40 00 00

;
;     EXP OF MANT/EXP1 RESULT IN MANT/EXP1
;
EXP    ldx #3      
       lda L2E,x
       sta X2,x    
       dex
       bpl EXP+2
       jsr FMUL    
       ldx #3      
FSA    lda X1,x
       sta Z,x     
       dex
       bpl FSA     
       jsr FIX     
       lda M1+1
       sta INT     
       sec         
       sbc #124    
       lda M1
       sbc #0
       bpl OVFLW   
       clc         
       lda M1+1
       adc #120    
       lda M1
       adc #0
       bpl CONTIN  
       lda #0      
       ldx #3      
ZERO   sta X1,x    
       dex
       bpl ZERO
       rts         
;
OVFLW  brk         
;
CONTIN jsr FLOAT   
       ldx #3
ENTD   lda Z,x
       sta X2,x    
       dex
       bpl ENTD
       jsr FSUB    
       ldx #3      
ZSAV   lda X1,x
       sta Z,x     
       sta X2,x    
       dex
       bpl ZSAV
       jsr FMUL    
       ldx #3      
LA2    lda A2,x
       sta X2,x    
       lda X1,x
       sta SEXP,x  
       dex
       bpl LA2
       jsr FADD    
       ldx #3      
LB2    lda B2,x
       sta X2,x    
       dex
       bpl LB2
       jsr FDIV    
       ldx #3      
DLOAD  lda X1,x
       sta T,x     
       lda C2,x
       sta X1,x    
       lda SEXP,x
       sta X2,x    
       dex
       bpl DLOAD
       jsr FMUL    
       jsr SWAP    
       ldx #3      
LTMP   lda T,x
       sta X1,x    
       dex
       bpl LTMP
       jsr FSUB    
       ldx #3      
LDD    lda D,x
       sta X2,x    
       dex
       bpl LDD
       jsr FADD    
       jsr SWAP    
       ldx #3      
LFA    lda Z,x
       sta X1,x    
       dex
       bpl LFA
       jsr FSUB    
       ldx #3      
LF3    lda Z,x
       sta X2,x    
       dex
       bpl LF3
       jsr FDIV    
       ldx #3      
LD12   lda MHLF,x
       sta X2,x    
       dex
       bpl LD12
       jsr FADD    
       sec         
       lda INT     
       adc X1      
       sta X1      
       rts         
       
L2E    HEX 80 5c 55 1e
A2     HEX 86 57 6a e1
B2     HEX 89 4d 3f 1d
C2     HEX 7b 46 fa 70
D      HEX 83 4f a3 03

;
;
;     BASIC FLOATING POINT ROUTINES
;

ADD    clc         
       ldx #$02    
ADD1   lda M1,x
       adc M2,x    
       sta M1,x
       dex         
       bpl ADD1    
       rts         
MD1    asl SIGN    
       jsr ABSWAP  
ABSWAP bit M1      
       bpl ABSWP1  
       jsr FCOMPL  
       inc SIGN    
ABSWP1 sec         
;
;     SWAP EXP/MANT1 WITH EXP/MANT2
;
SWAP   ldx #$04    
SWAP1  sty E-1,x
       lda X1-1,x  
       ldy X2-1,x  
       sty X1-1,x  
       sta X2-1,x
       dex         
       bne SWAP1   
       rts
;
;
;
;     CONVERT 16 BIT INTEGER IN M1(HIGH) AND M1+1(LOW) TO F.P.
;     RESULT IN EXP/MANT1.  EXP/MANT2 UNEFFECTED
;
;
FLOAT  lda #$8E
       sta X1      
       lda #0      
       sta M1+2
       beq NORM    
NORM1  dec X1      
       asl M1+2
       rol M1+1    
       rol M1
NORM   lda M1      
       asl         
       eor M1
       bmi RTS1    
       lda X1      
       bne NORM1   
RTS1   rts         
;
;
;     EXP/MANT2-EXP/MANT1 RESULT IN EXP/MANT1
;
FSUB   jsr FCOMPL  
SWPALG jsr ALGNSW  
;
;     ADD EXP/MANT1 AND EXP/MANT2 RESULT IN EXP/MANT1
;
FADD   lda X2
       cmp X1      
       bne SWPALG  
       jsr ADD     
ADDEND bvc NORM    
       bvs RTLOG   
ALGNSW bcc SWAP    
RTAR   lda M1      
       asl         
RTLOG  inc X1      
       beq OVFL    
RTLOG1 ldx #$FA    
ROR1   lda #$80
       bcs ROR2
       asl
ROR2   lsr E+3,x   
       ora E+3,x
       sta E+3,x
       inx         
       bne ROR1    
       rts         
;
;
;     EXP/MANT1 X EXP/MANT2 RESULT IN EXP/MANT1
;
FMUL   jsr MD1     
       adc X1      
       jsr MD2     
       clc         
MUL1   jsr RTLOG1  
       bcc MUL2    
       jsr ADD     
MUL2   dey         
       bpl MUL1    
MDEND  lsr SIGN    
NORMX  bcc NORM    
FCOMPL sec         
       ldx #$03    
COMPL1 lda #$00    
       sbc X1,x    
       sta X1,x    
       dex         
       bne COMPL1  
       beq ADDEND  
;
;
;     EXP/MANT2 / EXP/MANT1 RESULT IN EXP/MANT1
;
FDIV   jsr MD1     
       sbc X1      
       jsr MD2     
DIV1   sec         
       ldx #$02    
DIV2   lda M2,x
       sbc E,x     
       pha         
       dex         
       bpl DIV2    
       ldx #$FD    
DIV3   pla         
       bcc DIV4    
       sta M2+3,x
DIV4   inx         
       bne DIV3    
       rol M1+2
       rol M1+1    
       rol M1
       asl M2+2
       rol M2+1    
       rol M2
       bcs OVFL    
       dey         
       bne DIV1    
       beq MDEND   
MD2    stx M1+2
       stx M1+1    
       stx M1
       bcs OVCHK   
       bmi MD3     
       pla         
       pla         
       bcc NORMX   
MD3    eor #$80    
       sta X1      
       ldy #$17    
       rts         
OVCHK  bpl MD3     
OVFL   brk
;
;
;     CONVERT EXP/MANT1 TO INTEGER IN M1 (HIGH) AND M1+1(LOW)
;      EXP/MANT2 UNEFFECTED
;
       jsr RTAR    
FIX    lda X1      
       cmp #$8E    
       bne FIX-3   
RTRN   rts         
