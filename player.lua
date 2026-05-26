require("engine.vector")

player = {
	--speed = 1,
	movement = {
		speed = 2,
		accel = 10,
		fall = 20,
		grav= 9,
		jump_vel = 20 -- TODO calculate this from jump height instead
	},
	velocity = vec(0, 0),
	touching = {
		ground = false,
		ceiling = false,
		wall = false,
	},
	aabb = {
		x = 100,
		y = 100,
		w = 10,
		h = 10,
		--normal = {},
	},
	--pointer = vec(0, 0),
	--looking_at = nil,
}

function player:update(dt)
	local input_dir = vector.utils.input_vector()
	local input_accel = { x = input_dir.x * self.movement.accel, y = self.movement.grav }
	local state_accel = { x = -self.velocity.x * self.movement.accel / self.movement.speed, y = -self.velocity.y * self.movement.grav / self.movement.fall }
	self.velocity.x = self.velocity.x + dt * (input_accel.x + state_accel.x)
	self.velocity.y = self.velocity.y + dt * (input_accel.y + state_accel.y)
	if self.touching.ground and input.held(input.BTN1) then
		self.velocity.y = -self.movement.jump_vel
	end
	player:move_to({x = self.aabb.x + self.velocity.x, y = self.aabb.y + self.velocity.y})
end

function player:move_to(target)
	self.aabb, self.touching = move_to(world[current_scene], self.aabb, target)
	if self.touching.ceiling or self.touching.ground then
		self.velocity.y = 0
	end
	if self.touching.wall then
		self.velocity.x = 0
	end
end

function player:draw()
	gfx.rect_fill(player.aabb.x - player.aabb.w / 2, player.aabb.y - player.aabb.h, player.aabb.w, player.aabb.h, gfx.COLOR_WHITE)
end

--[[
function player:update(dt)
	self:input()
	if self.aabb.normal.y ~= -1 then
		self.velocity.y += 10 * dt
	end

	local targeting = world.utils.get_tile(self.pointer.x, self.pointer.y)
	if targeting ~= nil then
		self.looking_at = targeting
	else
		self.looking_at = nil
	end

	collision.move(self.aabb, self.velocity.x, self.velocity.y)
end

function player:draw()
	gfx.rect_fill(player.aabb.x, player.aabb.y, 10, 10, gfx.COLOR_WHITE)
	gfx.circ(self.pointer.x + (world.cell_size / 2), self.pointer.y + (world.cell_size / 2), 3, gfx.COLOR_WHITE)
end

function player:input()
	local input_dir = vector.utils.input_vector()
	input_dir = util.vec_normalize(vector.utils.input_vector())
	self.velocity.x = input_dir.x * self.speed
	self.pointer = world.utils.to_tile(
		self.aabb.x + (input_dir.x * world.cell_size),
		self.aabb.y + (input_dir.y * world.cell_size)
	)

	if input.pressed(input.BTN1) and self.aabb.normal.y == -1 then
		self.velocity.y = -3
	end

	if input.pressed(input.BTN2) and self.looking_at ~= nil then
		for i, v in pairs(collision.colliders) do
			print(v.x, v.y, v.w, v.h)
		end
		world.utils.set_tile(self.pointer.x, self.pointer.y, nil)
		local index, collider = collision.get_collider(self.pointer.x, self.pointer.y)
		print(index)
	end
end
]]
