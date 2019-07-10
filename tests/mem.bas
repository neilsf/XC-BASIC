const SCREEN = 1024

' Clear the screen
memset SCREEN, 1000, 32

' Print message
textat 0, 0, "hello world"

' Copy to 2nd line
memcpy SCREEN, SCREEN+40, 11

' Print another message
textat 10, 2, "xc=basic memory routines"

' Move it
memshift SCREEN+90, SCREEN+99, 24