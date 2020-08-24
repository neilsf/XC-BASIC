pragma target = "vic20"

memset $1e00, 506, 32

for x! = 0 to 7
  textat x!, x! + 1, "hello vic-20", x!
next

let f% = 3.14159
print f%
textat 9, 9, f%, 4