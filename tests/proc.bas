rem ** procedure example **
    rem ** these variables are global **
    let a = 1
    let b = 2
    dim array[4]
    let array[3]=2

proc simpleproc
    print "simple"
    print \a
    print \array[3]
endproc

proc printmin(x, y)
    rem ** x, y and a are local variables **
    let a = 3
    if x < y then print x else print y
endproc

call printmin(a, b)
call printmin(-1, -5)
print a
call simpleproc