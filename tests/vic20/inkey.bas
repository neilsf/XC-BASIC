pragma target = "vic20"

repeat
  key = inkey()
  if key > 0 then print key
until key = 13