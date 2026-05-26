world = {}
world.tiles = {}
world.utils = {}
world.cell_size = 10

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
