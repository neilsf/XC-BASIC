DIM n[100]
i=0
loop:
  n[i] = i
  INC i
  IF i<=100 THEN GOTO loop
PRINT n[5]
PRINT n[99]

rem -- fast array lookup
DIM small![100]
for x!=0 to 99
  small![x!] = x!
next x!
print small![15]
print small![x!-4]