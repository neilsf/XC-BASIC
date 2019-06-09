counter = 3
proc recursive_proc(x,y)
  print "before: ", x
  y = y + 2
  x = x + y
  if x > 50 then return
  call recursive_proc(x,y)
  print "after: ", x
endproc

call recursive_proc(5,5)