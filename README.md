**XC-BASIC** is a dialect of the BASIC programming language for the Commodore-64 and **xcbasic64** is a cross-compiler that compiles **XC-BASIC** source code to assembly source (in DASM format). 

Some of the advantages of programming in **XC-BASIC** are:

- Cross development - use your favourite OS/editor/etc.
- Higher execution speed  - no interpreter, the source can be compiled to pure machine code in two steps.
- More available memory - the program does not require the BASIC ROM to be present, which means the program code may span from $0801 to $CFFF - a total of 50K!

**XC-BASIC** is based on Tiny BASIC, with many differences in syntax.

# Language reference

## General syntax
A **XC-BASIC** program consists of lines, allowing only one statement per line. A line may be prepended by a label or the label can be written in a separate line. For example:

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

## Variables

Variables are automatically declared upon the first `LET`, `DIM` or `ḊATA` statement that the compiler encounters. Every variable has a type that cannot be changed after declaration. The variable type is defined by appending the variable type modifier to the variable name. The valid types are:

- **Signed short integers** (-32768 to +32767), where variable names are prepended with the `#` modifier (this is the default and the modifier can be omitted, i. e. `myInt#` is the same as `myInt`)
- **Floating point numbers** (*coming soon!*),  where variable names are prepended with the `%` modifier
- **Strings** (*coming soon!*), where variable names are prepended with the `$` modifier

Variable names can be of any length, they can consist of letters and numbers, but they may not start with a number. Variable names are case-sensitive.

## Arrays

Arrays must be defined using the `DIM` statement. As of the current version, maximum two-dimensional arrays are supported and both dimensions are limited to a length of 32767 elements. However, this is just a theoretical limit, in practice you'll run out of memory earlier. Arrays are zero-based (the first index is 0) and only integers may be used as indices.

The syntax to define array is the following (not square brackets):

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

Numeric expressions are evaluated just like in BASIC V2 or any other BASIC dialects. The valid operators are `*`, `/`, `+` and `-`. Parentheses are also supported. Example:

	let x = (14 + y) *42 / (20 - z)

More operators coming soon.

## Strings

As of the current version, only constant strings (literals) are supported. Strings are enclosed in double quotes (`"`) and can be used as the argument of the `PRINT` and `TEXTAT` commands. All characters in strings will be translated from ASCII to PETSCII or screencodes, depending on the context.

There are several escape sequences that you can use in string literals to be able to print special PETSCII characters.

- The escape sequence `{num}` (where num is a decimal number) will be replaced by the PETSCII code indicated by `num`.
- You can also use the following convenience escape sequences: `{CLR}`, `{HOME}`, `{INSERT}`, `{DEL}`, `{CR}`, `{REV_ON}`, `{REV_OFF}`, `{CRSR_UP}`, `{CRSR_DOWN}`, `{CRSR_LEFT}`, `{CRSR_RIGHT}`

Examples:

	print "{CLR}welcome to a fresh new screen"
	print "this is line one{CR}and this is line two"
	print "{5}white text"

As for the screencodes (used by `TEXTAT`), you can use the `{num}` escape sequence - remember to use screencodes instead of PETSCII.

## Error conditions

For the sake of execution speed, there is only one error condition that is checked in runtime, the **division by zero**. The compiler will try to detect static (compile time) errors in code, but naturally it can't predict runtime error conditions. In each statement's documentation you can read the possible error conditions that you, the programmer have to take care of.

## List of commands

The following is the list of the commands supported by **XC-BASIC**, in alphabetical order:

`CHARAT` | `DATA` | `DIM` | `END` | `FOR ... NEXT` |  `GOSUB ... RETURN` | `GOTO` | `IF ... THEN ... ELSE` | `INKEY` | `INPUT` | `LET` |  `PEEK` | `POKE`  | `REM` | `RND` | `TEXTAT` 

More commands are coming soon!

### CHARAT

Syntax:

	charat column, row, screencode

Outputs a character at the given column and row on the screen. Accepts integers for `colum` and `row`, and another integer for the `screencode`. Example:

	rem this puts an 'A' near the center of the screeen
	charat 20, 10, 65 
	
Note that the runtime library will not check if the values are within the screen boundaries. As `CHARAT` is just a convenience wrapper around `POKE`, it can overwrite memory locations other than the screen memory, thus damaging the program or data. Use it with special care.

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

### DIM

Defines an array. See the Arrays section for more information.

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

### IF ... THEN ... ELSE

Syntax:

	if condition then statement <else statement>
	
Conditional structure. Executes the statement after `THEN` if the expression evaluates to true, otherwise the statement after `ELSE`, if present. `ELSE` is optional.

Current limitations:

- Expressions do not support logical operators (`OR`, `AND` - *coming soon!*)
- Only one command can be executed after `THEN` and `ELSE`
- `THEN` may not be omitted

Examples:

	if x >= y/z then print "yes, expression is true"
	if a = b then print "they are equal" else print "they are not equal"
	
The supported relational operators are:

- `=` (equal)
- `>` (greater than)
- `>=` (greater than or equal)
- `<` (less than)
- `<=` (less than or equal)
- `<>` (not equal)

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

Assigns the value of an expression to a variable. The keyword `LET` can not be omitted as in other BASIC dialects. Examples:

	let somevar = 5
	let somearray[n] = x * 2
	
### PRINT

Prints strings or numbers (values of any expression) on the screen using the KERNAL CHAROUT routine. Any number of arguments are accepted. The arguments must be separated with a colon (`,`). Examples:

	print "hello world"
	print "the value of myvar is ", myvar, " and that of anothervar is ", anothervar
	print "let's print the value of an expression: ", (486 + y) * 3
	
ASCII strings will be converted to PETSCII in compile-time.

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

### PEEK

The `PEEK` function returns the value that is read from a memory address. The same conversions apply to the address as discussed above. Example:

	let value = peek(n)

### REM

A remark, just as you'd expect. Everything until the end of line is ignored.

### RND

The `RND` function returns a pseudo-random integer between -32768 and +32767. Example:

	print "we'll flip a coin"
	if rnd() < 0 then print "heads" else print "tails"
	
Note: needless to say that the number returned by `RND` is not a true random number.

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

# Using the compiler

Use **xcbasic64** to compile XC-BASIC source code to assembly source. Then use DASM (not included in the source) to assemble to machine code. 

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

Command line usage is:

	xcbasic64 source.bas > target.asm
	
You can omit the output redirection if you just want to see the result on the screen.

The target then can be compiled using DASM:

	dasm target.asm
	
Or using a singe lline command:

	xcbasic64 source.bas > target.asm && dasm target.asm
	
