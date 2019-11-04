rem -----------------------------------
rem -- initialize charset
rem -----------------------------------

proc init_charset(animphase!)
  on animphase! goto init_1, init_2
  return
  init_1:
    memcpy $2200, $2280, 16
    memcpy $2220, $2290, 16
    memcpy $2240, $22A0, 16
    return
  init_2:
    memcpy $2210, $2280, 16
    memcpy $2230, $2290, 16
    memcpy $2250, $22A0, 16
    return
endproc
