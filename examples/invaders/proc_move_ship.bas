rem -----------------------------------
rem -- move the player's ship and bullet
rem -----------------------------------

proc move_ship
  on \bullet_on! goto no_bullet, bullet
bullet:
  if \bullet_posy! < 66 then
    \bullet_on! = 0
    poke \SPR_CNTRL, peek!(\SPR_CNTRL) & %11111101
    poke \SID_CNTRL1, 0
    goto no_bullet
  endif
  \bullet_posy! = \bullet_posy! - 4
  poke 53251, \bullet_posy!
  doke \SID_FREQ1, lshift(cast(\bullet_posy!), 4);
  poke \SID_PULSE1, \bullet_posy!
no_bullet:
  joy! = peek!($dc00)
  if joy! & %00000100 = 0 then
    if \ship_pos > 24 then dec \ship_pos
  else
    if joy! & %00001000 = 0 then 
      if \ship_pos < 320 then inc \ship_pos
    endif
  endif
  gosub move
  if joy! & %00010000 = 0 then gosub fire
  return
move:
  poke 53248, \ship_pos
  if \ship_pos > 255 then
    poke $d010, peek!($d010) | %00000001
  else
    poke $d010, peek!($d010) & %11111110
  endif
  return
fire:
  if \bullet_on! = 1 then return
  \bullet_on! = 1
  \bullet_posx = \ship_pos + 11
  \bullet_posy! = 229
  poke 53250, \bullet_posx
  poke 53251, \bullet_posy!
  if \bullet_posx > 255 then
    poke $d010, peek!($d010) | %00000010
  else
    poke $d010, peek!($d010) & %11111101
  endif
  poke \SPR_CNTRL, peek!(\SPR_CNTRL) | %00000010

  rem make sound
  doke \SID_FREQ1, 3760
  poke \SID_PULSE1, 235
  poke \SID_CNTRL1, 65
  return
endproc
