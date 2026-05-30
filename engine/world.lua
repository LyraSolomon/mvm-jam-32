-- walls must be at least player height and floors at least player width
-- otherwise they can get stuck inside the player
-- TODO add map validator
world = usagi.read_json("map.json")
current_scene = "initial"

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
	for _, wall in pairs(world[current_scene].walls) do
		gfx.line(wall.bottom.x, wall.bottom.y, wall.top.x, wall.top.y, gfx.COLOR_DARK_BLUE)
	end
	for _, floor in pairs(world[current_scene].floors) do
		gfx.line(floor.left.x, floor.left.y, floor.right.x, floor.right.y, gfx.COLOR_RED)
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
	for scene, room in pairs(world) do
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
