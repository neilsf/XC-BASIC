proc test1
  for int = -50 to -30 step 3
    print int
  next int
endproc
 
proc test2
  FOR int = -20 TO 20
    PRINT int
  NEXT int
endproc

proc test3
  for int = 32760 to -32760
    print int
  next int
endproc

proc test4
  for int = 50 to -50 step -5
    print int
  next
endproc

call test4