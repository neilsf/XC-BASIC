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

  poke \SPRITE0_SHAPE, 255 : rem ship shape
  poke \SPRITE1_SHAPE, 254 : rem bullet shape
  poke \SPRITE2_SHAPE, 254 : rem bullet shape
  poke \SPRITE3_SHAPE, 254 : rem bullet shape
  poke \SPRITE4_SHAPE, 254 : rem bullet shape
  poke \SPRITE6_SHAPE, 246 : rem ufo shape
  rem poke \SPR_CNTRL, %01000001 : rem sprite0 & 6 on, the rest off
  poke \SPRITE1_X, 176
  poke \SPRITE1_Y, 226
  poke $d028, 1
  poke \SPRITE6_COLOR, 4
  poke \SPRITE6_Y, 66
endproc