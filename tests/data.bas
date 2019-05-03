let i! = 0
loop:
  print x[i!], " ", y![i!], " ", z%[i!]
  let i! = i! + 1
  if i! <= 3 then goto loop
end

data x[] = 1235, -11200, 0, 65535
data y![] = 1, 89, 129, 255
data z%[] = 1.0, 3.14159, -234110.0, 99400.09