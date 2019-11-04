proc update_backup_ships
  data ship_shape![] = 109, 110, 111
  memset 1984, 40, 90
  i! = 0
  while i! < \lives! - 1 
    memcpy @ship_shape!, 1984 + i! * 3, 3
    inc i!
  endwhile
endproc