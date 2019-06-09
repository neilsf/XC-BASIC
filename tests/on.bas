dim buffer![2]
a$ = @buffer!
print "enter index (0-2):"
input a$, 1, "012"
x! = val!(a$)
on x! goto first, second, third
end

first:
  print "{CR}1st called"
  end

second:
  print "{CR}2nd called"
  end

third:
  print "{CR}3rd called"
  end