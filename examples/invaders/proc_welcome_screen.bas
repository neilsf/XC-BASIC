rem -----------------------------------
rem -- welcome screen
rem -----------------------------------

proc welcome_screen
  call cls
  textat 15, 2, "welcome to"
  textat 10, 4, "*** xcb invaders ***"
  textat 11, 6, "press fire to play"
  
  textat 14, 10, "AA = 1 point" : poke 1438, 64
  textat 14, 12, "BC = 2 points"
  textat 14, 14,"DE = 3 points"
  textat 14, 16,"NO = 30 points"

  
  textat 11, 24, "visit xc-basic.net"
endproc