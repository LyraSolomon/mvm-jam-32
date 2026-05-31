world = usagi.read_json("map.json")
current_scene = "initial"
for _, room in pairs(world) do
	if type(room) == "table" then
		table.insert(room.walls, {
			bottom = { x = 1, y = usagi.GAME_H - 1 },
			top = { x = 1, y = 1 },
			position = "w"
		})
		table.insert(room.walls, {
			bottom = { x = usagi.GAME_W - 1, y = usagi.GAME_H - 1 },
			top = { x = usagi.GAME_W - 1, y = 1 },
			position = "e"
		})
		table.insert(room.floors, {
			left = { x = 1, y = usagi.GAME_H - 1 },
			right = { x = usagi.GAME_W - 1, y = usagi.GAME_H - 1 },
			position = "s"
		})
		table.insert(room.floors, {
			left = { x = 1, y = 1 },
			right = { x = usagi.GAME_W - 1, y = 1 },
			position = "n"
		})
	end
end

function world:draw()
	for _, transition in pairs(world[current_scene].transitions) do
		gfx.rect_fill(
			transition.x1,
			transition.y1,
			transition.x2 - transition.x1,
			transition.y2 - transition.y1,
			gfx.COLOR_DARK_GRAY
		)
	end
	-- integer wall positions place barrier between pixels
	-- this draws the wall on the pixel outside
	for _, wall in pairs(world[current_scene].walls) do
		local offset = 0
		if wall.position == "e" then
			offset = 1
		end
		local color = gfx.COLOR_DARK_BLUE
		if wall.mark == "err" then
			color = gfx.COLOR_RED
		end
		gfx.line(
			wall.bottom.x + offset,
			wall.bottom.y,
			wall.top.x + offset,
			wall.top.y,
			color
		)
	end
	for _, floor in pairs(world[current_scene].floors) do
		local offset = 0
		if floor.position == "n" then
			offset = -1
		end
		local color = gfx.COLOR_DARK_BLUE
		if floor.mark == "err" then
			color = gfx.COLOR_RED
		end
		gfx.line(
			floor.left.x,
			floor.left.y + offset,
			floor.right.x,
			floor.right.y + offset,
			color
		)
	end
	for _, enemy in pairs(world[current_scene].active_enemies) do
		enemy:draw()
	end
end

function world:update_enemies(dt)
	for _, enemy in pairs(world[current_scene].active_enemies) do
		enemy:update(dt)
	end
end

function world:spawn_enemies()
	for _, room in pairs(world) do
		if type(room) == "table" then
			room.active_enemies = {}
			for i, enemy in pairs(room.enemies) do
				room.active_enemies[i] = enemies[enemy.name]:spawn(enemy.settings)
			end
		end
	end
end

world:spawn_enemies()

function world:update_room()
	for _, transition in pairs(world[current_scene].transitions) do
		if
			player.aabb.x >= transition.x1
			and player.aabb.x <= transition.x2
			and player.aabb.y >= transition.y1
			and player.aabb.y <= transition.y2
		then
			if transition.target.x then
				player.aabb.x = transition.target.x
			end
			if transition.target.y then
				player.aabb.y = transition.target.y
			end
			current_scene = transition.target.room
			break
		end
	end
end

function world:validate()
	for scene, room in pairs(world) do
		if type(room) == "table" then
			-- 1: walls must be at least player height and floors at least player width
			-- otherwise they can get stuck inside the player
			-- 2: wall/floor endpoints must form a corner
			local min_height = player.aabb.h + 1
			local min_width = player.aabb.w + 1
			for i, wall in pairs(room.walls) do
				wall.mark = nil
				if wall.bottom.x ~= wall.top.x or
				   wall.bottom.y <= wall.top.y or
				   wall.position ~= "e" and wall.position ~= "w" then
					print("world validation: invalid " .. scene .. ".wall[" .. i .. "]")
					wall.mark = "err"
				else
					if wall.bottom.y - wall.top.y < min_height then
						print("world validation: length of " .. scene .. ".wall[" .. i .. "]")
						wall.mark = "err"
					end
					local connection_s = false
					local connection_n = false
					for _, floor in pairs(room.floors) do
						if wall.position == "e" and floor.position == "s" or
						   wall.position == "w" and floor.position == "n" then
							if floor.left.x < wall.bottom.x and
							   floor.right.x >= wall.bottom.x and
							   floor.right.y == wall.bottom.y then
								connection_s = true
							end
							if floor.left.x <= wall.top.x and
							   floor.right.x > wall.top.x and
							   floor.left.y == wall.top.y then
								connection_n = true
							end
						else
							if floor.left.x <= wall.bottom.x and
							   floor.right.x > wall.bottom.x and
							   floor.left.y == wall.bottom.y then
								connection_s = true
							end
							if floor.left.x < wall.top.x and
							   floor.right.x >= wall.top.x and
							   floor.right.y == wall.top.y then
								connection_n = true
							end
						end
					end
					if not connection_s then
						print("world validation: no connection to bottom of " .. scene .. ".wall[" .. i .. "]")
						wall.mark = "err"
					end
					if not connection_n then
						print("world validation: no connection to top of " .. scene .. ".wall[" .. i .. "]")
						wall.mark = "err"
					end
				end
			end
			for i, floor in pairs(room.floors) do
				floor.mark = nil
				if floor.right.y ~= floor.left.y or
				   floor.right.x <= floor.left.x or
				   floor.position ~= "n" and floor.position ~= "s" then
					print("world validation: invalid " .. scene .. ".floor[" .. i .. "]")
					floor.mark = "err"
				else
					if floor.right.x - floor.left.x < min_width then
						print("world validation: length of " .. scene .. ".floor[" .. i .. "]")
						floor.mark = "err"
					end
					local connection_e = false
					local connection_w = false
					for _, wall in pairs(room.walls) do
						if wall.position == "e" and floor.position == "s" or
						   wall.position == "w" and floor.position == "n" then
							if wall.top.y < floor.right.y and
							   wall.bottom.y >= floor.right.y and
							   wall.bottom.x == floor.right.x then
								connection_e = true
							end
							if wall.top.y <= floor.left.y and
							   wall.bottom.y > floor.left.y and
							   wall.top.x == floor.left.x then
								connection_w = true
							end
						else
							if wall.top.y <= floor.right.y and
							   wall.bottom.y > floor.right.y and
							   wall.top.x == floor.right.x then
								connection_e = true
							end
							if wall.top.y < floor.left.y and
							   wall.bottom.y >= floor.left.y and
							   wall.bottom.x == floor.left.x then
								connection_w = true
							end
						end
					end
					if not connection_w then
						print("world validation: no connection to left of " .. scene .. ".floor[" .. i .. "]")
						floor.mark = "err"
					end
					if not connection_e then
						print("world validation: no connection to right of " .. scene .. ".floor[" .. i .. "]")
						floor.mark = "err"
					end
				end
			end
			-- TODO: check transitions and enemy placements
		end
	end
end
