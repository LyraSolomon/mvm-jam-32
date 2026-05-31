require("engine.vector")
require("engine.physics")

player = {
	movement = {
		speed = 300,
		accel = 1500,
		fall = 400,
		slide = 150,
		grav = 900,
		jump_height = 50,
		jump_boost_height = 100,
		jump_boost_time = 0.3,
		coyote_time = 0.2,
		--air_jumps = 1, -- TODO separate jump_boost info for each?
		-- TODO wall jumps / climb ?
		friction = {
			air = {
				x = { 0.4, 0.6 },
				y = { 0.2, 0.8 }
			},
			ground = {
				x = { 0.8, 0.2 },
				y = { 1, 0 }
			},
			wall = {
				x = { 1, 0 },
				y = { 0.6, 0.4 }
			},
			ceiling = {
				x = { 0.7, 0.3 },
				y = { 1, 0 }
			},
		},
		brake = 0.4,
		air_control = 0.3,
	},
	state = {
		jump_start = 0,
		jump_jump_held = 1000,
		coyote_timer = 0,
		--air_jumps_used = 0,
	},
	velocity = vec(0, 0),
	touching = {
		ground = false,
		ceiling = false,
		wall = false,
	},
	aabb = {
		x = 10,
		y = 100,
		w = 10,
		h = 10,
	},
}

function player.boost_ratio(t)
	return t ^ 0.75
end

function player:update(dt)
	self.state.coyote_timer = self.state.coyote_timer + dt
	if self.touching.ground then
		self.state.jump_held = self.movement.jump_boost_time + 1
		self.state.coyote_timer = 0
	end
	if self.touching.ceiling then
		self.state.jump_held = self.movement.jump_boost_time + 1
	end

	local input_dir = vector.utils.input_vector()
	if not (self.touching.ground or self.touching.wall or self.touching.ceiling) then
		input_dir.x *= self.movement.air_control
	elseif input_dir.x == 0 then
		input_dir.x = -self.movement.brake * util.sign(self.velocity.x)
	end
	local input_accel = { x = input_dir.x * self.movement.accel, y = self.movement.grav }
	if input.held(input.BTN1) then
		if self.state.coyote_timer < self.movement.coyote_time then
			self.velocity.y = -physics.jump_velocity(self.movement.jump_height)
			self.state.jump_held = 0
			self.state.coyote_timer = self.movement.coyote_time + 1
			self.state.jump_start = self.aabb.y
		elseif self.state.jump_held < self.movement.jump_boost_time then
			local target_total = self.movement.jump_height + self.movement.jump_boost_height * player.boost_ratio(self.state.jump_held / self.movement.jump_boost_time)
			local height_remaining = target_total + self.aabb.y - self.state.jump_start
			self.velocity.y = -physics.jump_velocity(height_remaining)
			self.state.jump_held = self.state.jump_held + dt
		end
	else
		self.state.jump_held = self.movement.jump_boost_time + 1
	end
	local target = {}
	local friction = self.movement.friction.air
	if self.touching.ground and not input.held(input.BTN1) then
		friction = self.movement.friction.ground
	elseif self.touching.wall then
		friction = self.movement.friction.wall
	elseif self.touching.ceiling then
		friction = self.movement.friction.ceiling
	end
	if self.touching.ground then
		local v_old = self.velocity.x
		self.velocity.x, target.x = physics.step(
			input_accel.x,
			friction.x,
			{ self.movement.accel / self.movement.speed,
			self.movement.accel / self.movement.speed^2 },
			self.velocity.x,
			self.aabb.x,
			dt
		)
		if util.sign(v_old) == -util.sign(self.velocity.x) then
			self.velocity.x = 0
		end
	else
		local v_old = self.velocity.x
		self.velocity.x, target.x = physics.step(
			input_accel.x,
			friction.x,
			{ self.movement.accel * self.movement.air_control / self.movement.speed,
			self.movement.accel * self.movement.air_control / self.movement.speed^2 },
			self.velocity.x,
			self.aabb.x,
			dt
		)
		if util.sign(v_old) == -util.sign(self.velocity.x) then
			self.velocity.x = 0
		end
	end
	if self.touching.wall then
		self.velocity.y, target.y = physics.step(
			input_accel.y,
			friction.y,
			{ self.movement.grav / self.movement.slide,
			self.movement.grav / self.movement.slide^2 },
			self.velocity.y,
			self.aabb.y,
			dt
		)
	else
		self.velocity.y, target.y = physics.step(
			input_accel.y,
			friction.y,
			{ self.movement.grav / self.movement.fall,
			self.movement.grav / self.movement.fall^2 },
			self.velocity.y,
			self.aabb.y,
			dt
		)
	end
	player:move_to(target)

	-- TODO for testing only, remove
	if input.pressed(input.BTN2) then
		for _, enemy in pairs(world[current_scene].active_enemies) do
			enemy:inflict(1)
		end
	end
	if input.pressed(input.BTN3) then
		world:spawn_enemies()
	end
end

function player:move_to(target)
	self.aabb, self.touching = collision.move_to(world[current_scene], self.aabb, target)
	if self.touching.ceiling or self.touching.ground then
		self.velocity.y = 0
	end
	if self.touching.wall then
		self.velocity.x = 0
	end
end

function player:draw()
	gfx.rect_fill(
		player.aabb.x - player.aabb.w / 2,
		player.aabb.y - player.aabb.h,
		player.aabb.w,
		player.aabb.h,
		gfx.COLOR_WHITE
	)
end

