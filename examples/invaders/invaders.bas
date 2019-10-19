rem -----------------------------------
rem -- XCB Invaders
rem -- written by Csaba Fekete
rem --
rem -- to be compiled using
rem -- XC=BASIC v2.1
rem -----------------------------------

rem -- Global constants and variables

include "globals.bas"

rem -- Go to program start

goto main

rem -- Include all procedures

include "proc_cls.bas"
include "proc_load_level.bas"
include "proc_draw_enemies.bas"
include "proc_ruin_shields.bas"
include "proc_draw_scene.bas"
include "proc_shift_enemies.bas"
include "proc_init_charset.bas"
include "proc_init_sprites.bas"
include "proc_move_enemies.bas"
include "proc_update_enemy_map_bottom.bas"

rem -- Include graphic charset at $2000

origin $2000
incbin "charset_s.bin"

rem -- Include some more procedures

include "proc_detect_collisions.bas"
include "proc_move_ship.bas"
include "proc_enemy_shooting.bas"
include "proc_move_enemy_bullets.bas"
include "proc_move_ufo.bas"

rem -- put all the rest
rem -- above $4000 to make sure sprites
rem -- and code don't overlap

origin $4000

include "proc_lazy_routines.bas"
include "proc_reset_game.bas"
include "proc_init_sound.bas"

rem -----------------------------------
rem -- main program starts here
rem -----------------------------------

main:
  call init_charset(0)
  call init_sprites
  call init_sound
  poke VIC_MEMSETUP, 24
  poke BORDER, 0 : poke BACKGR, 0
  disableirq

  call load_level
  call draw_scene
  gosub first_start

set:
  score = 0
  lives! = 3
  level! = 1
  game_speed! = 20

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
  call reset_game
  
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
  poke \SID_CNTRL3, 129
  poke \SID_CNTRL1, 0
  for i! = 250 to 253
    poke \SPRITE0_SHAPE, i!
    for j! = 0 to 25
      watch RASTER_POS, 0
    next j!
  next i!
  dec lives!
  rem textat 38, 0, lives!
  poke \SID_CNTRL3, 128
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
  textat 3, 2, "extra ship! press fire to continue"
  gosub wait_fire
  memset 1104, 40, 32
  inc level!
  textat 38, 0, level!
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

include "sprites.bas"

data bits![] = 1, 2, 4, 8, 16, 32, 64, 128

