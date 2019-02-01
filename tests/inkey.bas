print "press a key"
loop:
  let key = inkey()
  if key = 0 then goto loop
  print "you pressed ", key
 