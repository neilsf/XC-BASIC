const SCREEN1 = $2800
const SCREEN2 = $2c00
const CHARSET = $2000
const BORDER = $d020
const BACKGR = $d021
const COLOR = $d800

dim c1A! fast
dim c1B! fast
dim c2A! fast
dim c2B! fast

c1A! = 0
c1B! = 0
c2A! = 0
c2B! = 0

proc doplasma(screen)
  dim xbuf![40]
  dim ybuf![25]

  dim i! fast
  dim x! fast
  dim y! fast
  dim c1a! fast
  dim c1b! fast
  dim c2a! fast
  dim c2b! fast

  c1a! = \c1A! : c1b! = \c1B!

  i! = 0
  repeat
    ybuf![i!] = \sntable![c1a!] + \sntable![c1b!]
    inc c1a! : inc c1a! : inc c1a! : inc c1a!
    c1b! = c1b! + 9
    inc i!
  until i! = 25

  inc \c1A! : inc \c1A! : inc \c1A!
  dec \c1B! : dec \c1B! : dec \c1B! : dec \c1B! : dec \c1B!

  c2a! = \c2A! : c2b! = \c2B!

  i! = 0
  repeat
    xbuf![i!] = \sntable![c2a!] + \sntable![c2b!]
    inc c2a! : inc c2a! : inc c2a!
    c2b! = c2b! + 7
    inc i!
  until i! = 40

  inc \c2A! : inc \c2A!
  dec \c2B! : dec \c2B!

  cursor = screen
  y! =0
  repeat
    x! = 0
    repeat
        poke cursor, xbuf![x!] + ybuf![y!]
	inc x!
	inc cursor
    until x! = 40
    inc y!
  until y! = 25

endproc

proc makecharset(address)
  print "{CLR}"
  textat 15,10,"loading..."
  c! = 0
  loop:
    s! = \sntable![c!]
    for i! = 0 to 7
      b! = 0
      for ii! = 0 to 7
        if rnd!() & 255 > s! then b! = b! | \bittab![ii!]
      next ii!
      poke address + c! * 8 + i!, b!
    next i!
    inc c!
    if c! > 0 then goto loop
endproc

asm "
    sei"
poke BORDER, 6 : poke BACKGR, 6
memset COLOR, 1000, 0
call makecharset(CHARSET)
loop:
  call doplasma(SCREEN1)
  poke $d018, %10101000
  call doplasma(SCREEN2)
  poke $d018, %10111000
  goto loop

data bittab![] = 1, 2, 4, 8, 16, 32, 64, 128

data sntable![] = ~
$7f, $82, $85, $88, $8b, $8f, $92, $95, $98, $9b, $9e, $a1, $a4, $a7, $aa, $ad,  ~
$b0, $b3, $b6, $b8, $bb, $be, $c1, $c3, $c6, $c8, $cb, $cd, $d0, $d2, $d5, $d7,  ~
$d9, $db, $dd, $e0, $e2, $e4, $e5, $e7, $e9, $eb, $ec, $ee, $ef, $f1, $f2, $f4,  ~
$f5, $f6, $f7, $f8, $f9, $fa, $fb, $fb, $fc, $fd, $fd, $fe, $fe, $fe, $fe, $fe,  ~
$ff, $fe, $fe, $fe, $fe, $fe, $fd, $fd, $fc, $fb, $fb, $fa, $f9, $f8, $f7, $f6,  ~
$f5, $f4, $f2, $f1, $ef, $ee, $ec, $eb, $e9, $e7, $e5, $e4, $e2, $e0, $dd, $db,  ~
$d9, $d7, $d5, $d2, $d0, $cd, $cb, $c8, $c6, $c3, $c1, $be, $bb, $b8, $b6, $b3,  ~
$b0, $ad, $aa, $a7, $a4, $a1, $9e, $9b, $98, $95, $92, $8f, $8b, $88, $85, $82,  ~
$7f, $7c, $79, $76, $73, $6f, $6c, $69, $66, $63, $60, $5d, $5a, $57, $54, $51,  ~
$4e, $4b, $48, $46, $43, $40, $3d, $3b, $38, $36, $33, $31, $2e, $2c, $29, $27,  ~
$25, $23, $21, $1e, $1c, $1a, $19, $17, $15, $13, $12, $10, $0f, $0d, $0c, $0a,  ~
$09, $08, $07, $06, $05, $04, $03, $03, $02, $01, $01, $00, $00, $00, $00, $00,  ~
$00, $00, $00, $00, $00, $00, $01, $01, $02, $03, $03, $04, $05, $06, $07, $08,  ~
$09, $0a, $0c, $0d, $0f, $10, $12, $13, $15, $17, $19, $1a, $1c, $1e, $21, $23,  ~
$25, $27, $29, $2c, $2e, $31, $33, $36, $38, $3b, $3d, $40, $43, $46, $48, $4b,  ~
$4e, $51, $54, $57, $5a, $5d, $60, $63, $66, $69, $6c, $6f, $73, $76, $79, $7c