const VIC_MEMSETUP = 53272
const SCREEN = 1024
const COLOR = 55296
const BORDER = 53280
const BACKGR = 53281
const RASTER_POS = $d012
const SPR_CNTRL = $d015
const VIC2_CNTR2 = $d016
const ENEMY_CHAR_START! = 96

const SPRITE0_SHAPE = 2040
const SPRITE1_SHAPE = 2041
const SPRITE2_SHAPE = 2042
const SPRITE3_SHAPE = 2043
const SPRITE4_SHAPE = 2044
const SPRITE5_SHAPE = 2045
const SPRITE6_SHAPE = 2046

const SPRITE6_X = $d00c
const SPRITE6_Y = $d00d

const SPRITE6_COLOR = $d02d

dim enemy_map![60]
dim enemy_bullet_on![3]
dim enemy_bullet_posx[3]
dim enemy_bullet_posy![3]

scroll! = 0
enemy_posx! = 8
enemy_posy! = 0
bottom_row! = 13
enemy_dir! = 1

ship_pos = 176
bullet_on! = 0
bullet_posx = 0
bullet_posy! = 0

last_killed_enemy = 0
score = 0
lives! = 3
speed! = 20
game_speed! = 20

enemies_alive! = 60
scroll_bottom_limit! = 210
enemy_map_length = 340

spos = 0

ufo_on! = 0
ufo_pos = 370
ufo_hit! = 0
framecount_ufo = 0

dim bottom_row_cached!

goto main

rem -----------------------------------
rem -- clear the screen
rem -----------------------------------

proc cls
  memset \SCREEN, 1000, 32
  memset \COLOR, 40, 13
  memset \COLOR + 80, 40, 10
  memset \COLOR + 200, 80, 7
  memset \COLOR + 280, 80, 8
  memset \COLOR + 360, 80, 10
  memset \COLOR + 440, 80, 13
  memset \COLOR + 520, 80, 14
  memset \COLOR + 600, 400, 6
endproc

rem -----------------------------------
rem -- load level
rem -----------------------------------

proc load_level
  for i! = 0 to 4
    for j! = 0 to 11
      \enemy_map![i! * 12 + j!] = \map1![i!]
    next j!
  next i!
  \enemy_bullet_on![0] = 0
  \enemy_bullet_on![1] = 0
  \enemy_bullet_on![2] = 0
  \bottom_row! = 13
  \scroll_bottom_limit! = 210
  \enemy_posx! = 8
  \enemy_posy! = 0
  \spos = 1224 + \enemy_posy! * 40 + \enemy_posx!
endproc

rem -----------------------------------
rem -- draw enemies
rem -----------------------------------

proc draw_enemies(line_no!, offset!)
  pos = 1224 + line_no! * 40 + offset!
  map_offset! = 0
  for y! = 0 to 4
    poke pos-1, 32
    for x! = 0 to 11
      shape! = \enemy_map![map_offset!]
      poke pos, shape!
      inc pos
      inc shape!
      poke pos, shape!
      inc pos
      inc map_offset!
    next x!
    poke pos+1, 32
    pos = pos + 56
  next y!
endproc

rem -----------------------------------
rem -- ruin all shields when enemies
rem -- get there
rem -----------------------------------

proc ruin_shields
  memset 1824, 120, 32
  \scroll_bottom_limit! = 250
endproc

rem -----------------------------------
rem -- draw scene
rem -----------------------------------

proc draw_scene
  call cls
  textat 0, 0, "score"
  textat 6, 0, \score
  textat 14, 0, "xcb invaders"
  textat 33, 0, "ships"
  textat 38, 0, \lives!
  
  data shield_top![] = 88, 90, 90, 90, 89
  
  memcpy @shield_top!, 1830, 5
  memset 1870, 5, 90
  memset 1910, 5, 90
  memcpy @shield_top!, 1842, 5
  memset 1882, 5, 90
  memset 1922, 5, 90
  memcpy @shield_top!, 1854, 5
  memset 1894, 5, 90
  memset 1934, 5, 90

  call draw_enemies(0, \enemy_posx!)

  poke \SPRITE0_SHAPE, 255 : rem ship shape
  poke \SPRITE1_SHAPE, 254 : rem bullet shape
  poke \SPRITE2_SHAPE, 254 : rem bullet shape
  poke \SPRITE3_SHAPE, 254 : rem bullet shape
  poke \SPRITE4_SHAPE, 254 : rem bullet shape
  poke \SPRITE6_SHAPE, 246 : rem ufo shape
  rem poke \SPR_CNTRL, %01000001 : rem sprite0 & 6 on, the rest off
  poke 53248, 176
  poke 53249, 235
  poke $d028, 1
  poke \SPRITE6_COLOR, 13
  poke \SPRITE6_Y, 66
endproc

rem -----------------------------------
rem -- shift enemies to the right
rem -----------------------------------

proc rshift_enemies
  memshift \spos, \spos + 1,  \enemy_map_length
  poke \spos, 32
  inc \spos
endproc

rem -----------------------------------
rem -- shift enemies down
rem -----------------------------------

proc dshift_enemies
  memshift \spos, \spos + 40, \enemy_map_length
  memset \spos, 24, 32
  inc \bottom_row!
  \spos = \spos + 40
  if \bottom_row! = 19 then call ruin_shields
endproc

rem -----------------------------------
rem -- shift enemies to the left
rem -----------------------------------

proc lshift_enemies  
  memcpy \spos, \spos - 1, \enemy_map_length + 2
  dec \spos
endproc

rem -----------------------------------
rem -- initialize charset
rem -----------------------------------

proc init_charset(animphase!)
  on animphase! goto init_1, init_2
  return
  init_1:
    memcpy $2200, $2280, 16
    memcpy $2220, $2290, 16
    memcpy $2240, $22A0, 16
    return
  init_2:
    memcpy $2210, $2280, 16
    memcpy $2230, $2290, 16
    memcpy $2250, $22A0, 16
    return
endproc

rem -----------------------------------
rem -- initialize sprites
rem -----------------------------------

proc init_sprites
  poke $3f80, 192 : poke $3f81, 0 : poke $3f82, 0
  poke $3f83, 192 : poke $3f84, 0 : poke $3f85, 0
  poke $3f86, 192 : poke $3f87, 0 : poke $3f88, 0
  memset $3f89, 57, 0
  memcpy @\ship!, $3fc0, 63
  memcpy @\shape_ship_hit!, $3e00 , 384
  memcpy @\ufo_shape!, $3d80, 63
  memcpy @\ufo_shape_hit!, $3dc0, 63
endproc

rem -----------------------------------
rem -- move enemy map
rem -----------------------------------

proc move_enemies
  if \last_killed_enemy = 0 then goto skip_cleanup
  cleanup:
    doke \last_killed_enemy, $2020
    \last_killed_enemy = 0
  skip_cleanup:
    on \enemy_dir! goto move_left, move_right
  
  move_right:
    inc \scroll!
    if \scroll! = 8 then
      \scroll! = 0
      inc \enemy_posx!
      call rshift_enemies
    endif
    call init_charset(\scroll! & 1)
    \framecount! = 0
    return

  move_left:
    dec \scroll!
    if \scroll! = 255 then
      \scroll! = 7
      dec \enemy_posx!
      call lshift_enemies
    endif
    call init_charset(\scroll! & 1)
    \framecount! = 0
    return
endproc

rem -----------------------------------
rem -- detect the bottom of enemy map
rem -----------------------------------

proc update_enemy_map_bottom
  row! = \bottom_row_cached!
  repeat
    row_empty! = 1
    col! = 11
    row_offset! = row! * 12
    repeat
      if \enemy_map![col! + row_offset!] <> 255 then
        row_empty! = 0
      endif
      dec col!
    until col! = 0
    if row_empty! = 0 then goto exit
    dec row!
  until row! = 0
  exit:
    \bottom_row_cached! = row!
    \bottom_row! = 5 + \enemy_posy! + lshift!(row!)
    \enemy_map_length = cast(lshift!(row!)) * 40 + 25
endproc

rem -----------------------------------
rem -- graphics
rem -----------------------------------

origin $2000
incbin "charset_s.bin"

rem -----------------------------------
rem -- test for sprite collisions
rem -----------------------------------

proc detect_collisions(result_ptr)
  const SPR_BG_COLL  = $d01f
  const SPR_SPR_COLL = $d01e
  coll_state! = peek!(SPR_BG_COLL)
  spr_coll_state! = peek!(SPR_SPR_COLL)

  if coll_state! & %00000010 = 2 then gosub enemy_hit
  if coll_state! & %00011100 > 0 then gosub shield_hit_by_enemy
  if spr_coll_state! > 0 then gosub ship_hit
  return
  enemy_hit:
    rem -- it can be the shield hit by player bullet
    rem -- TODO there's a bug here
    if \bottom_row! < 19 and \bullet_posy! >= 210 then
      col! = cast!(rshift(\bullet_posx, 3)) - 3
      row! = rshift!(\bullet_posy! - 50, 3)
      hit_position = \SCREEN + col! + 40 * row!
      char! = peek!(hit_position)
      if char! >= 88 then 
        if char! < 91 then
          poke hit_position, char! + 3
        else
          poke hit_position, 32
        endif
        \bullet_on! = 0
        poke \SPR_CNTRL, peek!(\SPR_CNTRL) & %11111101  
        return
      endif
    else
    rem -- it's an enemy
      col! = cast!(rshift(\bullet_posx - \scroll!, 3)) - 3
      row! = rshift!(\bullet_posy! - 50, 3)
      \last_killed_enemy = \SCREEN + col! + 40 * row!
      char! = peek!(\last_killed_enemy)
      \enemy_map![(row! - \enemy_posy! - 5) * 6 + rshift!(col! - \enemy_posx!)] = 255
      if char! = 86 or char! = 87 then return
      if char! & 1 = 1 then
        charat col!, row!, 77
        charat col!-1, row!, 76
        dec \last_killed_enemy
      else
        charat col!, row!, 76
        charat col!+1, row!, 77
      endif
      if char! >= 84 then
        \score = \score + 20
      else
        if char! >= 82 then
          \score = \score + 30
        else
          \score = \score + 10
        endif
      endif
      \bullet_on! = 0
      dec \enemies_alive!
      \speed! = rshift!(\enemies_alive!, 2) + 5
      poke \SPR_CNTRL, peek!(\SPR_CNTRL) & %11111101
      if \enemies_alive! = 0 then poke result_ptr, 2
      return
    endif

    return
  shield_hit_by_enemy:
    rem -- can be multiple bullets
    
    for bn! = 2 to 4
      if coll_state! & \bits![bn!] <> 0 then
        bullet_no! = bn! - 2 
        col! = cast!(rshift(\enemy_bullet_posx[bullet_no!], 3)) - 3
        row! = rshift!(\enemy_bullet_posy![bullet_no!] - 49, 3)
        hit_position = \SCREEN + col! + 40 * row!
        char! = peek!(hit_position)
        if char! >= 88 then 
          if char! < 91 then
            poke hit_position, char! + 3
          else
            poke hit_position, 32
          endif
        endif
        \enemy_bullet_on![bullet_no!] = 0
        poke \SPR_CNTRL, peek!(\SPR_CNTRL) & (\bits![bn!] ^ $ff)
      endif
    next bn!
    return

  ship_hit:
    rem player ship hit
    if spr_coll_state! & %00000001 = 1 then 
      poke result_ptr, 1
      return
    endif
    rem ufo hit
    if spr_coll_state! & %01000000 = 64 then
      \bullet_on! = 0
      poke \SPR_CNTRL, peek!(\SPR_CNTRL) & %11111101
      \ufo_hit! = 1
      \score = \score + 300
      poke \SPRITE6_SHAPE, 247 : rem ufo shape
      textat 6, 0, \score
      return
    endif
endproc

rem -----------------------------------
rem -- move the player's ship and bullet
rem -----------------------------------

proc move_ship
  on \bullet_on! goto no_bullet, bullet
bullet:
  if \bullet_posy! < 66 then
    \bullet_on! = 0
    poke \SPR_CNTRL, peek!(\SPR_CNTRL) & %11111101
    goto no_bullet
  endif
  \bullet_posy! = \bullet_posy! - 4
  poke 53251, \bullet_posy!
no_bullet:
  joy! = peek!($dc00)
  if joy! & %00000100 = 0 then
    if \ship_pos > 24 then dec \ship_pos
  else
    if joy! & %00001000 = 0 then 
      if \ship_pos < 320 then inc \ship_pos
    endif
  endif
  gosub move
  if joy! & %00010000 = 0 then gosub fire
  return
move:
  poke 53248, \ship_pos
  if \ship_pos > 255 then
    poke $d010, peek!($d010) | %00000001
  else
    poke $d010, peek!($d010) & %11111110
  endif
  return
fire:
  if \bullet_on! = 1 then return
  \bullet_on! = 1
  \bullet_posx = \ship_pos + 11
  \bullet_posy! = 235
  poke 53250, \bullet_posx
  poke 53251, \bullet_posy!
  if \bullet_posx > 255 then
    poke $d010, peek!($d010) | %00000010
  else
    poke $d010, peek!($d010) & %11111101
  endif
  poke \SPR_CNTRL, peek!(\SPR_CNTRL) | %00000010
  return
endproc

rem -----------------------------------
rem - make enemies shoot if
rem - there is a free slot for
rem - the new bullet
rem -----------------------------------
proc enemy_shooting
  rem -- check for probability
  'if rnd!() > 8 then return
  i! = 0
  repeat
    if \enemy_bullet_on![i!] = 0 then goto shoot
    inc i!
  until i! = 3
  return
shoot:
  rem -- find out which enemy shoots
  rem -- i! now holds the slot number
  col! = rnd!() & %00001111
  if col! > 11 then return
  row! = 4
  repeat
    if \enemy_map![row! * 12 + col!] <> 255 then
      rem -- now shoot!
      \enemy_bullet_on![i!] = 1
      \enemy_bullet_posx[i!] = cast(lshift!(col!) + \enemy_posx!) * 8 + 32
      \enemy_bullet_posy![i!] = (lshift!(row!) + \enemy_posy!) * 8 + 101
      addr = 53252 + lshift!(i!)
      poke addr, \enemy_bullet_posx[i!]
      inc addr
      poke addr, \enemy_bullet_posy![i!]
      bit! = \bits![i! + 2]
      if \bullet_posx > 255 then
        poke $d010, peek!($d010) | bit!
      else
        poke $d010, peek!($d010) & (bit! ^ 255) 
      endif
      poke \SPR_CNTRL, peek!(\SPR_CNTRL) | bit!
      return
    endif
    dec row!
  until row! = 255
endproc

rem -----------------------------------
rem -- move enemy bullets
rem -----------------------------------

proc move_enemy_bullets
  for i! = 0 to 2
    if \enemy_bullet_on![i!] = 1 then
      \enemy_bullet_posy![i!] = \enemy_bullet_posy![i!] + 2
      if \enemy_bullet_posy![i!] < 250 then
        addr = 53253 + lshift!(i!)
        poke addr, \enemy_bullet_posy![i!]
      else
        \enemy_bullet_on![i!] = 0
        bit! = \bits![i! + 2]
        poke \SPR_CNTRL, peek!(\SPR_CNTRL) & (bit! ^ 255)
      endif
    endif
  next i!
endproc

rem -----------------------------------
rem -- move ufo
rem -----------------------------------

proc move_ufo
  if \ufo_hit! = 1 then
    inc \framecount_ufo
    if \framecount_ufo >= 75 then
      \ufo_on! = 0
      \ufo_pos = 370
      gosub pos_ufo
      \framecount_ufo = 0
      \ufo_hit! = 0
      poke \SPRITE6_SHAPE, 246
    endif
    return
  endif
  
  if \ufo_on! = 1 then
    dec \ufo_pos
    if \ufo_pos < 8 then \ufo_on! = 0 : return
    gosub pos_ufo
  else
    inc \framecount_ufo
    if \framecount_ufo >= 1000 then
      \ufo_on! = 1
      \ufo_pos = 370
      \framecount_ufo = 0
    endif
  endif
  return

  pos_ufo:
    poke \SPRITE6_X, \ufo_pos
    if \ufo_pos > 255 then
      poke $d010, peek!($d010) | %01000000
    else
      poke $d010, peek!($d010) & %10111111
    endif
    return
endproc

rem -- put all the rest
rem -- above $4000 to make sure sprites
rem -- and code don't overlap

origin $4000

rem -- put code here that
rem -- can run when there's enough
rem -- raster time

proc lazy_routines
  textat 6, 0, \score
  call update_enemy_map_bottom
endproc

rem -----------------------------------
rem -- main program starts here
rem -----------------------------------

main:
  call init_charset(0)
  call init_sprites
  poke VIC_MEMSETUP, 24
  poke BORDER, 0 : poke BACKGR, 0
  disableirq

  call load_level
  call draw_scene
  gosub first_start

set:
  score = 0
  lives! = 3
  game_speed! = 15

level:
  call load_level
  call draw_scene
  enemies_alive! = 60
  enemy_posx! = 8
  enemy_posy! = 0
  bottom_row! = 13
  enemy_dir! = 1
  ship_pos = 176
  bullet_on! = 0
  bullet_posx = 0
  bullet_posy! = 0
  last_killed_enemy = 0
  dec game_speed!
  speed! = game_speed!
  enemies_alive! = 60
  scroll_bottom_limit! = 210
  enemy_map_length = 344
  ufo_pos = 370
  ufo_on! = 0
  ufo_hit! = 0
  framecount_ufo = 500
  \bottom_row_cached! = 4

  poke \SPRITE6_SHAPE, 246
  poke \SPRITE6_X, 0

game:
  framecount! = 0
  framecount_shooting! = 0
  event! = 0
  
  ship_pos = 176
  poke 53248, ship_pos
  if ship_pos > 255 then
    poke $d010, peek!($d010) | %00000001
  else
    poke $d010, peek!($d010) & %11111110
  endif
  for i! = 0 to 15
    poke \SPR_CNTRL, i! & %00000001
    for j! = 0 to 25
      watch RASTER_POS, 0
    next j!
  next i!

  poke \SPR_CNTRL, %01000001

loop:  
  call move_ufo
  watch RASTER_POS, 50
  poke VIC2_CNTR2, %11001000
  watch RASTER_POS, 58
  poke VIC2_CNTR2, \scroll! | %11001000
  call move_enemy_bullets
  watch RASTER_POS, \scroll_bottom_limit!
  poke VIC2_CNTR2, %11001000
  inc framecount!
  inc framecount_shooting!
  if framecount! >= speed! then call move_enemies else call lazy_routines
  if enemy_posx! = 12 and enemy_dir! = 1 then
    call dshift_enemies
    inc enemy_posy!
    inc \bottom_row!
    if \bottom_row! = 24 then goto game_over
    enemy_dir! = 0
    goto eloop
  endif
  if enemy_posx! = 3 and enemy_dir! = 0 then
    call dshift_enemies
    inc enemy_posy!
    inc \bottom_row!
    if \bottom_row! = 23 then goto game_over
    enemy_dir! = 1
  endif

  eloop:
  call detect_collisions(@event!)
  on event! goto skip, live_lost, game_won
skip:
  call move_ship
  if framecount_shooting! >= enemies_alive! then call enemy_shooting : framecount_shooting! = 0
  goto loop

live_lost:
  for i! = 0 to 2
    \enemy_bullet_on![i!] = 0
  next i!
  poke \SPR_CNTRL, 1
  for i! = 250 to 253
    poke \SPRITE0_SHAPE, i!
    for j! = 0 to 25
      watch RASTER_POS, 0
    next j!
  next i!
  dec lives!
  textat 38, 0, lives!
  if lives! = 0 then goto game_over
  textat 4, 2, "ship down! press fire to continue"
  gosub wait_fire
  memset 1104, 40, 32
  poke \SPRITE0_SHAPE, 255
  goto game

game_won:
  for i! = 0 to 2
    \enemy_bullet_on![i!] = 0
  next i!
  poke \SPR_CNTRL, 1
  inc lives!
  textat 38, 0, lives!
  textat 3, 2, "extra ship! press fire to continue"
  gosub wait_fire
  memset 1104, 40, 32
  goto level

game_over:
  textat 2, 2, "game over - press fire to play again"
  gosub wait_fire
  goto set

first_start:
  textat 11, 2, "press fire to play"
  gosub wait_fire
  goto set

wait_fire:
    joy! = peek!($dc00)
    if joy! & %00010000 = 0 then return
    goto wait_fire

data map1![] = 82,84,84,80,80

data ship![] = %00000000,%00000000,%00000000, ~
               %00000000,%00000000,%00000000, ~
             %00000000,%00000000,%00000000, ~
             %00000000,%00000000,%00000000, ~
             %00000000,%00000000,%00000000, ~
             %00000000,%00000000,%00000000, ~
             %00000000,%00000000,%00000000, ~
             %00000000,%00000000,%00000000, ~
             %00000000,%00011000,%00000000, ~
             %00000000,%00111100,%00000000, ~
             %00000000,%00111100,%00000000, ~
             %00000111,%11111111,%11100000, ~
             %00001111,%11111111,%11110000, ~
             %00001111,%11111111,%11110000, ~
             %00001111,%11111111,%11110000, ~
             %00000000,%00000000,%00000000, ~
             %00000000,%00000000,%00000000, ~
             %00000000,%00000000,%00000000, ~
             %00000000,%00000000,%00000000, ~
             %00000000,%00000000,%00000000, ~
             %00000000,%00000000,%00000000

data shape_ship_hit![] = ~
 $00,$00,$00,$00,$00,$00,$00,$00, ~
 $00,$00,$00,$00,$00,$00,$00,$00, ~
 $00,$00,$00,$00,$00,$00,$00,$00, ~
 $00,$40,$00,$00,$36,$20,$04,$3c, ~
 $c0,$07,$ff,$e0,$0f,$ff,$f0,$0f, ~
 $ff,$f0,$0f,$ff,$f0,$00,$00,$00, ~
 $00,$00,$00,$00,$00,$00,$00,$00, ~
 $00,$00,$00,$00,$00,$00,$00,$03, ~
~
 $00,$00,$00,$00,$00,$00,$00,$00, ~
 $00,$00,$00,$00,$00,$00,$00,$00, ~
 $00,$00,$01,$88,$80,$00,$c9,$00, ~
 $08,$53,$00,$0c,$36,$38,$04,$24, ~
 $c0,$07,$e7,$e0,$0f,$ef,$f0,$0f, ~
 $ef,$f0,$0f,$ff,$f0,$00,$00,$00, ~
 $00,$00,$00,$00,$00,$00,$00,$00, ~
 $00,$00,$00,$00,$00,$00,$00,$03, ~
~
 $00,$00,$00,$00,$00,$00,$00,$00, ~
 $00,$02,$00,$00,$02,$04,$00,$03, ~
 $04,$40,$01,$80,$c0,$10,$81,$00, ~
 $18,$10,$0c,$08,$34,$38,$00,$24, ~
 $00,$07,$e3,$e0,$0f,$c3,$f0,$0f, ~
 $c7,$f0,$0f,$ff,$f0,$00,$00,$00, ~
 $00,$00,$00,$00,$00,$00,$00,$00, ~
 $00,$00,$00,$00,$00,$00,$00,$03, ~
~
 $00,$00,$00,$04,$00,$00,$04,$02, ~
 $00,$06,$02,$00,$02,$00,$20,$02, ~
 $00,$60,$20,$00,$40,$30,$00,$02, ~
 $10,$10,$0c,$00,$34,$00,$00,$24, ~
 $00,$07,$e3,$e0,$0c,$c0,$f0,$0f, ~
 $47,$f0,$0f,$ff,$f0,$00,$00,$00, ~
 $00,$00,$00,$00,$00,$00,$00,$00, ~
 $00,$00,$00,$00,$00,$00,$00,$03, ~
~
 $00,$00,$00,$04,$00,$00,$00,$02, ~
 $08,$06,$00,$08,$40,$00,$20,$00, ~
 $00,$00,$20,$00,$01,$00,$00,$02, ~
 $00,$00,$00,$00,$00,$00,$00,$24, ~
 $00,$06,$63,$60,$0c,$c0,$70,$08, ~
 $07,$90,$0f,$ff,$f0,$00,$00,$00, ~
 $00,$00,$00,$00,$00,$00,$00,$00, ~
 $00,$00,$00,$00,$00,$00,$00,$03, ~
~
 $00,$00,$00,$00,$00,$00,$00,$00, ~
 $00,$00,$00,$00,$00,$00,$00,$00, ~
 $00,$00,$00,$00,$00,$00,$00,$00, ~
 $00,$00,$00,$00,$00,$00,$00,$24, ~
 $00,$02,$63,$40,$08,$00,$70,$08, ~
 $07,$90,$0f,$c0,$f0,$00,$00,$00, ~
 $00,$00,$00,$00,$00,$00,$00,$00, ~
 $00,$00,$00,$00,$00,$00,$00,$03

data ufo_shape![] = ~
$03,$c0,$00,$0f,$f0,$00,$1f,$f8, ~
$00,$35,$ac,$00,$ff,$ff,$00,$38, ~
$1c,$00,$10,$08,$00,$00,$00,$00, ~
$00,$00,$00,$00,$00,$00,$00,$00, ~
$00,$00,$00,$00,$00,$00,$00,$00, ~
$00,$00,$00,$00,$00,$00,$00,$00, ~
$00,$00,$00,$00,$00,$00,$00,$00, ~
$00,$00,$00,$00,$00,$00,$00,$03

data ufo_shape_hit![] = ~
$f9,$c7,$00,$0a,$28,$80,$12,$69, ~
$80,$32,$aa,$80,$0b,$2c,$80,$8a, ~
$28,$80,$71,$c7,$00,$00,$00,$00, ~
$00,$00,$00,$00,$00,$00,$00,$00, ~
$00,$00,$00,$00,$00,$00,$00,$00, ~
$00,$00,$00,$00,$00,$00,$00,$00, ~
$00,$00,$00,$00,$00,$00,$00,$00, ~
$00,$00,$00,$00,$00,$00,$00,$03

data bits![] = 1, 2, 4, 8, 16, 32, 64, 128

