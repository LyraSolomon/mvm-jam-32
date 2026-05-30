enemies = {}
--[[ example:
	state = {
		aware = 0,
		direction = 1,
		turn_timer = 0, TODO
		last_detected_direction = 0,
		attack_timer = 0,
		current_attack = nil,
		hp = 0,
		idle_timer = 0,
		death_timer = 0,
	},
	movement = {
		w = 16,
		h = 12,
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
	},
]]
function enemies:create(movement)
	local enemy = {}
	setmetatable(enemy, self)
	self.__index = self
	enemy.movement = movement
	return enemy
end

function enemies:init()
	self.aabb = {}
	self.aabb.w = self.movement.w
	self.aabb.h = self.movement.h
	self.state = {}
	self.state.aware = 0
	self.state.death_timer = 0
	self.state.idle_timer = 0
	self.state.hp = self.movement.max_hp
	self.state.turn_timer = 0
end

function enemies:inflict(damage)
	self.state.hp -= damage
end

function enemies:check_hit()
	-- override this
end

function enemies:state_machine(dt)
	-- override this
end

function enemies:state_animation(dt)
	-- override this
end

function enemies:update(dt)
	if self.state.hp <= 0 then
		self.state.death_timer += dt
		return
	end
	if self.state.current_attack ~= nil then
		local attack = self.movement.attacks[self.state.current_attack]
		if self.state.attack_timer < attack.windup and self.state.attack_timer + dt >= attack.windup then
			self.check_hit()
		end
		self.state.attack_timer += dt
		if self.state.attack_timer > attack.windup + attack.recovery then
			self.state.current_attack = nil
		end
	end
	if self.state.current_attack == nil then
		-- Update awareness meter
		if dist_test(self.aabb, player.aabb, self.movement.detect_radius) then
			if self.movement.xray or collision.lineofsight(world[current_scene], self.aabb, player.aabb) then
				self.state.last_detected_direction = 0 -- TODO
				if self.aabb.x < player.aabb.x then
					self.state.last_detected_direction = 1
					self.state.direction = 4
				elseif self.aabb.x > player.aabb.x then
					self.state.last_detected_direction = -1
					self.state.direction = 2
				end
				self.state.aware = math.min(self.state.aware + dt / self.movement.detect_time, 1)
			else
				self.state.aware = math.max(self.state.aware - dt / self.movement.forget_time, 0)
			end
		elseif
			(not dist_test(self.aabb, player.aabb, self.movement.forget_radius)) or
			(not (self.movement.xray or collision.lineofsight(world[current_scene], self.aabb, player.aabb))) then
			self.state.aware = math.max(self.state.aware - dt / self.movement.forget_time, 0)
		end
		self:state_machine(dt)
	end
end

function enemies:draw()
	self.animation = animations.enemies["monitor"]
	local animation = self.animation.idle
	local animation_time = self.state.idle_timer / self.movement.idle_loop
	local alpha = 1
	if self.state.hp <= 0 then
		animation = self.animation.death
		animation_time = self.state.death_timer / self.movement.death_time
		alpha = 1 - (self.state.death_timer - self.movement.death_time) / self.movement.fade_time
	elseif self.state.current_attack ~= nil then
		local attack = self.movement.attacks[self.state.current_attack]
		if self.state.attack_timer < attack.windup then
			animation = self.animation.attacks[self.state.current_attack].windup
			animation_time = self.state.attack_timer / attack.windup
		else
			animation = self.animation.attacks[self.state.current_attack].recovery
			animation_time = (self.state.attack_timer - attack.windup) / attack.recovery
		end
	else
		animation, animation_time = self:state_animation()
		if animation == nil then
			animation = self.animation.idle
			animation_time = self.state.idle_timer / self.movement.idle_loop
		end
	end
	gfx.spr_ex(
		spritepage["monitor"] + animation_frame(animation, animation_time),
		self.aabb.x - self.aabb.w / 2,
		self.aabb.y - self.aabb.h - self.movement.y_pad,
		self.state.turn_timer < 0.5,
		false,
		0,
		gfx.COLOR_TRUE_WHITE,
		alpha
	)
end

function dist_test(aabb1, aabb2, r)
	local dx = math.max(math.abs(aabb1.x - aabb2.x) - (aabb1.w + aabb2.w) / 2, 0)
	local dy = 0
	if aabb1.y > aabb2.y then
		dy = math.max(aabb1.y - aabb2.y - aabb1.h, 0)
	else
		dy = math.max(aabb2.y - aabb1.y - aabb2.h, 0)
	end
	return dx*dx+dy*dy < r*r
end

function animation_frame(animation, time)
	for _, frame in pairs(animation) do
		if time < frame.end_at or frame.end_at == 1 then
			return frame.frame
		end
	end
end
