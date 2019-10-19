rem -----------------------------------
rem -- move enemy bullets
rem -----------------------------------

proc move_enemy_bullets
  for i! = 0 to 2
    if \enemy_bullet_on![i!] = 1 then
      \enemy_bullet_posy![i!] = \enemy_bullet_posy![i!] + 2
      if \enemy_bullet_posy![i!] < 250 then
        addr = 53253 + lshift!(i!)
        poke addr, \enemy_bullet_posy![i!]
      else
        \enemy_bullet_on![i!] = 0
        bit! = \bits![i! + 2]
        poke \SPR_CNTRL, peek!(\SPR_CNTRL) & (bit! ^ 255)
      endif
    endif
  next i!
endproc
