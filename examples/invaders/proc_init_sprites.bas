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