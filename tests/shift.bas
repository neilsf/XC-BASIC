x! = 53
z! = 2
y! = lshift!(x!, z!)
print y!
y! = rshift!(y!, z!)
print y!
print "----"
print lshift(398, 3)
print rshift(1024, 2)
print "----"
print lshift!(45)
print rshift!(45)