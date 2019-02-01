let x=1
let y=1 
let dx=1
let dy=1
let i = 0

gosub cls

loop:
    charat x, y, 81
    gosub wait_frame
    charat x, y, 32

    if x = 0 then let dx = 1
    if x = 39 then let dx = -1
    if y = 0 then let dy = 1
    if y = 24 then let dy = -1

    let x = x+dx
    let y = y+dy

    goto loop

cls:
    poke 1024+i,32
    let i=i+1
    if i < 1000 then goto cls
    return

wait_frame:
    if peek(53266) < 250 then goto wait_frame
    return