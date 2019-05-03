x! = 1
y! = 1 
dx! = 1
dy! = 1
i = 0

const SPACE! = 32
const BALL! = 81
const SCREEN = 1024

gosub cls

loop:
    charat x!, y!, BALL!
    gosub wait_frame
    charat x!, y!, SPACE!

    rem // 255 equals to -1 in 8-bit arithmetics

    if x! = 0  then dx! = 1
    if x! = 39 then dx! = 255
    if y! = 0  then dy! = 1
    if y! = 24 then dy! = 255

    x! = x! + dx!
    y! = y! + dy!

    goto loop

cls:
    poke SCREEN + i, SPACE!
    i = i + 1
    if i < 1000 then goto cls
    return

wait_frame:
    if peek!(53266) < 250 then goto wait_frame
    return