proc staticexample(firstrun)
	dim a
	if firstrun = 1 then let a = 1 else inc a[0]
	print a
endproc
    
call staticexample(1)
call staticexample(0)