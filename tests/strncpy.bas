dim buffer![6]
a$ = "hello world"
b$ = @buffer!
strncpy b$, a$, 5
print b$
rem -- the above will output "hello"