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
