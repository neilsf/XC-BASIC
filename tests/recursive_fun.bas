fun fact(n)
  ret = 0
  m = 0
  if n <= 1 then
    ret = 1
  else
    print n
    m = fact(n-1)
    print n, " ", m
    ret = n * m
  endif
  print ret
  return ret
endfun

print fact(5)

fun fib(n)
  if n <= 1 then
    return n
  else
    return fib(n-1) + fib(n-2)
  endif
endfun

print fib(3)
