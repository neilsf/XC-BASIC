pragma target = "x16"

dim buf![40]
in$ = @buf!
print "hello x16 from xc=basic!"
input in$, 39
print in$