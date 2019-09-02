rem -- Maze generator in XC-BASIC
rem -- by Oliver Hermanni
rem --
rem -- Original BASIC V2 code is from the book
rem -- "Programming the Commodore 64 - The Definitive Guide"
rem -- by Raeto Collin West

rem ==================================
rem = Better random number generator =
rem ==================================
proc randomize(a!, b!)
    poke $2A7, a!
    poke $2A8, b!
asm "
    lda #$ff
    sta $d40e
    sta $d40f
    lda #$80
    sta $d412
rand:
    lda $d41b
    cmp $2A8
    bcs rand
    adc $2A7
    sta $2A9
    "
    \random_number! = peek!($2A9)
endproc

rem =============
rem = vars init =
rem =============

rem = add 81 to 1024, as we don't start at 1024 directly
const sc = 1105
data aa[] = -2, -80, 2, 80
random_number! = 0
dim fi fast
dim s! fast
dim sm! fast
dim j! fast
dim x! fast
dim b fast
dim a fast


start:
    poke $d020,0
    poke $d021,0
    print "{CLR}"
    textat 11,10,"press key to start..."
    wait 198,1
    call randomize(0,10)
    a = sc + random_number! * 80
    call randomize(0,10)
    a = a + random_number! * 2
    asm "
        lda #$a0
        ldx #$00
init_screen:
        sta $0428,x
        sta $0518,x
        sta $0608,x
        sta $06f8,x
        inx
        cpx #$f0
        bne init_screen
        lda #$20
        ldx #$00
clr_last_line:        
        sta $07c0,x
        inx
        cpx #$28
        bne clr_last_line
    "
    for j! = 0 to 23
        textat 39, j!, " "
    next j!
    poke a,4
loop1:
    call randomize(0,3)
    j! = random_number!
    x! = j!
    if s! <= sm! then goto loop2
    sm! = s!
    fi = b
loop2:
    b = a+aa[j!]
    if peek(b) <> 160 then goto loop3
    poke b,j!
    poke a+aa[j!]/2,32
    a = b
    inc s!
    goto loop1
loop3:
    j!=j! + 1 & 3
    if j!<>x! then goto loop2
    j!=peek!(a)
    poke a,32
    dec s!
    if j!>=4 then goto loop4
    a=a-aa[j!]
    goto loop1
loop4:
    poke a,1
    poke fi,2
infinity_loop:
    goto infinity_loop
