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
