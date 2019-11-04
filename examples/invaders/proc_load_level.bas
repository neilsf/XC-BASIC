rem -----------------------------------
rem -- load level
rem -----------------------------------

proc load_level
  for i! = 0 to 4
    for j! = 0 to 11
      \enemy_map![i! * 12 + j!] = \map1![i!]
    next j!
  next i!
  \enemy_bullet_on![0] = 0
  \enemy_bullet_on![1] = 0
  \enemy_bullet_on![2] = 0
  \bottom_row! = 13
  \scroll_bottom_limit! = 202
  \enemy_posx! = 8
  \enemy_posy! = 0
  \spos = 1224 + \enemy_posy! * 40 + \enemy_posx!
endproc