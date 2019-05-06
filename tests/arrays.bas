DIM n[100]
i=0
loop:
  n[i] = i
  INC i
  IF i<=100 THEN GOTO loop
PRINT n[5]
PRINT n[99]