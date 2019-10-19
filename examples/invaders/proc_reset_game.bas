proc reset_game
  \framecount! = 0
  \framecount_shooting! = 0
  \event! = 0
  
  \ship_pos = 176
  poke 53248, \ship_pos
  if \ship_pos > 255 then
    poke $d010, peek!($d010) | %00000001
  else
    poke $d010, peek!($d010) & %11111110
  endif
  if \ufo_pos > 255 then
    poke $d010, peek!($d010) | %01000000
  else
    poke $d010, peek!($d010) & %10111111
  endif
  for i! = 0 to 15
    poke \SPR_CNTRL, i! & %00000001
    for j! = 0 to 25
      watch \RASTER_POS, 0
    next j!
  next i!

  \enemy_bullet_on![0] = 0
  \enemy_bullet_on![1] = 0
  \enemy_bullet_on![2] = 0
  poke \SPR_CNTRL, %01000001
  \sound_phase! = 3
endproc
