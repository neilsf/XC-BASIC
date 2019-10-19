rem -----------------------------------
rem -- draw scene
rem -----------------------------------

proc draw_scene
  call cls
  textat 0, 0, "score"
  textat 6, 0, \score
  textat 14, 0, "xcb invaders"
  textat 33, 0, "level"
  textat 38, 0, \level!
  
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
