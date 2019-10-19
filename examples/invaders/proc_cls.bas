rem -----------------------------------
rem -- clear the screen
rem -----------------------------------

proc cls
  memset \SCREEN, 1000, 32
  memset \COLOR, 40, 13
  memset \COLOR + 80, 40, 10
  memset \COLOR + 200, 80, 7
  memset \COLOR + 280, 80, 8
  memset \COLOR + 360, 80, 10
  memset \COLOR + 440, 80, 13
  memset \COLOR + 520, 80, 14
  memset \COLOR + 600, 400, 6
endproc