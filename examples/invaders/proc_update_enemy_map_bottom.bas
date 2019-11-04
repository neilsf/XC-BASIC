rem -----------------------------------
rem -- detect the bottom of enemy map
rem -----------------------------------

proc update_enemy_map_bottom
  row! = \bottom_row_cached!
  repeat
    row_empty! = 1
    col! = 11
    row_offset! = row! * 12
    repeat
      if \enemy_map![col! + row_offset!] <> 255 then
        row_empty! = 0
      endif
      dec col!
    until col! = 0
    if row_empty! = 0 then goto exit
    dec row!
  until row! = 0
  exit:
    \bottom_row_cached! = row!
    \bottom_row! = 5 + \enemy_posy! + lshift!(row!)
    \enemy_map_length = cast(lshift!(row!)) * 40 + 25
endproc
