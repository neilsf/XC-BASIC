pragma target = "vic20"

dim buffer![23]
a$ = @buffer!

print "?";
input a$, 22
print "{13}You typed: ", a$