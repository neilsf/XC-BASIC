rem -----------------------------------
rem - make enemies shoot if
rem - there is a free slot for
rem - the new bullet
rem -----------------------------------
proc enemy_shooting
  rem -- check for probability
  'if rnd!() > 8 then return
  i! = 0
  repeat
    if \enemy_bullet_on![i!] = 0 then goto shoot
    inc i!
  until i! = 3
  return
shoot:
  rem -- find out which enemy shoots
  rem -- i! now holds the slot number
  col! = rnd!() & %00001111
  if col! > 11 then return
  row! = 4
  repeat
    if \enemy_map![row! * 12 + col!] <> 255 then
      rem -- now shoot!
      \enemy_bullet_on![i!] = 1
      \enemy_bullet_posx[i!] = cast(lshift!(col!) + \enemy_posx!) * 8 + 32
      \enemy_bullet_posy![i!] = (lshift!(row!) + \enemy_posy!) * 8 + 101
      addr = 53252 + lshift!(i!)
      poke addr, \enemy_bullet_posx[i!]
      inc addr
      poke addr, \enemy_bullet_posy![i!]
      bit! = \bits![i! + 2]
      if \bullet_posx > 255 then
        poke $d010, peek!($d010) | bit!
      else
        poke $d010, peek!($d010) & (bit! ^ 255) 
      endif
      poke \SPR_CNTRL, peek!(\SPR_CNTRL) | bit!
      return
    endif
    dec row!
  until row! = 255
endproc
