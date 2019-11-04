rem -- put code here that
rem -- can run when there's enough
rem -- raster time

proc lazy_routines
  if \addscore > 0 then
    \score = \score + \addscore
    textat 6, 0, \score
    \addscore = 0
  endif
  call update_enemy_map_bottom
endproc