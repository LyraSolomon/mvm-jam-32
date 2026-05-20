require("player")
require("engine.collision")
require("engine.world")

function _config()
	return { name = "Game", game_id = "com.usagiengine.YOURGAMENAME", pixel_perfect = true }
end

for i = 0, 10 do
	block = {
		aabb = {
			x = i * 10,
			y = 50,
			w = 10,
			h = 10,
		},
	}
	collision.add(block.aabb)
	world.utils.set_tile(block.aabb.x, block.aabb.y, block)
end

function _init()
	State = {}
end

function _update(dt)
	player:update(dt)
end

function _draw(dt)
	gfx.clear(gfx.COLOR_BLACK)
	player:draw()
	world:draw()
end
