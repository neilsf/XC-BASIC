**XC-BASIC** is a dialect of the BASIC programming language for the Commodore-64 and **xcbasic64** is a cross-compiler that compiles **XC-BASIC** source code to assembly source (in DASM format). 

Some of the advantages of programming in **XC-BASIC** are:

- Cross development - use your favourite OS/editor/etc.
- Higher execution speed  - no interpreter, the source can be compiled to pure machine code in two steps.
- More available memory - the program does not require the BASIC ROM to be present, which means the program code may span from $0801 to $CFFF - a total of 50K!

**XC-BASIC** is based on Tiny BASIC, with many differences in syntax.

# Contributors wanted!

- If you've written a working XC-BASIC program, please add it to the examples/ directory in the develop branch and submit a PR. Or you can just send it to me to feketecsaba dot gmail dot com
- If you've found a bug, please post a GitHub issue.
- If you have any suggestions, ideas, critics or would like to develop the project, feel free to email me. Any feedback is warmly appreciated.

# Language reference

## General syntax
A **XC-BASIC** program is an ASCII text that is parsed line by line. Each line may have zero or more statements. If there are more than one statements in a line, they must be separated by a colon (`:`).

 A line may be prepended by a label. Labels are appended with a colon (`:`). An example program:

	rem ** fibonacci series **
	max = 32767
	t1 = 0 : t2 = 1
	print "fibonacci series:"
	loop:
		print t1, " "
		nx = t1 + t2
		t1 = t2 : t2 = nx
		if nx < max then goto loop
	end

Line breaks are ignored if the last character of a line is a tilde (`~`) character. This can be useful in a `DATA` statement with a long list, for example:

    data my_long_data[] = 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, ~
                          11, 12, 13, 14, 15

Note that no other character is allowed after the tilde, including whitespace.

## Variables

Variables are automatically declared upon the first `LET`, `DIM` or `ḊATA` statement that the compiler encounters. Every variable has a type that cannot be changed after declaration. The variable type is defined by appending the variable type modifier to the variable name. The valid types are:

- **Signed short integers** (-32768 to +32767), their identifiers are appended with the `#` modifier (this is the default and the modifier can be omitted, i. e. `myInt#` is the same as `myInt`)
- **Floating point numbers** (*coming soon!*), their identifiers are appended with the `%` modifier
- **Strings** (*coming soon!*), their identifiers are appended with the `$` modifier

Variable names can be of any length, they can consist of letters and numbers, but they may not start with a number or reserved keyword (e. g. the names `letter` or `endpoint` are not allowed because both start with a keyword and would confuse the compiler). Variable names are case-sensitive.

## Constants

Constants are special variables that are initialized in compile time and may not change value during runtime. The benefit of using constants instead of variables are:

- Constants do not reserve space in memory
- Constants are *faster* to evaluate

Always prefer constants over variables, whenever possible. See the documentation for `CONST` for more information.

## Scope

Variables, constants and labels can be **global** or **local**.

- Any variable or constant declared using a `CONST`,  `LET`, `DIM` or `DATA` statement outside a `PROC ... ENDPROC` pair is considered to be a global variable and can only be accessed from the global scope. Global variables are accessible from within a procedure by using the global modifier (`\`).
- Any variable or constant declared using a `CONST`, `LET`, `DIM` or `DATA` statement inside a `PROC ... ENDPROC` pair, including the procedure's parameters, is considered to be a local variable and can only be accessed within that procedure.

Please see the documentation for the `PROC ... ENDPROC` statements for more details.

## Arrays

Arrays must be defined using the `DIM` statement. As of the current version, maximum two-dimensional arrays are supported and both dimensions are limited to a length of 32767 elements. However, this is just a theoretical limit, in practice you'll run out of memory earlier. Arrays are zero-based (the first index is 0) and only integers may be used as indices.

The syntax to define array is the following (note the square brackets):

	dim variable[x_len, y_len]
	
Example:

	dim myArr[100, 100]
	let myArr[15, 2] = 3420
	print myArr[15, 2]
	
Or:

	rem ** fill an array with consecutive numbers **
	dim myArr[10]
	for i=0 to 9
		let myArr[i] = i
	next i
	print "fetch number 5 from myArr: ", myArr[5]
	end


Arrays are not initialized, which means that if you read the value of an array member without previously assigning a value to it, you will get unexpected results. For example:

	dim a[10]
	print a[0]
	rem ** this will print an undefined number **

**Important:** there is no runtime array bounds checking! The programmer has to make sure that the array subscript returns a number that is within the bounds of the array. Otherwise the result will be undefined.

## Expressions

Numeric expressions are evaluated similarly to BASIC V2 or any other BASIC dialects, with some minor incompatibilities. The currently supported arithmetic operators are:

### Arithmetic operators

 - `*` (mutiplication)
 - `/` (division)
 - `+` (addition)
 - `-` (substraction)

### Relational operators

- `=` (equal to)
- `<>` (not equal to)
- `>`  (greater than)
- `>=`  (greater than or equal to)
- `<` (less than)
- `<=` (less than or equal to)

### Conditional operators

- `AND`
- `OR`

### Bitwise operators

- `&` (and)
- `|` (or)
- `^` (exclusive or)

Note that you are not allowed to use the `AND` or `OR` keywords for bitwise operations as in BASIC V2.

### Unary operators

- `@` (address of)

## Strings

As of the current version, only constant strings (literals) are supported. Strings are enclosed in double quotes (`"`) and can be used as the argument of the `PRINT` and `TEXTAT` commands. All characters in strings will be translated from ASCII to PETSCII or screencodes, depending on the context.

There are several escape sequences that you can use in string literals to be able to print special PETSCII characters.

- The escape sequence `{num}` (where num is a decimal number) will be replaced by the PETSCII code indicated by `num`.
- You can also use the following convenience escape sequences: `{CLR}`, `{HOME}`, `{INSERT}`, `{DEL}`, `{CR}`, `{REV_ON}`, `{REV_OFF}`, `{CRSR_UP}`, `{CRSR_DOWN}`, `{CRSR_LEFT}`, `{CRSR_RIGHT}`

Examples:

	print "{CLR}welcome to a fresh new screen"
	print "this is line one{CR}and this is line two"
	print "{5}white text"

## Error conditions

For the sake of execution speed, there is only one error condition that is checked in runtime, the **division by zero**. The compiler will try to detect static (compile time) errors in code, but naturally it can't predict runtime error conditions. In each statement's documentation you can read the possible error conditions that you, the programmer have to take care of.

## List of commands

The following is the list of the commands supported by **XC-BASIC**, in alphabetical order:

`CALL` | `CHARAT` | `CONST` | `DATA` | `DEC` | `DIM` | `END` | `FERR` | `FOR ... NEXT` |  `GOSUB ... RETURN` | `GOTO` | `IF ... THEN ... ELSE` | `INC` | `INCBIN` | `INKEY` | `INPUT` | `LET` | `LOAD` | `ORIGIN` |  `PEEK` | `POKE` | `PRINT` | `PROC ... ENDPROC` | `REM` | `RND` | `SAVE` | `SYS` | `TEXTAT` | `USR` | `@`

More commands are coming soon!

### CALL

Please see `PROC ... ENDPROC`

### CHARAT

Syntax:

	charat column, row, screencode

Outputs a character at the given column and row on the screen. Accepts integers for `colum` and `row`, and another integer for the `screencode`. Example:

	rem this puts an 'A' near the center of the screeen
	charat 20, 10, 65 
	
Note that the runtime library will not check if the values are within the screen boundaries. As `CHARAT` is just a convenience wrapper around `POKE`, it can overwrite memory locations other than the screen memory, thus damaging the program or data. Use it with special care.

### CONST

The `CONST` statement defines a constant. Syntax:

	const varname = number
	
The constant can be subsequently used as a regular variable, except that it is read-only. The value may not be an expression.

Example:

	const BORDER = 53280
	const WHITE = 1
	
	poke BORDER, WHITE

### DATA

Syntax:

	data varname[] = value1, value2, value3, ...

The `DATA` command allocates a one-dimensional static array in memory filled with pre-initialized data in compile time. The array can be used as a regular array in runtime. Example:

	rem ** this will print: 9
	data squares[] = 0, 1, 4, 9, 16
	print squares[3]
	
`DATA` statements can be written anywhere in your program. The following will also work:

	print squares[3]
	end
	
	rem ** program data **
	data squares[] = 0, 1, 4, 9, 16
	
The data members can be updated in runtime using the `LET` command:

	rem ** this will print 9 first, then -1 **
	print squares[3]
	let squares[3] = -1
	print squares[3]
	end
		
	rem ** program data **
	data squares[] = 0, 1, 4, 9, 16

Again, note there is no runtime array bounds checking. Trying to write data over the array bounds may break the program.

### DEC

Decrements the value of an integer variable by 1. This is considerably faster than doing `LET x = x - 1`. Example:

	let myVar = 10
	dec myVar
	print myVar

The above will output 9.

### DIM

Defines an array. See the Arrays section for more information.

`DIM` can also be used to define a single variable without having to assign a value. For example:

	dim x
	rem ** x is now an uninitalized variable

### END

Ends execution. Can be used within the normal program flow. It can be used in the end of the program, but it is not necessary. See `GOSUB` for an example.

### FOR ...  NEXT
Syntax:

	for varname = expression1 to expression2
	[statements]
	next varname
	
The `FOR ... NEXT` construct will assign the result of expression1 to the given variable, then iterate the variable until it reaches the value of expression2, executing the commands between `FOR` and `NEXT` as many times as necessary. `FOR ... NEXT` constructs can be nested.

Note #1: the value of expression2 is evaluated only once, before starting the loop.

Note #2: it is not possible to omit the varibale name after the `NEXT` statement.

Note #3: the runtime library will not check the consistency of your `FOR ... NEXT` blocks. If there is a `NEXT` without `FOR`, for example, the program will likely break.

### FERR

The `FERR` function returns error information subsequent to the last `LOAD` or `SAVE` statement.

If the return value is zero, no error occurred. Otherwise the value will hold the matching KERNAL error code.

Example:

	load "myfile",8
	err = ferr()
	if err = 0 then print "success" else goto load_error
	end
	load_error:
		print "an error occurred"
		rem ** more error handling **

Example error codes:

- 4: file not found
- 5: device not present
- 8: missing file name
- 9: illegal device number
- 29: load error
- 30: break (user pressed break button)

### GOTO

Continues execution of the program from the given label. Syntax:

	goto label

### GOSUB ... RETURN

Calls a subroutine marked by a label. Return will pass control back to the caller. Nesting subroutines are supported (`GOSUB` and `RETURN` compiles to just plain `JSR` and `RTS`, nothing fancy). Stack overflow is not checked in runtime, but is quite unlikely to encounter. Example:

	rem ** subroutines **
	gosub first_routine
	end
	
	first_routine:
		print "hello world"
		gosub second_routine
		return
		
	second_routine:
		print "and hello again"
		return

Note #1: make sure to use the `END` command before your routines if you don't want them to be executed in the normal program flow (like in the example above).

Note #2: there is no runtime call stack checking (e. g. no `?RETURN WITHOUT GOSUB ERROR`). If your call stack is corrupted, the program is likely to break.

Note #3: Unlike procedures, subroutines do not open a new local scope.

### IF ... THEN ... ELSE

Syntax:

	if relation <and/or relation> then statement <else statement>
	
Conditional structure. Executes the statement after `THEN` if the expression evaluates to true, otherwise the statement after `ELSE`, if present. `ELSE` is optional.

Current limitations:

- Only one conditional operation (`AND`/`OR`) is supported
- Only one command can be executed after `THEN` and `ELSE` each
- `THEN` may not be omitted

Expressions support conditional operators (`AND` and `OR`) since version 1.0.

Examples:

	if x >= y/z then print "yes, expression is true"
	if a = b then print "they are equal" else print "they are not equal"
	if a = b or a < 2 then print "they are equal or a is less than two"
	
Please refer to the "Expressions" section for the list of supported operators.

### INC

Increments the value of an integer variable by 1. This is considerably faster than doing `LET x = x + 1`. Example:

	let myVar = 10
	inc myVar
	print myVar

The above will output 11.

### INCBIN

Syntax:

	incbin "filename"

The `INCBIN` comand instructs the assembler to include a custom binary file. This is useful to include graphics, music or any kind of data - even machine code routines - in your program.

**Note**: the included file must be in the same folder where the XC-BASIC source is.

**Important note**: you have to be very careful when using `INCBIN` as the binary stream will be "injected" into the program right at the point where the compiler finds the command. Make sure that the included data is outside the program flow (unless it's meant to be).

An example of wrong usage:

	rem program starts here
	print "welcome to my buggy game"
	incbin "sprites.bin"
	print "now let's play"
	
In the example above, after printing the welcome message, the program will try to execute whatever is in "sprites.bin" which will likely result in a crash. The good practice is to separate your code and data or use a `GOTO` statement to skip unwanted parts of the program.

The above example fixed:

	rem program starts here
	goto start
	incbin "sprites.bin"
	start:
		print "welcome to my cool game"
		print "now let's play"
		
Or:

	rem program starts here
	print "welcome to my cool game"
	print "now let's play"
	end
	incbin "sprites.bin"
		
Although the compiler will let you know the exact addresses where the included files got assembled within the final executable, these addresses may be changing. In most cases you will want to use `INCBIN` in combination with `ORIGIN` to make sure that your included binaries are always located at the same address.

### INKEY

Syntax:

	let key = inkey()
	
The `INKEY()` function returns the keyboard code of the currently pressed key. If no key is pressed, the return value is 0. Example:

	print "press a key"
	loop:
		let key = inkey()
		if key = 0 then goto loop
	print "you pressed: ", key
	
### INPUT

Calls a built-in routine that allows the user to input numbers using the keyboard. Only decimal integer inputs are supported currently. If there are more than one variable in the argument list, the routine will prompt to input the values one by one. Examples:

	input x
	input x, y, z
	
### LET

Assigns the value of an expression to a variable. Examples:

	let somevar = 5
	let somearray[n] = x * 2
	
Important! **Prior to version 1.0, the `LET` keyword may not be omited** as in other BASIC dialects.

	rem ** works in v1.0+ only **
	x = 5
	
### LOAD

Syntax:

	load "filename", device_no <,start_address>
	
Loads a binary file from the given device into memory using the KERNAL load routine. If `start_address` is not specified, the first to bytes (LB/HB) of the file will be used as the start address. Otherwise the first two bytes of the file will be discarded and the rest will be loaded into the memory addres specified by `start_address`.

Use the `FERR` function to get error information on the loading process.
	
### ORIGIN

Syntax:

	origin address

The `ORIGIN` command instructs the underlying assembler to locate the code or data that follows to a specific location instead of the normal flow.

- If the new address is less than the current address, the program won't compile.
- If the new address is greater than the current address, the gap between the current and new address will be filled in with $FF bytes.

The `ORIGIN` command can take a decimal or hexadecimal address, but no variables, constants or expressions are allowed here.

Example:

	rem the program starts here
	goto start
	incbin "sprites.bin"
	origin $3800
	incbin "charset.bin"
	origin $4000
	start:
		rem the actual code starts here
		print "welcome to my game"
		
In the example above, sprite data will start right after the `GOTO` statement. The gap between the sprites and the charset will be filled with $FF-s.

It is very important that the program code must never execute the empty gaps between the different "segments" that you define with `ORIGIN`, because that would lead to a crash. Consider the following example:

	rem segment #1
	print "hello world"

	origin $1000
	rem segment #2
	print "hello again"
	
The above program will break if there is a gap between the two segments. The good practice is the following:

	rem segment #1
	print "hello world"
	goto seg2
	
	origin $1000
	rem segment #2
	seg2:
	print "hello again"
	
### PEEK

The `PEEK` function returns the value that is read from a memory address. Example:

	let value = peek(n)

The same number conversions apply as discussed further in the next section.

### POKE

Syntax:

	poke address, value

Stores a value in the given memory address. Both the address and the value are integers, thus the following conversions will be made:

- The address will be recognized as an unsigned integer, or if it's an expression, a signed integer will be converted to unsigned
- The value will be truncated to 8 bits

Examples:

	rem ** turn border to black **
	poke 53280, 0
	
	rem ** unsigned conversion **
	let x = -5
	poke x, 0
	rem ** which will effectively be the same as:
	poke 65531,0
	
	rem ** values are truncated to 8 bits - the MSB is discarded **
	poke 53280, 65535
	rem ** will be the same as
	poke 53820, 255

### PRINT

Prints strings or numbers (values of any expression) on the screen using the KERNAL CHAROUT routine. Any number of arguments are accepted. The arguments must be separated with a comma (`,`). Examples:

	print "hello world"
	print "the value of myvar is ", myvar, " and that of anothervar is ", anothervar
	print "let's print the value of an expression: ", (486 + y) * 3
	
ASCII strings will be converted to PETSCII in compile-time.

### PROC ... ENDPROC

The `PROC` statement introduces a new procedure that spans until the `ENDPROC` statement. Procedures are named subroutines that have a unique variable and label scope. Procedures may have one or more parameters that are passed to by the `CALL` statement. The `CALL` statement is the only way to execute a procedure (you can't `GOTO` into a procedure, for example). You can use `RETURN` to early exit a procedure.

Syntax:

	proc proc_name (parameter_list)
	endproc
	call proc_name (argument_list)

Example:

	rem ** procedure example **
	rem ** these variables are global **
	let a = 1
	let b = 2
	
	proc printmin(x, y)
		rem ** x, y and a are local variables **
		let a = 3
		if x < y then print x else print y
	endproc

	call printmin(a, b)
	call printmin(-1, -5)
	print a

The above program will output (note that the value of `a` remained 1 in the global scope):

	1
	-5
	1
	
To access global variables from within a procedure, prefix the variable name with the `\` modifier. Example:

	let a=1
	proc someproc
		let a=2
		print \a
	endproc

	rem ** will display: 1	
	call someproc


Local variables of a procedure are *static* which means they are not dinamically allocated on each procedure call. This also means they keep their values through subsequent executions of the same procedure. Take the following example.

	proc staticexample(firstrun)
		dim a
		if firstrun = 1 then let a = 1 else inc a[0]
		print a
	endproc
	
	call staticexample(1)
	call staticexample(0)
	
The above program will output:

	1
	2
	
To declare and call parameterless procedures, just omit the parentheses:

	proc simpleproc
		print "simpleproc called"
	endproc
	
	call simpleproc
		
### REM

A remark, just as you'd expect. Everything until the end of line is ignored.

### RND

The `RND` function returns a pseudo-random integer between -32768 and +32767. Example:

	print "we'll flip a coin"
	if rnd() < 0 then print "heads" else print "tails"
	
Note: needless to say that the number returned by `RND` is not a true random number.

### SAVE

The `SAVE` command saves the given memory area into a file on the given device. Syntax:

	save "filename", device_no, start_address, end_address
	
The first two bytes in the file will contain the start address.

Note: The last byte written in the file will be `end_address - 1`.

Note: Prepend the file name with `@0:` to overwrite an existing file on disk. Example:

	save "@0:existingfile", 8, 49152, 49408

Use the `FERR` function to get error information on the saving process.

### SYS

The `SYS` command calls a machine language routine at a apecified address. Syntax:

	sys expression
	
The expression must return an integer and will be treated as unsigned. Once the machine language routine returns using the `RTS` opcode, the XC-BASIC program will continue at the next line.

Note that `SYS` can't pass parameters to the machine language routine, nor has any return value. For calling machine language functions, see `USR`.

### TEXTAT

Syntax:

	textat column, row, "string literal"
	
or:

	textat column, row, numeric_expression
	
Outputs a string or a number a the given column and row on the screen. Accepts integers for `colum` and `row`, and a string literal or a numeric expression as the text output. Examples:

	textat 15, 10, "hello world"
	rem ** the following will output "200" as text
	textat 15, 10, 200

Note: the runtime library will not prevent the text from overflowing outside the screen thus damaging data or code. The programmer has to make sure the text fits within the screen RAM ($0400-$07E7).

### USR

The `USR` function passes an arbitrary length of parameters to a machine language routine, executes it, and then uses the return value of the machine language routine as the value of the function.

Usage:

	let retval = usr(address, arg1, arg2, ...)
	
The arguments are available on the stack for the machine language routine. The routine can access them in the same order as they're passed, but in reverse byte order. The routine is then supposed to push the return value back to the stack in normal order and exit using `JMP ($02fe)` (NOT `RTS`!) For example:

	; this is the ML routine
	ORG $c000
	PLA ; get x high byte
	STA arg1+1
	PLA ; get x low byte
	STA arg1
	PLA ; get y high byte
	STA arg2+1
	PLA ; get y low byte
	STA arg2
	
	<do whatever>
	
	LDA result
	PHA
	LDA result+1
	PHA
	JMP ($02fe) ; note this is the only valid way to return from an user function
	
	rem ***
	rem *** XC-BASIC program starts here
	const MY_FUNC = 49152
	let x = 1
	let y = 2
	print usr(MY_FUNC, x, y)

Note #1: For string arguments, the two-byte address of the string will be passed to the ML routine. Strings are nullbyte-terminated.

Note #2: The callee *must* pull all arguments from the stack and *must* push exactly 2 bytes (as of current version). The program will break otherwise.

### @ (address of) operator

Used within an expression, the `@` operator returns the memory address of the variable that it is prepended to, as an integer.

Example:

	rem define a new variable
	let x=1
	
	rem retrieve information about the variable
	print "the value of x is ", x
	print "the address of x is ", @x

# Using the compiler

## Installation

### Method 1: compile from source

**xcbasic64** is written in D, using the DUB package manager.

1. Install DUB
2. Clone this repository
3. Enter `dub build` to compile from source
4. The executable will be in the project root.

### Method 2: use a pre-built binary

There are pre-built binaries in the `dist/` directory of this repo (currently for Windows and Linux).

## Usage

Since version 1.0, the DASM executable is included in the project and XC-BASIC sources can be compiled to machine code using a single command.

Usage in Windows:

	xcb.bat source.bas target.prg
	
Usage in Linux:

	./xcb source.bas target.prg
	
That's all you have to use in most of the cases. However, you can still use the binaries in the `bin/` directory to see and debug the intermediate assembly listing.

The command line usage of the binarry is:

	xcbasic64 source.bas > target.asm
	
You can omit the output redirection if you just want to see the result on the screen.

The target then can be compiled using DASM:

	dasm target.asm
	
Or using a singe lline command:

	xcbasic64 source.bas > target.asm && dasm target.asm
	
# Credits

- XC-BASIC is using Philippe Sigaud's fantastic [Pegged library](https://github.com/PhilippeSigaud/Pegged) for grammar parsing
- Since version 1.0, the [DASM](http://dasm-dillon.sourceforge.net/) executable is included in the project, please see `third_party/dasm-2.20.11/LICENSE` for more information.
- Many ML routines have been borrowed from miscellaneous sources, their authors - if known - are credited within the source code. If you find your piece and your name is not credited, please drop me a line or post an issue here on GitHub and I'll fix my mistake!

