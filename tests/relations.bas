rem *** relation tests ***

proc check(a, b)
  print "for a=",a," and b=",b
  print "---------"
  if a < b then print "a < b is true"
  if a <= b then print "a <= b is true"
  if a > b then print "a > b is true"
  if a >= b then print "a >= b is true"
  if a = b then print "a = b is true"
  if a <> b then print "a <> b is true"

  if b < a then print "b < a is true"
  if b <= a then print "b <= a is true"
  if b > a then print "b > a is true"
  if b >= a then print "b >= a is true"
  if b = a then print "b = a is true"
  if b <> a then print "b <> a is true"

  loop: if inkey!() = 0 then goto loop
endproc


for i! = 0 to 6
  call check(a[i!], b[i!])
next i!

data a[] = 0, -30000, 30000, -25000, 25000, -5, -1
data b[] = 0,   5000, -2768, -27000, 27000, -5, 32767