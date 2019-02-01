dim n[100]
let i=0
loop:
  let n[i] = i
  let i=i+1
  if i<=100 then goto loop
print n[5]
print n[99]
