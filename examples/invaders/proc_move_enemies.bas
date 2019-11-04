rem -----------------------------------
rem -- move enemy map
rem -----------------------------------

proc move_enemies
  poke \SID_CNTRL2, 32
  poke \SID_CNTRL2, 33
  doke \SID_FREQ2, \notes[\sound_phase!]
  dec \sound_phase!
  if \sound_phase! = 255 then \sound_phase! = 3

  if \last_killed_enemy = 0 then goto skip_cleanup
  cleanup:
    doke \last_killed_enemy, $2020
    poke \SID_CNTRL3, 128
    \last_killed_enemy = 0
  skip_cleanup:
    on \enemy_dir! goto move_left, move_right
  
  move_right:
    inc \scroll!
    if \scroll! = 8 then
      \scroll! = 0
      inc \enemy_posx!
      call rshift_enemies
    endif
    call init_charset(\scroll! & 1)
    \framecount! = 0
    return

  move_left:
    dec \scroll!
    if \scroll! = 255 then
      \scroll! = 7
      dec \enemy_posx!
      call lshift_enemies
    endif
    call init_charset(\scroll! & 1)
    \framecount! = 0
    return
endproc