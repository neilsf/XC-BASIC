rem -----------------------------------
rem -- PURALAX!
rem --
rem -- C64 port of the game found at
rem -- http://www.puralax.com/
rem --
rem -- Written in XC=BASIC
rem -- by Csaba Fekete
rem -----------------------------------

const VIC_MEMSETUP = 53272
const SCREEN = 1024
const COLOR = 55296
const BORDER = 53280
const BACKGR = 53281

const VIC_SPRON = $d015
const VIC_SPRW = $d017
const VIC_PTRS = $d018
const VIC_SPRC = $d01c
const VIC_SPRH = $d01d
const VIC_SPR0X = $d000
const VIC_SPR0Y = $d001
const VIC_SPRX9 = $d010
const VIC_SPR0COL = $d027
const SPR0SHAPE = $07f8

const LEVEL_COUNT! = 25

const SPR_SHAPE_SQUA! = 159
const SPR_SHAPE_FRAM! = 164

const LEVEL_SIZE_SMALL! = 0
const LEVEL_SIZE_BIG! = 1

rem -----------------------------------
rem -- global vars
rem -----------------------------------

let current_level_no! = 0
let current_target_color! = 0
let current_level_size! = LEVEL_SIZE_SMALL!
dim current_level_colors![64]
dim current_level_dots![64]
let \current_level_shifted! = 0

cursor_posx! = 3 : cursor_posy! = 2
success! = 0

goto start

rem -----------------------------------
rem -- music and graphics data
rem -----------------------------------

origin $1000
incbin "another_time.sid"

origin $2000
incbin "charset_inv.bin"

origin $2600
incbin "sprites.bin"

rem -----------------------------------
rem -- clear the screen
rem -----------------------------------

proc cls
  for i=\SCREEN to \SCREEN+999
    poke i, 32
  next i
  for i=\COLOR to \COLOR+999
    poke i, 15
  next i
endproc

rem -----------------------------------
rem - Configure sprites
rem -----------------------------------

proc configure_sprites
  rem all sprites off for now
	poke \VIC_SPRON, 0
  rem sprites 1-2 double size
	poke \VIC_SPRW, %00000011
  poke \VIC_SPRH, %00000011
	rem single color sprites
	poke \VIC_SPRC, 254
endproc

rem -----------------------------------
rem -- draw one square in the given 
rem -- position
rem -----------------------------------

proc draw_square(pos!, color!, dots!)
  offset = \square_pos[pos!]
  if offset = 0 then return
  offset = offset + \current_level_shifted! * 86
  color_offset = offset + 54272
  char! = 0
  for i!=0 to 3
    for j!=0 to 3
      poke offset, \square_pattern![char!]
      poke color_offset, color!
      inc offset
      inc color_offset
      inc char!
    next j!
    offset = offset+36
    color_offset = color_offset+36
  next i!
  offset = \square_pos[pos!] + \current_level_shifted! * 86
  if dots! = 0 then return
  poke offset, 79
  if dots! = 1 then return
  if dots! = 2 then poke offset+1, 80 ~
    else poke offset+1, 81
endproc

rem -----------------------------------
rem -- draw one small square in the  
rem -- given position
rem -----------------------------------

proc draw_square_sm(pos!, color!, dots!)
  let offset = \square_pos_sm[pos!]
  let color_offset = offset + 54272
  let char! = 0
  for i!=0 to 2
    for j!=0 to 2
      poke offset, \square_pattern_sm![char!]
      poke color_offset, color!
      inc offset
      inc color_offset
      inc char!
    next j!
    let offset = offset+37
    let color_offset = color_offset+37
  next i!
  let offset = \square_pos_sm[pos!]
  if dots! = 0 then return
  poke offset, 79
  if dots! = 1 then return
  if dots! = 2 then poke offset+1, 80 ~
    else poke offset+1, 81
endproc

rem -----------------------------------
rem - load level
rem -----------------------------------

proc load_level(level_no!)
  ptr = cast(level_no!) * 64
  settings! = \levelsettings![level_no!]
  \current_level_size! = \LEVEL_SIZE_SMALL!
  \current_level_shifted! = 0
  \current_target_color! = settings! & %00001111
  leveltype! = (settings! & %11110000) / 16
  
  if leveltype! = 2 then \current_level_size! = \LEVEL_SIZE_BIG!
  if leveltype! = 1 then \current_level_size! = \LEVEL_SIZE_SMALL! : \current_level_shifted! = 1

  for i! = 0 to 63
    \current_level_colors![i!] = \leveldata![ptr] & %00001111
    \current_level_dots![i!] = \leveldata![ptr] / 16
    inc ptr
  next i!
  \cursor_posx! = 3 : \cursor_posy! = 2
endproc

rem -----------------------------------
rem - draw the current level
rem -----------------------------------

proc draw_level
  dim buffer![5]
  password$ = @buffer!
  all_passes$ = @\levelpass!

  call cls
  if \current_level_size! = \LEVEL_SIZE_SMALL! then gosub draw_squares else gosub draw_squares_sm

  shapeoffset = \current_level_size! * 250
  textat 0, 24, "level"
  textat 5, 24, \current_level_no! + 1
  textat 16, 24, "target"
  textat 31,24, "pass"

  passindex = cast(\current_level_no! * 4)
  strncpy password$, all_passes$ + passindex, 4
  textat 36, 24, password$
  
  charat 23, 24, 78
  poke 56279, \current_target_color!
  
  poke \VIC_SPRON, 1
  poke \VIC_SPR0X, 167 + \current_level_shifted! * 48 - \current_level_size! * 8
  poke \VIC_SPR0Y, 121 + \current_level_shifted! * 16 - \current_level_size! * 24
  poke $d010, 0
  poke \SPR0SHAPE, \SPR_SHAPE_FRAM! - \current_level_size! * 6
  poke \VIC_SPR0COL, 1
  return

  draw_squares:
    for i! = 0 to 39
      call draw_square(i!, \current_level_colors![i!], \current_level_dots![i!])
    next i!
    return

  draw_squares_sm:
    for i! = 0 to 63
      call draw_square_sm(i!, \current_level_colors![i!], \current_level_dots![i!])
    next i!
    return
endproc

rem -----------------------------------
rem - start music
rem -----------------------------------

proc start_music
  const CONF_MUSIC = $1000
  const MUSIC_ENTRY =	$1003

  asm "  sei"
  doke $314, @irq_routine
  poke $d011, $1b
  poke $d012, $e4
  poke $dc0d, %01111111
  poke $d01a, %00000001
  poke $d019, %00000001
  asm "
    lda #$00
    jsr $1000
    cli"
  return

  irq_routine:
    asm "
    lda #$01
    sta $d019
    jsr $1003
    asl $d019
    jmp $ea31"
endproc

rem -----------------------------------
rem - set color/dots under cursor
rem -----------------------------------

proc set_under_cursor(color!, dots!)
  pos! = \cursor_posy! * 8 + \cursor_posx!
  \current_level_colors![pos!] = color!
  \current_level_dots![pos!] = dots!
  if \current_level_size! = \LEVEL_SIZE_SMALL! then ~
    call draw_square(pos!, color!, dots!) ~
  else ~
    call draw_square_sm(pos!, color!, dots!)
endproc

rem -----------------------------------
rem - paint all neighbours to same
rem - color recursively
rem -
rem - some vars were moved out to
rem - the global scope to prevent
rem - stack overflow
rem -----------------------------------

let pn_pos! = 0
let pn_color! = 0
let pn_ocolor! = 0
let pn_tcolor! = 0

proc paint_neighbours(posx!, posy!)
  if posy! > 0 then dec posy! : gosub test : inc posy!
  if posx! < 7 then inc posx! : gosub test : dec posx!
  if posy! < 7 then inc posy! : gosub test : dec posy!
  if posx! > 0 then dec posx! : gosub test : inc posx!
  return

  test:
    \pn_pos! = posy! * 8 + posx!
    \pn_color! = \current_level_colors![\pn_pos!]
    if \pn_color! <> \pn_ocolor! or \pn_color! = \pn_tcolor! then return
    \current_level_colors![\pn_pos!] = \pn_tcolor!
    if \current_level_size! = \LEVEL_SIZE_SMALL! then ~
      call draw_square(\pn_pos!, \pn_tcolor!, \current_level_dots![\pn_pos!]) ~
    else ~
      call draw_square_sm(\pn_pos!, \pn_tcolor!, \current_level_dots![\pn_pos!])
          
    call paint_neighbours(posx!, posy!)
    return
endproc

rem -----------------------------------
rem - test if level is done
rem -----------------------------------

proc test_level_done(result)
  nonmatching! = 0
  for i! = 0 to 63
    color! = \current_level_colors![i!]
    if color! <> \current_target_color! and color! <> $0b then ~
      if color! <> $0c then inc nonmatching!
  next i!
  if nonmatching! = 0 then poke result, 1 else poke result, 0
endproc

rem -----------------------------------
rem - test if level is stuck
rem -----------------------------------

proc test_level_stuck(result)
  dots! = 0
  for i! = 0 to 63
    dots! = dots! + \current_level_dots![i!]
  next i!
  if dots! > 0 then poke result, 0 else poke result, 1
endproc

rem -----------------------------------
rem - play level
rem - arg success will be set to 0 or 1
rem -----------------------------------

proc play_level(success)

  if \current_level_size! = \LEVEL_SIZE_BIG! then ~
    boundary_x! = 7 : boundary_y! = 7 : distance! = 24 : shapeoffset! = 250 ~
    else boundary_x! = 6 : boundary_y! = 4 : distance! = 32 : shapeoffset! = 0

  sq_selected! = 0
  lstate! = 0
  loop:
    joy! = peek!(56320)
    if joy! = 126 then gosub move_up : goto ack_move
    if joy! = 125 then gosub move_down : goto ack_move
    if joy! = 119 then gosub move_right : goto ack_move
    if joy! = 123 then gosub move_left : goto ack_move
    if joy! = 111 and sq_selected! = 0 then gosub select_square : goto ack_move
    if joy! = 111 and sq_selected! = 1 then gosub deselect_square : goto ack_move
    goto loop
    ack_move:
      for j=0 to 1000 : next j
    call test_level_done(@lstate!)
    if lstate! = 1 then poke success, 1 : return
    call test_level_stuck(@lstate!)
    if lstate! = 1 then poke success, 0 : return
  goto loop

  move_up:
    if \cursor_posy! = 0 then return
    if sq_selected! = 1 then goto bring_up
    for i! = 1 to distance!
      gosub wait_frame
      poke \VIC_SPR0Y, peek!(\VIC_SPR0Y)-1
    next i!
    dec \cursor_posy!
    return

  move_down:
    if \cursor_posy! = boundary_y! then return
    if sq_selected! = 1 then goto bring_down
    for i! = 1 to distance!
      gosub wait_frame
      poke \VIC_SPR0Y, peek!(\VIC_SPR0Y)+1
    next i!
    inc \cursor_posy!
    return

  move_right:
    if \cursor_posx! = boundary_x! then return
    if sq_selected! = 1 then goto bring_right
    for i! = 1 to distance!
      gosub wait_frame
      if peek!(\VIC_SPR0X) = 255 then poke \VIC_SPRX9, 1
      poke \VIC_SPR0X, peek!(\VIC_SPR0X)+1
    next i!
    inc \cursor_posx!
    return

  move_left:
    if \cursor_posx! = 0 then return
    if sq_selected! = 1 then goto bring_left
    for i! = 1 to distance!
      gosub wait_frame
      if peek!(\VIC_SPR0X) = 0 then poke \VIC_SPRX9, 0
      poke \VIC_SPR0X, peek!(\VIC_SPR0X)-1
    next i!
    dec \cursor_posx!
    return

  select_square:
    pos! = \cursor_posy! * 8 + \cursor_posx!
    color! = \current_level_colors![pos!]
    if color! = $0b or color! = $0c then return
    dots! = \current_level_dots![pos!]
    if dots! = 0 then return
    poke \SPR0SHAPE, \SPR_SHAPE_SQUA! + shapeoffset! + dots!
    poke \VIC_SPR0COL, color!
    sq_selected! = 1 
    return

  deselect_square:
    poke \SPR0SHAPE, \SPR_SHAPE_FRAM! + shapeoffset!
    poke \VIC_SPR0COL, 1
    sq_selected! = 0
    return

  bring_up:
    neighbour_pos! = (\cursor_posy! - 1) * 8 + \cursor_posx!
    neighbour_color! = \current_level_colors![neighbour_pos!]
    neighbour_dots! = \current_level_dots![neighbour_pos!]
    pos! = \cursor_posy! * 8 + \cursor_posx!
    dots! = \current_level_dots![pos!]
    color! = \current_level_colors![pos!]
    if neighbour_color! = $0b or neighbour_color! = color! then return
    if neighbour_color! = $0c then gosub bring_up_onto_grey else gosub bring_up_onto_color
    return

    bring_up_onto_grey:
      call set_under_cursor($0c, 0)
      for i! = 1 to distance!
        gosub wait_frame
        poke \VIC_SPR0Y, peek!(\VIC_SPR0Y)-1
      next i!
      dec \cursor_posy!
      call set_under_cursor(color!, dots! -1)
      poke \SPR0SHAPE, peek!(\SPR0SHAPE)-1
      if dots! = 1 then gosub deselect_square
      return

    bring_up_onto_color:
      call set_under_cursor(color!, dots! - 1)
      dec \cursor_posy!
      call set_under_cursor(color!, neighbour_dots!)
      \pn_ocolor! = neighbour_color!
      \pn_tcolor! = color!
      call paint_neighbours(\cursor_posx!, \cursor_posy!)
      inc \cursor_posy!
      poke \SPR0SHAPE, peek!(\SPR0SHAPE)-1
      if dots! = 1 then gosub deselect_square
      return
  rem -- bring_up end

  bring_down:
    neighbour_pos! = (\cursor_posy! + 1) * 8 + \cursor_posx!
    neighbour_color! = \current_level_colors![neighbour_pos!]
    neighbour_dots! = \current_level_dots![neighbour_pos!]
    pos! = \cursor_posy! * 8 + \cursor_posx!
    dots! = \current_level_dots![pos!]
    color! = \current_level_colors![pos!]
    if neighbour_color! = $0b or neighbour_color! = color! then return
    if neighbour_color! = $0c then gosub bring_down_onto_grey else gosub bring_down_onto_color
    return

    bring_down_onto_grey:
      call set_under_cursor($0c, 0)
      for i! = 1 to distance!
        gosub wait_frame
        poke \VIC_SPR0Y, peek!(\VIC_SPR0Y) + 1
      next i!
      inc \cursor_posy!
      call set_under_cursor(color!, dots! - 1)
      poke \SPR0SHAPE, peek!(\SPR0SHAPE)-1
      if dots! = 1 then gosub deselect_square
      return

    bring_down_onto_color:
      call set_under_cursor(color!, dots! - 1)
      inc \cursor_posy!
      call set_under_cursor(color!, neighbour_dots!)
      \pn_ocolor! = neighbour_color!
      \pn_tcolor! = color!
      call paint_neighbours(\cursor_posx!, \cursor_posy!)
      dec \cursor_posy!
      poke \SPR0SHAPE, peek!(\SPR0SHAPE)-1
      if dots! = 1 then gosub deselect_square
      return
  rem -- bring_down end

  bring_right:
    neighbour_pos! = \cursor_posy! * 8 + \cursor_posx! + 1
    neighbour_color! = \current_level_colors![neighbour_pos!]
    neighbour_dots! = \current_level_dots![neighbour_pos!]
    pos! = \cursor_posy! * 8 + \cursor_posx!
    dots! = \current_level_dots![pos!]
    color! = \current_level_colors![pos!]
    if neighbour_color! = $0b or neighbour_color! = color! then return
    if neighbour_color! = $0c then gosub bring_right_onto_grey else gosub bring_right_onto_color
    return

    bring_right_onto_grey:
      call set_under_cursor($0c, 0)
      for i! = 1 to distance!
        gosub wait_frame
        if peek!(\VIC_SPR0X) = 255 then poke \VIC_SPRX9, 1
        poke \VIC_SPR0X, peek!(\VIC_SPR0X) + 1
      next i!
      inc \cursor_posx!
      call set_under_cursor(color!, dots! - 1)
      poke \SPR0SHAPE, peek!(\SPR0SHAPE)-1
      if dots! = 1 then gosub deselect_square
      return

    bring_right_onto_color:
      call set_under_cursor(color!, dots! - 1)
      inc \cursor_posx!
      call set_under_cursor(color!, neighbour_dots!)
      \pn_ocolor! = neighbour_color!
      \pn_tcolor! = color!
      call paint_neighbours(\cursor_posx!, \cursor_posy!)
      dec \cursor_posx!
      poke \SPR0SHAPE, peek!(\SPR0SHAPE)-1
      if dots! = 1 then gosub deselect_square
      return
  rem -- bring_right end

  bring_left:
    neighbour_pos! = \cursor_posy! * 8 + \cursor_posx! - 1
    neighbour_color! = \current_level_colors![neighbour_pos!]
    neighbour_dots! = \current_level_dots![neighbour_pos!]
    pos! = \cursor_posy! * 8 + \cursor_posx!
    dots! = \current_level_dots![pos!]
    color! = \current_level_colors![pos!]
    if neighbour_color! = $0b or neighbour_color! = color! then return
    if neighbour_color! = $0c then gosub bring_left_onto_grey else gosub bring_left_onto_color
    return

    bring_left_onto_grey:
      call set_under_cursor($0c, 0)
      for i! = 1 to distance!
        gosub wait_frame
        if peek!(\VIC_SPR0X) = 0 then poke \VIC_SPRX9, 0
        poke \VIC_SPR0X, peek!(\VIC_SPR0X) - 1
      next i!
      dec \cursor_posx!
      call set_under_cursor(color!, dots! - 1)
      poke \SPR0SHAPE, peek!(\SPR0SHAPE)-1
      if dots! = 1 then gosub deselect_square
      return

    bring_left_onto_color:
      call set_under_cursor(color!, dots! - 1)
      dec \cursor_posx!
      call set_under_cursor(color!, neighbour_dots!)
      \pn_ocolor! = neighbour_color!
      \pn_tcolor! = color!
      call paint_neighbours(\cursor_posx!, \cursor_posy!)
      inc \cursor_posx!
      poke \SPR0SHAPE, peek!(\SPR0SHAPE)-1
      if dots! = 1 then gosub deselect_square
      return
  rem -- bring_left end

  wait_frame:
    if peek!(53266) <> 0 then goto wait_frame
    return
endproc

rem -----------------------------------
rem - draw game logo
rem -----------------------------------

proc drawlogo
  charpos = 1041
  colorpos = 55313
  
  i! = 0
  for row! = 0 to 5
    for col! = 0 to 5
      poke charpos, \logo![i!]
      poke colorpos, \logo_colors![i!]
      inc i!
      inc charpos
      inc colorpos
    next col!
    charpos = charpos + 34
    colorpos = colorpos + 34
  next row!

  textat 16,7, "puralax!"
  for colorpos = 55592 to 55600 : poke colorpos, 7 : next colorpos
endproc

rem -----------------------------------
rem - intro screen
rem -----------------------------------

proc intro
  dim pass1buf![5]
  dim pass2buf![5]
  password1$ = @pass1buf!
  password2$ = @pass2buf!
  all_passes$ = @\levelpass!

  call cls
  call drawlogo

  charpos = 1041
  colorpos = 55313
  found! = 0

  textat 6, 10, "c64 port written in xc=basic"
  textat 12,12, "by  csaba fekete"
  textat 10,16, "f1 - start game"
  textat 10,18, "f3 - enter level pass"
  textat 1,24, "music: 'another time' by roman majewski"

  for colorpos = 55946 to 56146 : poke colorpos, 13 : next colorpos

  loop:
    key = inkey()
    if key = 133 then return
    if key = 134 then gosub enter_code
    if found! = 1 then return
    goto loop

  enter_code:
    curpos 10, 20
    print "{YELLOW}pass:         "
    curpos 16, 20
    input password1$, 4, "abcdefghijklmnopqrstuvwxyz0123456789"
    found! = 0
    k!=0
    check_pass:
      strncpy password2$, all_passes$ + cast(k! * 4), 4
      if strcmp(password1$, password2$) = 0 then found! = 1 : goto exit_check_pass
      inc k!
      if k! < 64 then goto check_pass
    exit_check_pass:
      if found! = 1 then \current_level_no! = k! : return
      curpos 16, 20
      print "{LIGHT_RED}no match"
      return
endproc

rem -----------------------------------
rem - end screen
rem -----------------------------------

proc frontend
  call cls
  call drawlogo
  textat 12, 10, "congratulations!"
  textat 6, 12, "you have completed all levels"
  textat 4, 14, "press any key to restart machine"
  loop:
    if inkey() = 0 then goto loop
  sys 64738
endproc

rem -----------------------------------
rem - main
rem -----------------------------------

start:
  poke VIC_MEMSETUP, 24
  poke BORDER, 11
  poke BACKGR, 11

  call configure_sprites
  call start_music
  call intro
  
  game_loop:
    call load_level(current_level_no!)
    call draw_level
    level_success = 0
    call play_level(@level_success)
    poke VIC_SPRON, 0
    if level_success = 0 then gosub try_again else gosub well_done
    if current_level_no! = LEVEL_COUNT! then call frontend
    goto game_loop
  
  try_again:
    textat 15, 24, "try again"
    for colorpos = 56271 to 56280 : poke colorpos, 10 : next colorpos
    gosub pressfire
    return

  well_done:
    textat 15, 24, "well done"
    for colorpos = 56271 to 56280 : poke colorpos, 13 : next colorpos
    gosub pressfire  
    inc current_level_no!
    return

  pressfire:
    if peek!(56320) <> 111 then goto pressfire
    return

  end

rem -----------------------------------
rem - data
rem -----------------------------------


data logo![] = ~
  $4e, $4e, $4e, $4e, $4e, $4e, ~
  $4e, $4e, $4e, $4e, $4e, $4e, ~
  $4e, $4e, $20, $20, $4e, $4e, ~
  $4e, $4e, $20, $20, $4e, $4e, ~
  $4e, $4e, $4e, $4e, $4e, $4e, ~
  $4e, $4e, $4e, $4e, $4e, $4e

data logo_colors![] = ~
  $04,$04,$0A,$0A,$07,$07, ~
  $04,$04,$0A,$0A,$07,$07, ~
  $02,$02,$0E,$0E,$0D,$0D, ~
  $02,$02,$0E,$0E,$0D,$0D, ~
  $06,$06,$0E,$0E,$0F,$0F, ~
  $06,$06,$0E,$0E,$0F,$0F

data square_pattern![] = 70,76,76,71, ~
			72,78,78,73, ~
			72,78,78,73, ~
			74,77,77,75

data square_pattern_sm![] = 70,76,71, ~
      72,78,73, ~
			74,77,75

data square_pos[] =	~
  1070, 1074, 1078, 1082, 1086, 1090, 1094, 0, ~
  1230, 1234, 1238, 1242,	1246, 1250, 1254, 0, ~
  1390, 1394, 1398, 1402, 1406, 1410, 1414, 0, ~
  1550, 1554, 1558, 1562,	1566, 1570, 1574, 0, ~
  1710, 1714, 1718, 1722, 1726, 1730, 1734, 0

data square_pos_sm[] = ~
  1032,	1035,	1038,	1041,	1044,	1047,	1050,	1053, ~
  1152,	1155,	1158,	1161,	1164,	1167,	1170,	1173, ~
  1272,	1275,	1278,	1281,	1284,	1287,	1290,	1293, ~
  1392,	1395,	1398,	1401,	1404,	1407,	1410,	1413, ~
  1512,	1515,	1518,	1521,	1524,	1527,	1530,	1533, ~
  1632,	1635,	1638,	1641,	1644,	1647,	1650,	1653, ~
  1752,	1755,	1758,	1761,	1764,	1767,	1770,	1773, ~
  1872,	1875,	1878,	1881,	1884,	1887,	1890,	1893

rem --
rem -- Level passwords
rem -- 4 chars * 25 levels = 100 bytes
rem --

data levelpass![] = ~
  $37, $38, $4b, $4a, $32, $42, $32, $30, $37, $55, $36, $37, $33, $43, $37, $38,  ~
  $42, $38, $4c, $50, $39, $57, $53, $47, $42, $34, $56, $39, $35, $31, $33, $43,  ~
  $31, $39, $31, $53, $44, $31, $33, $37, $51, $36, $36, $32, $36, $52, $39, $58,  ~
  $39, $33, $44, $57, $38, $32, $57, $39, $35, $47, $4d, $31, $4e, $47, $55, $4f,  ~
  $4d, $32, $42, $58, $4b, $39, $34, $31, $47, $44, $53, $4c, $42, $31, $45, $4f,  ~
  $33, $35, $34, $31, $4e, $33, $4f, $39, $33, $4e, $4a, $32, $38, $48, $31, $39,  ~
  $55, $35, $48, $35

rem --
rem -- Level settings
rem -- High nibble: 0 - 7x5 level, 1 - 4x4 level, 2 - 8x8 level
rem -- Low nibble : target color
rem --

data levelsettings![] = ~
  $0a, $0a, $07, $0a, $0d, $07, $0a, $1d, ~
  $14, $1e, $1d, $07, $0d, $04, $24, $1e, ~
  $0e, $0d, $0e, $04, $1d, $17, $24, $0e, ~
  $0a

rem --
rem -- Level data (squares)
rem -- High nibble: square dots count
rem -- Low nibble : square color
rem --

data leveldata![] = ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  $0b, $0b, $0c, $0c, $0c, $0b, $0b, $0b, ~
  $0b, $0b, $0c, $1a, $0d, $0b, $0b, $0b, ~
  $0b, $0b, $0c, $0c, $0c, $0b, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  ~
	$0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
	$0b, $0b, $0c, $0c, $0c, $0b, $0b, $0b, ~
	$0b, $0b, $2a, $0c, $0d, $0b, $0b, $0b, ~
	$0b, $0b, $0c, $0c, $0c, $0b, $0b, $0b, ~
	$0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  ~
	$0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
	$0b, $0b, $0c, $0c, $04, $0b, $0b, $0b, ~
	$0b, $0b, $27, $0c, $04, $0b, $0b, $0b, ~
	$0b, $0b, $0c, $0c, $04, $0b, $0b, $0b, ~
	$0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  ~
	$0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
	$0b, $0b, $0c, $0c, $0c, $0b, $0b, $0b, ~
	$0b, $0b, $3a, $0c, $07, $0b, $0b, $0b, ~
	$0b, $0b, $0c, $0d, $0c, $0b, $0b, $0b, ~
	$0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  ~
	$0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
	$0b, $0b, $0c, $07, $07, $0b, $0b, $0b, ~
	$0b, $0b, $3d, $0c, $04, $0b, $0b, $0b, ~
	$0b, $0b, $0c, $0c, $04, $0b, $0b, $0b, ~
	$0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  ~
	$0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
	$0b, $0b, $0c, $0c, $0c, $0b, $0b, $0b, ~
	$0b, $0b, $1a, $0c, $17, $0b, $0b, $0b, ~
	$0b, $0b, $0c, $1d, $0c, $0b, $0b, $0b, ~
	$0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
	$0b, $0b, $0c, $0d, $1d, $0b, $0b, $0b, ~
	$0b, $0b, $2a, $0c, $07, $0b, $0b, $0b, ~
	$0b, $0b, $0c, $0c, $07, $0b, $0b, $0b, ~
	$0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  ~
  $04, $04, $0d, $1d, $0b, $0b, $0b, $0b, ~
	$1a, $0c, $0c, $0a, $0b, $0b, $0b, $0b, ~
	$0a, $0c, $0c, $1a, $0b, $0b, $0b, $0b, ~
	$17, $07, $1e, $0e, $0b, $0b, $0b, $0b, ~
	$0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  ~
  $04, $14, $0d, $1d, $0b, $0b, $0b, $0b, ~
	$0a, $0c, $0c, $0a, $0b, $0b, $0b, $0b, ~
	$0a, $0c, $0c, $2a, $0b, $0b, $0b, $0b, ~
	$17, $17, $0e, $0c, $0b, $0b, $0b, $0b, ~
	$0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  ~
  $0a, $0a, $0d, $0d, $0b, $0b, $0b, $0b, ~
	$0a, $0e, $1e, $0d, $0b, $0b, $0b, $0b, ~
	$0c, $07, $07, $0c, $0b, $0b, $0b, $0b, ~
	$0c, $37, $37, $0c, $0b, $0b, $0b, $0b, ~
	$0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  ~
  $0e, $07, $0c, $07, $0b, $0b, $0b, $0b, ~
	$0a, $07, $2d, $07, $0b, $0b, $0b, $0b, ~
	$0a, $0c, $2d, $0c, $0b, $0b, $0b, $0b, ~
	$1e, $0c, $0c, $0c, $0b, $0b, $0b, $0b, ~
	$0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  ~
  $0b, $0d, $2d, $0c, $04, $04, $0b, $0b, ~
	$0b, $0d, $0c, $0c, $0c, $24, $0b, $0b, ~
	$0b, $0c, $0c, $27, $0c, $0c, $0b, $0b, ~
	$0b, $2a, $0c, $0c, $0c, $0e, $0b, $0b, ~
	$0b, $0a, $0a, $0c, $2e, $0e, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  ~
  $0b, $04, $17, $0c, $17, $04, $0b, $0b, ~
  $0b, $17, $0c, $1a, $0c, $17, $0b, $0b, ~
  $0b, $0c, $1a, $3d, $1a, $0c, $0b, $0b, ~
  $0b, $17, $0c, $1a, $0c, $17, $0b, $0b, ~
  $0b, $04, $17, $0c, $17, $04, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  ~
  $0b, $0a, $1d, $0c, $1d, $0a, $0b, $0b, ~
  $0b, $1d, $0c, $17, $0c, $1d, $0b, $0b, ~
  $0b, $0c, $17, $14, $17, $0c, $0b, $0b, ~
  $0b, $1d, $0c, $04, $0c, $1d, $0b, $0b, ~
  $0b, $0a, $1d, $0c, $2d, $0a, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  $14, $07, $07, $07, $07, $0c, $0c, $07, ~
  $0c, $07, $0c, $0c, $07, $07, $0c, $07, ~
  $0c, $0d, $0c, $0c, $0c, $07, $07, $07, ~
  $3a, $0c, $0c, $0c, $0c, $0c, $0c, $07, ~
  $3a, $0c, $0c, $0c, $0c, $0c, $0c, $0c, ~
  $0c, $0c, $3d, $0c, $3e, $0c, $3d, $0c, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  ~
  $0a, $1a, $0c, $0a, $0b, $0b, $0b, $0b, ~
  $0c, $1d, $0c, $0d, $0b, $0b, $0b, $0b, ~
  $0c, $0d, $0c, $0d, $0b, $0b, $0b, $0b, ~
  $1e, $0d, $3e, $0d, $0b, $0b, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  ~
  $0b, $0a, $2a, $0c, $0d, $0d, $0b, $0b, ~
  $0b, $0a, $0c, $0c, $0c, $2d, $0b, $0b, ~
  $0b, $0c, $0c, $14, $0c, $0c, $0b, $0b, ~
  $0b, $27, $0c, $0c, $0c, $0e, $0b, $0b, ~
  $0b, $07, $07, $0c, $2e, $0e, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  ~
  $0b, $27, $17, $17, $17, $17, $0b, $0b, ~
  $0b, $0c, $0c, $0c, $0c, $0c, $0b, $0b, ~
  $0b, $0d, $0d, $0d, $0d, $2d, $0b, $0b, ~
  $0b, $0c, $0c, $0c, $0c, $0c, $0b, $0b, ~
  $0b, $2a, $1a, $1a, $1a, $1a, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  ~
  $0b, $0d, $17, $27, $0c, $0d, $0b, $0b, ~
  $0b, $0c, $0c, $0c, $0c, $0d, $0b, $0b, ~
  $0b, $3a, $24, $0d, $07, $1d, $0b, $0b, ~
  $0b, $0c, $0c, $0c, $0c, $0d, $0b, $0b, ~
  $0b, $0e, $0e, $2e, $0c, $0d, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  ~
  $0e, $0c, $07, $07, $07, $0c, $0e, $0b, ~
  $0a, $3d, $0d, $04, $0d, $3d, $0a, $0b, ~
  $1a, $0a, $04, $14, $04, $3a, $1a, $0b, ~
  $0c, $17, $0c, $1e, $0c, $17, $0c, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  ~
  $04, $14, $0e, $0d, $0b, $0b, $0b, $0b, ~
  $07, $07, $0e, $0d, $0b, $0b, $0b, $0b, ~
  $0a, $0a, $17, $17, $0b, $0b, $0b, $0b, ~
  $1d, $0a, $14, $04, $0b, $0b, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  ~
  $07, $04, $04, $1e, $0b, $0b, $0b, $0b, ~
  $04, $04, $1d, $0d, $0b, $0b, $0b, $0b, ~
  $0a, $1a, $17, $07, $0b, $0b, $0b, $0b, ~
  $0d, $0a, $0a, $0e, $0b, $0b, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  $0b, $0d, $0d, $0a, $0a, $0d, $0d, $0b, ~
  $0b, $1a, $0d, $17, $07, $0d, $1a, $0b, ~
  $0b, $14, $0e, $0d, $0d, $2e, $04, $0b, ~
  $0b, $0a, $0d, $07, $07, $0d, $0a, $0b, ~
  $0b, $1d, $0d, $0a, $0a, $0d, $1d, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  ~
  $0d, $0d, $0d, $0d, $17, $07, $07, $0b, ~
  $07, $0a, $0a, $1e, $0a, $0a, $0d, $0b, ~
  $07, $04, $14, $0e, $04, $04, $0d, $0b, ~
  $07, $0a, $0a, $0e, $1a, $0a, $1d, $0b, ~
  $1d, $0d, $0d, $07, $07, $07, $07, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  ~
  $07, $17, $0a, $0d, $0d, $0e, $04, $0b, ~
  $04, $0e, $07, $1d, $0e, $1a, $0a, $0b, ~
  $14, $0e, $14, $17, $07, $14, $04, $0b, ~
  $1a, $0d, $0d, $1e, $0a, $07, $07, $0b, ~
  $0a, $0d, $17, $0e, $0a, $04, $17, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b, ~
  $0b, $0b, $0b, $0b, $0b, $0b, $0b, $0b