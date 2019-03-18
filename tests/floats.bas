let x%=3141.59
let y%=186.7779
let pass=1

gosub test

let y%=3141.59

gosub test

let x%=-5643117.0

gosub test
end

test:
    print "pass ",pass
    if x% > y% then print "x gt y"
    if x% < y% then print "x lt y"
    if x% = y% then print "x eq y"
    if x% >= y% then print "x gte y"
    if x% <= y% then print "x lte y"
    if x% <> y% then print "x neq y"
    inc pass
return