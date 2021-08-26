rem MandelBLOCK - a blocky Mandelbrot set
rem inspired by Matt Hefferman's YT video "8-BIT battle royale" (https://www.youtube.com/watch?v=DC5wi6iv9io&t=1687s)
rem code based on Wikipedia's Mandelbrot set pseudocode (https://en.wikipedia.org/wiki/Mandelbrot_set)
rem with speed optimizations suggested by Csaba Fekete, creator of XC-Basic

const BORDER = $d020
dim py!
dim px!
dim r
dim i!
dim xz%
dim yz%
dim x% fast
dim y% fast
dim xt% fast

poke BORDER, 0
print "{CLR}"
memset 1024, 1000, 160
disableirq

for py! = 0 to 24
  yz% = cast%(py!) * 2.0 / 24.0 - 1.0
  r = 55296 + py! * 40
  for px! = 0 to 39
    xz% = cast%(px!) * 3.5 / 40.0 - 2.5
    x% = 0.0
    y% = 0.0
    i! = 0
    while x% * x% + y% * y% <= 4 and i! < 16
      xt% = x% * x% - y% * y% + xz%
      y% = 2.0 * x% * y% + yz%
      x% = xt%
      i! = i! + 1
    endwhile
    poke r + px!, i!
  next px!
next py!

enableirq
repeat : until inkey!() <> 0