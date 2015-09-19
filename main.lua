-- tiny snake game <3

local WINDOW_X, WINDOW_Y = love.window.getDimensions()
local TILE_SIZE = WINDOW_Y / 16
local SIZE_Y = WINDOW_Y / TILE_SIZE
local SIZE_X = WINDOW_X / TILE_SIZE
local TAIL_BEGIN = 3
local TILE_NONE 
	TILE_TAIL,
	TILE_POWERUP =
	0, 1, 2

local DIR_LEFT,
	DIR_RIGHT,
	DIR_UP,
	DIR_DOWN =
	0, 1, 2, 3

local dir = DIR_RIGHT
local prevDir = dir
local tail = {}
local tailshifted = false
local length = 0
local powerup = {}
local numPowerups = 0
local difficulty = 8

local time = 0
local prevBonus = time

function love.load()
	math.randomseed(os.time())
	reset()
end

function love.update(dt)
	local prev = time
	time = time + dt

	for i = 1, numPowerups, 1 do
		local lifetime = powerup[i][3]
		if lifetime > -1 then
			lifetime = lifetime - dt
			if lifetime < 0 then
				powerup[i] = powerup[numPowerups]
				--powerup[numPowerups] = nil
				numPowerups = numPowerups - 1
				i = i - 1
			else
				powerup[i][3] = lifetime
			end
		end
	end

	if time - prevBonus >= 8 then
		prevBonus = prevBonus + (time - prevBonus)
		spawn(true)
	end

	if math.floor(prev * difficulty) < math.floor(time * difficulty) then
		tick()
	end
end

function tick()
	prevDir = dir
	tailshifted = false
	move()
end

function move()
	local dirX, dirY = getDirXY()
	local x = tail[length][1] + dirX
	local y = tail[length][2] + dirY

	if not tailshifted then
		for i = 1, length - 1, 1 do
			tail[i] = tail[i + 1]
		end
		tailshifted = true
	end

	if x < 0 or 
	x >= SIZE_X or 
	y < 0 or 
	y >= SIZE_Y or 
	get(x, y) == TILE_TAIL then
		reset()
		return
	end

	tail[length] = {x, y}

	if pickup(x, y) == TILE_POWERUP then
		length = length + 1
		tail[length] = {x, y}
		move()
	end
end

function reset()
	time = 0
	dir = DIR_RIGHT
	prevDir = dir
	tail = {}
	tailshifted = false
	length = TAIL_BEGIN
	for i = 1, TAIL_BEGIN, 1 do
		tail[i] = {i, (SIZE_Y / 2)}
	end
	powerup = {}
	numPowerups = 0
	prevBonus = time
	spawn()
end

function get(x, y)
	for i = 1, numPowerups, 1 do
		if powerup[i][1] == x and powerup[i][2] == y then
			return TILE_POWERUP
		end
	end

	for i = 1, length, 1 do
		if tail[i][1] == x and tail[i][2] == y then
			return TILE_TAIL
		end
	end

	return TILE_NONE
end

function spawn(bonus)
	while true do
		local x, y = math.random(SIZE_X - 1), math.random(SIZE_Y - 1)
		if get(x, y) == TILE_NONE and
		not (x == 0 and y == 0) and 
		not (x == 0 and y == SIZE_Y - 1) and 
		not (x == SIZE_X - 1 and y == 0) and
		not (x == SIZE_X - 1 and y == SIZE_Y - 1) then
			numPowerups = numPowerups + 1;
			if bonus then
				powerup[numPowerups] = {x, y, 5}
			else
				powerup[numPowerups] = {x, y, -1}
			end
			break
		end
	end
end

function pickup(x, y)
	for i = 1, numPowerups, 1 do
		if powerup[i][1] == x and powerup[i][2] == y then
			if powerup[i][3] == -1 then
				spawn()
			end
			powerup[i] = powerup[numPowerups]
			powerup[numPowerups] = nil
			numPowerups = numPowerups - 1
			return TILE_POWERUP
		end
	end
	return TILE_NONE
end

function getDirXY()
	if dir == DIR_LEFT then return -1, 0
	elseif dir == DIR_RIGHT then return 1, 0
	elseif dir == DIR_UP then return 0, -1
	else return 0, 1
	end
end

function love.draw()
	love.graphics.setColor(12, 12, 12)
	love.graphics.rectangle('fill', 0, 0, WINDOW_X, WINDOW_Y)
	love.graphics.setColor(20, 20, 20)
	for y = 0, SIZE_Y / 2, 1 do
		for x = 0, SIZE_X / 2, 1 do
			if x % 2 == 0 and y % 2 == 0 or x % 2 ~= 0 and y % 2 ~= 0 then
				love.graphics.rectangle('fill', x * TILE_SIZE * 2, y * TILE_SIZE * 2, TILE_SIZE * 2, TILE_SIZE * 2)
			end
		end
	end

	love.graphics.setColor(255, 0, 0)
	for i = 2, length - 1, 1 do
		love.graphics.rectangle('fill', tail[i][1] * TILE_SIZE, tail[i][2] * TILE_SIZE, TILE_SIZE, TILE_SIZE)
	end

	-- animate head
	if prevDir == DIR_LEFT then
		love.graphics.rectangle('fill', (tail[length][1] + (1 - time * difficulty % 1)) * TILE_SIZE, tail[length][2] * TILE_SIZE, TILE_SIZE * (time * difficulty % 1), TILE_SIZE)
	elseif prevDir == DIR_RIGHT then
		love.graphics.rectangle('fill', tail[length][1] * TILE_SIZE, tail[length][2] * TILE_SIZE, TILE_SIZE * (time * difficulty % 1), TILE_SIZE)
	elseif prevDir == DIR_UP then
		love.graphics.rectangle('fill', tail[length][1] * TILE_SIZE, (tail[length][2] + (1 - time * difficulty % 1)) * TILE_SIZE, TILE_SIZE, TILE_SIZE * (time * difficulty % 1))
	else -- if prefDir == DIR_DOWN then
		love.graphics.rectangle('fill', tail[length][1] * TILE_SIZE, tail[length][2] * TILE_SIZE, TILE_SIZE, TILE_SIZE * (time * difficulty % 1))
	end

	-- animate tail
	if length > 1 then
		if tail[1][1] < tail[2][1] then
		love.graphics.rectangle('fill', (tail[1][1] + time * difficulty % 1) * TILE_SIZE, tail[1][2] * TILE_SIZE, TILE_SIZE * (1 - time * difficulty % 1), TILE_SIZE)
		elseif tail[1][1] > tail[2][1] then
		love.graphics.rectangle('fill', tail[1][1] * TILE_SIZE, tail[1][2] * TILE_SIZE, TILE_SIZE * (1 - time * difficulty % 1), TILE_SIZE)
		elseif tail[1][2] < tail[2][2] then
		love.graphics.rectangle('fill', tail[1][1] * TILE_SIZE, (tail[1][2] + time * difficulty % 1) * TILE_SIZE, TILE_SIZE, TILE_SIZE * (1 - time * difficulty % 1))
		else -- if tail[1][2] > tail[2][2] then
		love.graphics.rectangle('fill', tail[1][1] * TILE_SIZE, tail[1][2] * TILE_SIZE, TILE_SIZE, TILE_SIZE * (1 - time * difficulty % 1))
		end
	end

	for i = 1, numPowerups, 1 do
		love.graphics.rectangle('fill', powerup[i][1] * TILE_SIZE, powerup[i][2] * TILE_SIZE, TILE_SIZE, TILE_SIZE)
	end
end

function love.keypressed(key, isrepeat)
	if not isrepeat then
		if (key == 'left' or key == 'a') and prevDir ~= DIR_LEFT and prevDir ~= DIR_RIGHT then
			dir = DIR_LEFT
		elseif (key == 'right' or key == 'd') and prevDir ~= DIR_LEFT and prevDir ~= DIR_RIGHT then
			dir = DIR_RIGHT
		elseif (key == 'up' or key == 'w') and prevDir ~= DIR_UP and prevDir ~= DIR_DOWN then
			dir = DIR_UP
		elseif (key == 'down' or key == 's') and prevDir ~= DIR_UP and prevDir ~= DIR_DOWN then
			dir = DIR_DOWN
		end
	end
end
