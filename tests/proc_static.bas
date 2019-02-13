proc staticexample(firstrun)
	dim a[1]
	if firstrun = 1 then let a[0] = 1 else inc a[0]
	print a[0]
endproc
    
call staticexample(1)
call staticexample(0)