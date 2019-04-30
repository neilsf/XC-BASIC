print "{CLR}"
for i=0 to 39
  h% = sin%(float%(i) / 6.28)
  charat i, 12 + int(h% * 12), 160
next i
for i=0 to 39
  h% = cos%(float%(i) / 6.28)
  charat i, 12 + int(h% * 12), 160
next i