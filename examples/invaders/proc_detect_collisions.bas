rem -----------------------------------
rem -- test for sprite collisions
rem -----------------------------------

proc detect_collisions(result_ptr, score_ptr)
  const SPR_BG_COLL  = $d01f
  const SPR_SPR_COLL = $d01e
  coll_state! = peek!(SPR_BG_COLL)
  spr_coll_state! = peek!(SPR_SPR_COLL)

  if coll_state! & %00000010 = 2 then gosub enemy_hit
  if coll_state! & %00011100 > 0 then gosub shield_hit_by_enemy
  if spr_coll_state! > 0 then gosub ship_hit
  return
  enemy_hit:
    rem -- it can be the shield hit by player bullet
    rem -- TODO there's a bug here
    if \bottom_row! < 19 and \bullet_posy! >= 202 then
      col! = cast!(rshift(\bullet_posx, 3)) - 3
      row! = rshift!(\bullet_posy! - 50, 3)
      hit_position = \SCREEN + col! + 40 * row!
      char! = peek!(hit_position)
      if char! >= 88 then 
        if char! < 91 then
          poke hit_position, char! + 3
        else
          poke hit_position, 32
        endif
        \bullet_on! = 0
        poke \SID_CNTRL1, 0
        poke \SPR_CNTRL, peek!(\SPR_CNTRL) & %11111101  
        return
      endif
    else
    rem -- it's an enemy
      col! = cast!(rshift(\bullet_posx - \scroll!, 3)) - 3
      row! = rshift!(\bullet_posy! - 50, 3)
      \last_killed_enemy = \SCREEN + col! + 40 * row!
      char! = peek!(\last_killed_enemy)
      \enemy_map![(row! - \enemy_posy! - 5) * 6 + rshift!(col! - \enemy_posx!)] = 255
      if char! = 86 or char! = 87 then return
      if char! & 1 = 1 then
        charat col!, row!, 77
        charat col!-1, row!, 76
        dec \last_killed_enemy
      else
        charat col!, row!, 76
        charat col!+1, row!, 77
      endif
      if char! >= 84 then
        doke score_ptr, 3
      else
        if char! >= 82 then
          doke score_ptr, 2
        else
          doke score_ptr, 1
        endif
      endif
      \bullet_on! = 0
      poke \SID_CNTRL1, 0
      poke \SID_CNTRL3, 129
      dec \enemies_alive!
      \speed! = rshift!(\enemies_alive!, 2) + 5
      poke \SPR_CNTRL, peek!(\SPR_CNTRL) & %11111101
      if \enemies_alive! = 0 then poke result_ptr, 2
      return
    endif

    return
  shield_hit_by_enemy:
    rem -- can be multiple bullets
    
    for bn! = 2 to 4
      if coll_state! & \bits![bn!] <> 0 then
        bullet_no! = bn! - 2 
        col! = cast!(rshift(\enemy_bullet_posx[bullet_no!], 3)) - 3
        row! = rshift!(\enemy_bullet_posy![bullet_no!] - 49, 3)
        hit_position = \SCREEN + col! + 40 * row!
        char! = peek!(hit_position)
        if char! >= 88 then 
          if char! < 91 then
            poke hit_position, char! + 3
          else
            poke hit_position, 32
          endif
        endif
        \enemy_bullet_on![bullet_no!] = 0
        poke \SPR_CNTRL, peek!(\SPR_CNTRL) & (\bits![bn!] ^ $ff)
      endif
    next bn!
    return

  ship_hit:
    rem player ship hit
    if spr_coll_state! & %00000001 = 1 then 
      poke result_ptr, 1
      return
    endif
    rem ufo hit
    if spr_coll_state! & %01000000 = 64 then
      \bullet_on! = 0
      poke \SID_CNTRL1, 0
      poke \SPR_CNTRL, peek!(\SPR_CNTRL) & %11111101
      \ufo_hit! = 1
      doke score_ptr, 30
      poke \SPRITE6_SHAPE, 247 : rem ufo shape
      return
    endif
endproc
