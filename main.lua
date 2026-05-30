require("player")
require("engine.collision")
require("enemies.enemies")
require("enemies.monitor")
require("engine.world")
require("spritepage")

function _config()
	return { name = "Game", game_id = "com.usagiengine.YOURGAMENAME", pixel_perfect = true }
end

animations = usagi.read_json("animations.json")
-- TODO validation check

function _init()
	State = {}
end

function _update(dt)
	world:update_enemies(dt)
	player:update(dt)
	world:update_room()
end

function _draw(dt)
	gfx.clear(gfx.COLOR_BLACK)
	world:draw()
	player:draw()
end
