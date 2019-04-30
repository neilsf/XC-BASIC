dim snake_pieces[256]

gosub cls
textat 7,8,"welcome to xc-basic snake!"
textat 15,10,"controls:"
poke 1523,137
poke 1562,138
poke 1564,140
poke 1603,139
textat 14,16,"press a key"
key_loop0:
		if inkey() = 0 then goto key_loop0

rem this is a remark
rem it just fuckin works

game_loop:
	gosub cls
	let snake_length = 4
	let head_x = 19
	let head_y = 10
	let dx = 1
	let dy = 0
	let speed = 16
	let hit = 0
	for i=0 to snake_length
		let snake_pieces[i] = 415+i
		poke 1439+i, 209
	next i
	
	gosub new_food
	gosub move_loop
	if hit = 1 then gosub game_over 
	goto game_loop

	game_over:
		textat 16,10,  "game over"
		textat 15,11, "press a key"
		key_loop:
			if inkey() = 0 then goto key_loop
		return

	move_loop:
		
		poke 1024+snake_pieces[0], 32
		gosub get_input
		for i=0 to snake_length-1
			let snake_pieces[i] = snake_pieces[i+1]
		next i
		let head_x = head_x+dx
		let head_y = head_y+dy
		let snake_pieces[snake_length] = head_x + 40 * head_y
		gosub check_hit
		if hit = 1 then return
		gosub check_eat
		for i=1 to speed
			gosub wait_frame
		next i
		gosub update_screen
		goto move_loop

	wait_frame:
		if peek(53266) < 250 then goto wait_frame
		return

	update_screen:
		poke 1024+snake_pieces[snake_length], 209
		return

	get_input:
		let key=inkey()
		if key = 73 then goto move_up
		if key = 74 then goto move_left
		if key = 75 then goto move_down
		if key = 76 then goto move_right
		return
		move_up:
			if dy = 1 then return
			let dx = 0
			let dy = -1
			return
		move_left:
			if dx = 1 then return
			let dx = -1
			let dy = 0
			return
		move_down:
			if dy = -1 then return
			let dx = 0
			let dy = 1
			return
		move_right:
			if dx = -1 then return
			let dx = 1
			let dy = 0
			return

	new_food:
		let food_loc = rnd()/32
		if food_loc < 0 then let food_loc = food_loc * -1
		if food_loc > 999 then goto new_food
		if peek(1024+food_loc) <> 32 then goto new_food
		poke 1024+food_loc, 42
		return

	check_hit:
		if head_x = 40 then let hit = 1
		if head_x = -1 then let hit = 1
		if head_y = 0 then let hit = 1
		if head_y = 25 then let hit = 1

		if peek(1024+head_x + 40*head_y) = 209 then let hit = 1
		return 

	check_eat:
		if peek(1024+head_x + 40*head_y) = 32 then return
		let snake_length = snake_length + 1
		let snake_pieces[snake_length] = head_x + 40*head_y
		textat 8,0, "   "
		textat 8,0, snake_length
		poke 1032, peek(1032)+128
		poke 1033, peek(1033)+128
		poke 1034, peek(1034)+128
		
		let speed = 16-snake_length/16
		
		textat 38,0, "  "
		textat 38,0, 17-speed
		poke 1062, peek(1062)+128
		poke 1063, peek(1063)+128

		gosub new_food
		return
end

cls:
	poke 53280,5
	poke 53281,0
	for i=0 to 999
		poke 1024+i, 32
		poke 55296+i, 5
	next i
	textat 0,0, "length: 4     xc-basic snake   speed: 1"
	for i=1024 to 1063
		poke i, peek(i)+128
	next i
	return
