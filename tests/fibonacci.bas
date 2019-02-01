rem ** fibonacci series **
let max = 32767
let t1 = 0
let t2 = 1
print "fibonacci series:"
loop:
	print t1, " "
	let nx = t1 + t2
	let t1 = t2
	let t2 = nx
	if nx < max then goto loop
end
