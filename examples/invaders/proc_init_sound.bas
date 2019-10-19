proc init_sound
  poke \SID_VOLUME, 15
  poke \SID_AD1, %00010100
  poke \SID_SR1, %00100000

  poke \SID_AD3, %00010100
  poke \SID_SR3, %00010110

  poke \SID_AD2, %01110100
  poke \SID_SR2, %00010000

  doke \SID_FREQ3, 440
endproc
