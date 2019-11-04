rem -----------------------------------
rem -- ruin all shields when enemies
rem -- get there
rem -----------------------------------

proc ruin_shields
  memset 1824, 120, 32
  \scroll_bottom_limit! = 250
endproc
