fun xfun!(a!, b!)
  return a! + b!
endfun

fun noparams()
  return -2
endfun

fun floatfun%(a)
  return cast%(a) + 1.0
endfun

print xfun!(5, 6)
print noparams() * 4
print floatfun%(980)