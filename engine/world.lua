--[[
world = {}
world.tiles = {}
world.utils = {}
world.cell_size = 10
]]

-- walls must be at least player height and floors at least player width
-- otherwise they can get stuck inside the player

-- TODO add map validator
world = {
	initial = {
		walls = {
			{ bottom = { x = 1, y = 180 }, top = { x = 1, y = 0 }},
			{ bottom = { x = 320, y = 180 }, top = { x = 320, y = 0 }},
		},
		floors = {
			{ left = { x = 0, y = 179 }, right = { x = 320, y = 179 }},
			{ left = { x = 100, y = 100 }, right = { x = 200, y = 100 }},
			{ left = { x = 0, y = 0 }, right = { x = 320, y = 0 }},
		},
		transitions = {
			{ x1 = 300, x2 = 320, y1 = 0, y2 = 180, target = { room = "room_2", x = 21 }},
		}
	},
	room_2 = {
		walls = {
			{ bottom = { x = 1, y = 180 }, top = { x = 1, y = 0 }},
			{ bottom = { x = 320, y = 180 }, top = { x = 320, y = 0 }},
		},
		floors = {
			{ left = { x = 0, y = 179 }, right = { x = 320, y = 179 }},
			{ left = { x = 0, y = 0 }, right = { x = 320, y = 0 }},
		},
		transitions = {
			{ x1 = 0, x2 = 20, y1 = 0, y2 = 180, target = { room = "initial", x = 299 }},
		}
	},
}
current_scene = "initial"

function world:draw()
	for _, transition in pairs(world[current_scene].transitions) do
		gfx.rect_fill(transition.x1, transition.y1, transition.x2 - transition.x1, transition.y2 - transition.y1, gfx.COLOR_DARK_GRAY)
	end
	for _, wall in pairs(world[current_scene].walls) do
		gfx.line(wall.bottom.x, wall.bottom.y, wall.top.x, wall.top.y, gfx.COLOR_DARK_BLUE)
	end
	for _, floor in pairs(world[current_scene].floors) do
		gfx.line(floor.left.x, floor.left.y, floor.right.x, floor.right.y, gfx.COLOR_RED)
	end
end

function world:update_room()
	for _, transition in pairs(world[current_scene].transitions) do
		if player.aabb.x >= transition.x1 and player.aabb.x <= transition.x2 and player.aabb.y >= transition.y1 and player.aabb.y <= transition.y2 then
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

--[[
function world.utils.update_colliders()
	for _, v in pairs(world.tiles) do
		collision.add(v.aabb)
	end
end

function world.utils.to_tile(x, y)
	return vec(util.round(x / world.cell_size) * world.cell_size, util.round(y / world.cell_size) * world.cell_size)
end

function world.utils.set_tile(x, y, tbl)
	local key = x .. "," .. y
	world.tiles[key] = tbl
end

function world.utils.get_tile(x, y)
	local key = x .. "," .. y
	return world.tiles[key]
end

function world:draw()
	for i, v in pairs(world.tiles) do
		gfx.rect_fill(v.aabb.x, v.aabb.y, v.aabb.w, v.aabb.h, gfx.COLOR_DARK_GRAY)
	end
end
]]
