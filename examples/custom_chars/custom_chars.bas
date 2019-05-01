rem -- Example: custom charset in XC=BASIC --
rem

const VIC_MEMSETUP = 53272
const CHARS_LOC    = 14336
const DRIVE	   = 8

rem -- Load the charset to location $3800
rem -- Note: the file is prepended with a 2-byte address
rem -- that we'll ignore now.

load "assaultmachine", DRIVE, CHARS_LOC
if ferr() = 0 then goto load_ok
  print "load error"
  end
load_ok:

rem -- Setup VIC to see chars at $3800

poke VIC_MEMSETUP, peek(VIC_MEMSETUP) | 14

rem -- Write some test

print "hello this is the new charset"