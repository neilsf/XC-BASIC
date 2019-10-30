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
  data ship_shape![] = 109, 110, 111
  
  memcpy @shield_top!, 1790, 5
  memset 1830, 5, 90
  memset 1870, 5, 90
  memcpy @shield_top!, 1802, 5
  memset 1842, 5, 90
  memset 1882, 5, 90
  memcpy @shield_top!, 1814, 5
  memset 1854, 5, 90
  memset 1894, 5, 90

  memset 1984, 40, 90
  memcpy @ship_shape!, 1984, 3
  memcpy @ship_shape!, 1987, 3
  memcpy @ship_shape!, 1990, 3

  call draw_enemies(0, \enemy_posx!)
endproc
