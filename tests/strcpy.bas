a$ = "hello world"
dim buffer![6]
b$ = @buffer!
strcpy b$, a$+(strlen!(a$)-5)
print b$
