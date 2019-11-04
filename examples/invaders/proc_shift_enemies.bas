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
