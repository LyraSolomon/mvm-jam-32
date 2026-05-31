-- Prototype for a simple ground-based enemy with ranged attack

enemies.turret_tank = enemies:new()

function enemies.turret_tank:new(stats)
	local enemy = {}
	setmetatable(enemy, self)
	self.__index = self
	enemy.stats = stats
	return enemy
end

--[[ example:
	settings = {
		left = 20,
		right = 100,
		y = 150,
		direction = 1,
	},
]]
function enemies.turret_tank:spawn(settings)
	local spawn = {}
	setmetatable(spawn, self)
	self.__index = self
	spawn.settings = settings
	spawn:init()
	spawn.aabb.x = (settings.left + settings.right) / 2
	spawn.aabb.y = settings.y
	spawn.state.direction = settings.direction
	spawn.state.turn_timer = 0
	if settings.direction == 1 then
		spawn.state.turn_timer = 0
	elseif settings.direction == 3 then
		spawn.state.turn_timer = self.stats.turn_time
	end
	return spawn
end

function enemies.turret_tank:check_hit()
	-- TODO
end

function enemies:flip()
	return self.state.turn_timer / self.stats.turn_time < 0.5
end

function enemies.turret_tank:state_machine(dt)
	if self.state.aware == 0 then
		-- Idle patrol
		if self.state.direction == 1 then
			-- moving right
			self.aabb.x += self.stats.speed * dt
			self.state.idle_timer += dt
			if self.state.idle_timer > self.stats.idle_loop then
				self.state.idle_timer -= self.stats.idle_loop
			end
			if self.aabb.x >= self.settings.right then
				self.state.direction = 2
			end
		elseif self.state.direction == 2 then
			-- turning left
			self.state.turn_timer += dt
			if self.state.turn_timer >= self.stats.turn_time then
				self.state.direction = 3
				self.state.idle_timer = 0
			end
		elseif self.state.direction == 3 then
			-- moving left
			self.aabb.x -= self.stats.speed * dt
			self.state.idle_timer += dt
			if self.state.idle_timer > self.stats.idle_loop then
				self.state.idle_timer -= self.stats.idle_loop
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
		if self.state.last_detected_direction.x > 0 then
			self.state.direction = 4
			self.state.turn_timer = math.max(self.state.turn_timer - dt, 0)
		elseif self.state.last_detected_direction.x < 0 then
			self.state.direction = 2
			self.state.turn_timer = math.min(self.state.turn_timer + dt, self.stats.turn_time)
		end
	end
	-- attack
	if self.state.aware == 1 then
		self.state.attack_timer = 0
		self.state.current_attack = 1
	end
end

function enemies.turret_tank:state_animation(dt)
	if self.state.aware == 0 then
		if self.state.direction == 2 or self.state.direction == 4 then
			return self.animation.turn, self.state.turn_timer / self.stats.turn_time
		end
	else
		if self.state.aware <= 0.45 then
			return self.animation.alert_turn, self.state.turn_timer / self.stats.turn_time
		else
			return self.animation.alert, self.state.aware
		end
	end
end
