rem ** file i/o test **
rem ** save and load area $c000-$c0ff

const MEM_START = 49152
const MEM_END   = 49408

rem ** dump random data
for i=0 to 255
    poke MEM_START+i, rnd()
next i

print "random data written. press a key"
gosub waitforkey

print "saving to file..."
save "@0:testfile", 8, MEM_START, MEM_END
err_code = ferr()
if err_code = 0 then print "done" else goto error

print "saved to file. press a key"
gosub waitforkey

rem ** scratch memory area
for i=0 to 255
    poke MEM_START+i, 0
next i

print "memory scratched. press a key"
gosub waitforkey

print "loading from file"
load "testfile", 8
err_code = ferr()
if err_code = 0 then print "done" else goto error

end

waitforkey:
    loop:
	if inkey() = 0 then goto loop
    return

error:
print "error code: ",err_code
