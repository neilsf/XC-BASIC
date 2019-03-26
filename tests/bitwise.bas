rem binary 10011010
let a=154
rem binary 11100001
let b=225
print a | b
rem 251
print a & b
rem 128
print a ^ b
rem 123

rem check grammar parsing
if a|b = 251 or a & b < 129 then print "correct"
