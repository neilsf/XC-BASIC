rem ----------------------------------------------
rem -- splash screen
rem -- written by Eric Hilaire aka Majikeyric
rem --
rem -- to be compiled using
rem -- XC=BASIC v2.1
rem ----------------------------------------------

dim	screen
dim	colors
dim	bitmap
dim	screen2
dim	chargen

dim	col!
dim	backcol!
dim	car
dim	i!
dim	j!
dim	k!

dim	width!
dim	height!
dim	nbcars
dim	offset_colors
dim	offset_bitmap
dim	modulo_colors
dim	modulo_bitmap
dim bin
		
const HEADER_SIZE = 12

screen2	= $4c00
screen =  $0400
colors	= $d800
bitmap	= $6000
bin		= @splash_bin

rem --- Get splash screen params from binary header

width! 			= peek!(bin)
height!			= peek!(bin+1)
nbcars 			= deek(bin+2)
offset_colors	= deek(bin+4)
offset_bitmap 	= deek(bin+6)
modulo_colors 	= deek(bin+8)
modulo_bitmap 	= deek(bin+10)

disableirq
   
backcol!=peek!($d021) & $0f

rem	--- Convert actual screen to bitmap hires
	   
repeat

	poke screen2,lshift!(peek!(colors),4) | backcol!
	inc	colors
	inc	screen2
			
	car=peek(screen)
	inc	screen
	chargen=$d000+lshift(car,3)

	asm	"
		 lda #$33
		 sta $01
		"

	i!=0
	repeat
		poke bitmap,peek!(chargen)
		inc bitmap
		inc chargen
		inc	i!
	until i!=8
   
	asm	"
		 lda #$36
		 sta $01
		"

until screen=$07e8
			
rem	--- Build splash screen on bitmap
		
screen	=$4c00+offset_colors
screen2	=$6000+offset_bitmap
colors	=bin+HEADER_SIZE
bitmap	=bin+HEADER_SIZE+nbcars
		
i!=0
repeat
	j!=0
	repeat
		poke screen,peek!(colors)
		inc colors
		inc screen
   
		k!=0
		repeat
			poke screen2,peek!(bitmap)
			inc screen2
			inc bitmap
			inc	k!
		until k!=8
				
		inc j!
	until j!=width!
			
	screen=screen+modulo_colors
	screen2=screen2+modulo_bitmap
			
	inc i!
until i!=height!
   
rem --- Display hires bitmap and loop

wait $d011,$80,$80	: rem --- Wait VBL
wait $d011,$80,$00

poke $d018,$38
poke $d016,8
poke $dd00,2
poke $d011,$3b
loop:
goto loop

origin $0f00

splash_bin:

incbin "arcia.bin" 
