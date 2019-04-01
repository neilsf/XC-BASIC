rem -- Maze generator in XC-BASIC
rem -- by Oliver Hermanni
rem --
rem -- Original BASIC V2 code is from the book
rem -- "Programming the Commodore 64 - The Definitive Guide"
rem -- by Raeto Collin West
start:
    random_number = 0
    fi = 0
    data aa[] = -2, -80, 2, 80
    sc=1024
    s=0
    sm=0
    b=0
    max_random=10

    poke 53280,0
    poke 53281,0
    print "{CLR}"
    gosub make_random
    a = sc + 81 + random_number * 80
    gosub make_random
    a = a + random_number * 2
    for j=1 to 23
        print "{REV_ON}                                       "
    next j
    poke a,4
loop1:
    max_random=3
    gosub make_random
    j=random_number
    x=j
    if s<=sm then goto loop2
    sm = s
    fi = b
loop2:
    b=a+aa[j]
    if peek(b) <> 160 then goto loop3
    poke b,j
    poke a+aa[j]/2,32
    a=b
    s=s+1
    goto loop1
loop3:
    j=j+1&3
    if j<>x then goto loop2
    j=peek(a)
    poke a,32
    s=s-1
    if j>=4 then goto loop4
    a=a-aa[j]
    goto loop1
loop4:
    poke a,1
    poke fi,2
    infinity_loop:
    goto infinity_loop

make_random:
gen_random_number:
    random_number = rnd() / 3267
    if random_number < 0 thenrandom_number = random_number * -1
    if random_number > max_random then goto gen_random_number
    return