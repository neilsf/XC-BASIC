proc recfun(x)
  dim a[2,2]
  a[0,0] = x
  a[0,1] = x + 1
  a[1,0] = x + 2
  a[1,1] = x + 3
  print "before: ", a[1,0]
  if x > 3 then return
  call recfun(x+1)
  print "after: ", a[1,0]
endproc

call recfun(1)