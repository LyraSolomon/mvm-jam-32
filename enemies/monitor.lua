-- Prototype for a simple ground-based enemy with ranged attack

enemies.monitor = enemies:create({
	w = 16,
	h = 12,
	speed = 40,
	turn_time = 0.8,
	xray = false,
	detect_radius = 100,
	detect_time = 2,
	forget_radius = 100,
	forget_time = 1.5,
	attacks = {{
		windup = 1,
		recovery = 0.5,
	}},
	max_hp = 5,
	y_pad = 4,
	idle_loop = 1,
	death_time = 1,
	fade_time = 4
})

--[[ example:
	settings = {
		left = 20,
		right = 100,
		y = 150,
		direction = 1,
	},
]]
function enemies.monitor:spawn(settings)
	local spawn = {}
	setmetatable(spawn, self)
	self.__index = self
	spawn.settings = settings
	spawn:init()
	spawn.aabb.x = (settings.left + settings.right) / 2
	spawn.aabb.y = settings.y
	spawn.state.direction = settings.direction
	if settings.direction == 1 then
		spawn.state.turn_timer = 0
	elseif settings.direction == 3 then
		spawn.state.turn_timer = self.movement.turn_time
	end
	return spawn
end

function enemies.monitor:check_hit()
	-- TODO
end

function enemies.monitor:state_machine(dt)
	if self.state.aware == 0 then
		-- Idle patrol
		if self.state.direction == 1 then
			-- moving right
			self.aabb.x += self.movement.speed * dt
			self.state.idle_timer += dt
			if self.state.idle_timer > self.movement.idle_loop then
				self.state.idle_timer -= self.movement.idle_loop
			end
			if self.aabb.x >= self.settings.right then
				self.state.direction = 2
			end
		elseif self.state.direction == 2 then
			-- turning left
			self.state.turn_timer += dt
			if self.state.turn_timer >= self.movement.turn_time then
				self.state.direction = 3
				self.state.idle_timer = 0
			end
		elseif self.state.direction == 3 then
			-- moving left
			self.aabb.x -= self.movement.speed * dt
			self.state.idle_timer += dt
			if self.state.idle_timer > self.movement.idle_loop then
				self.state.idle_timer -= self.movement.idle_loop
			end
			if self.aabb.x <= self.settings.left then
				self.state.direction = 4
			end
		else
			-- turning right
			self.state.turn_timer -= dt
			if self.state.turn_timer <= 0 then
				self.state.direction = 1
				self.state.idle_timer = 0
			end
		end
	else
		self.state.turn_timer = math.max(math.min(self.state.turn_timer - dt * self.state.last_detected_direction, 1), 0)
	end
	-- attack
	if self.state.aware == 1 then
		self.state.attack_timer = 0
		self.state.current_attack = 1
	end
end

function enemies.monitor:state_animation(dt)
	if self.state.aware == 0 then
		if self.state.direction == 1 or self.state.direction == 3 then
			return self.animation.turn, self.state.turn_timer / self.movement.turn_time
		end
	else
		return self.animation.alert, self.state.aware
	end
end
