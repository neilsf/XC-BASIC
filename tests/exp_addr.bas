const SCREEN_ADDR = $0400

dim screen![1000] @ SCREEN_ADDR

for i=0 to 999
  screen![i] = 65
next i