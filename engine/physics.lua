physics = {}

-- TODO separate this from player data
function physics.max_jump_height(velocity)
	local linear_only = -player.movement.fall/player.movement.grav*(player.movement.fall*math.log(1+velocity/player.movement.fall)-velocity)
	local quad_only = player.movement.fall^2 * math.log(velocity^2/player.movement.fall^2 + 1) / (2*player.movement.grav)
	-- This is actually a very good estimate
	-- (sub-pixel accuracy for typical values)
	return linear_only * player.movement.friction.air.y[1] + quad_only * player.movement.friction.air.y[2]
end

function physics.jump_velocity(height)
	-- Newton's Method
	local guess = 100
	for i = 0, 10 do
		local slope = physics.max_jump_height(guess + 0.5) - physics.max_jump_height(guess - 0.5)
		local err = physics.max_jump_height(guess) - height
		guess = guess - err / slope
	end
	return guess
end

-- a: input acceleration
-- friction_mode: { c1, c2 }, none negative, sum to 1
-- resistance: { a_max / v_max, a_max / v_max^2 }, all strictly positive
function physics.step(a, friction_mode, resistance, v0, x0, t)
	if a < 0 or a == 0 and v0 < 0 then
		local v1, x1 = physics.step_(-a, friction_mode, resistance, -v0, t)
		return -v1, x0 - x1
	else
		local v1, x1 = physics.step_(a, friction_mode, resistance, v0, t)
		return v1, x0 + x1
	end
end

function physics.step_(a, friction_mode, resistance, v0, t)
	local linear = {}
	local quad = {}
	do
		-- linear resistance
		local b = math.max(resistance[1], 1e-9)
		local c = a / b - v0
		local c2 = -c / b
		linear.v1 = a / b - c * math.exp(-b * t)
		linear.x1 = a * t / b + c * math.exp(-b * t) / b + c2
	end
	do
		-- quadratic resistance
		local b = math.max(resistance[2], 1e-9)
		if a == 0 then
			-- special case
			if v0 == 0 then
				quad.v1 = 0
				quad.x1 = 0
			else
				local c = 1/v0
				local c2 = math.log(v0)/b
				quad.v1 = 1 / (b*t+c)
				quad.x1 = math.log(b*t+c)/b + c2
			end
		elseif v0 < 0 then
			-- case 2
			local c = math.atan(v0*math.sqrt(b/a)) / math.sqrt(a*b)
			local c2 = -math.log(v0^2*b/a+1) / (2*b)
			quad.v1 = math.sqrt(a/b) * math.tan(math.sqrt(a*b) * (c + t))
			quad.x1 = -math.log(math.cos(math.sqrt(a*b) * (c + t))) / b + c2
		elseif v0^2 < a / b then
			-- case 1
			local c = atanh(v0*math.sqrt(b/a)) / math.sqrt(a*b)
			local c2 = math.log(1-v0^2*b/a) / (2*b)
			quad.v1 = math.sqrt(a/b) * tanh(math.sqrt(a*b) * (c + t))
			quad.x1 = math.log(cosh(math.sqrt(a*b) * (c + t))) / b + c2
		else
			-- case 3
			local c = acoth(v0*math.sqrt(b/a)) / math.sqrt(a*b)
			local c2 = math.log(v0^2*b/a-1) / (2*b)
			quad.v1 = math.sqrt(a/b) * coth(math.sqrt(a*b) * (c + t))
			quad.x1 = math.log(sinh(math.sqrt(a*b) * (c + t))) / b + c2
		end
	end
	return
		(linear.v1*friction_mode[1]+quad.v1*friction_mode[2]),
		(linear.x1*friction_mode[1]+quad.x1*friction_mode[2])
end

--[[
=== simple drag ===
y'' = g - y' * g / vmax
y'(0) = v
y(t) = c * exp(-(g/vmax)*t) * vmax/g + t*vmax + c2 ## per WolframAlpha
y'(t) = -c * exp(-(g/vmax)*t) + vmax
y'(0) = v = -c + vmax = v
c = vmax - v
y(0) = 0 = (vmax - v) * vmax/g + c2
c2 = (v-vmax)*vmax/g

y'(t) = 0 = (v-vmax) * exp(-(g/vmax)*t) + vmax
t = vmax * ln (1 - v/vmax) / g ## per WolfraphAlpha
y = (vmax-v) * exp(-ln(1-v/vmax)) * vmax/g + vmax^2/g*ln(1-v/vmax) + (v-vmax)*vmax/g
  = (vmax-v) / (1-v/vmax) * vmax/g + vmax^2/g * ln(1-v/vmax) + (v-vmax)*vmax/g
  = vmax^2/g + vmax^2/g * ln(1-v/vmax) + v*vmax/g - vmax^2/g
  = vmax/g * (vmax * ln(1-v/vmax) + v)
note v and y are both negative

per WolframAlpha,
v = vmax * (W(-exp(-y*g/vmax^2-1))+1), where W is the Lambert W / product log function
however, this is incorrect for whatever reason. Newton's Method it is!

--- generic:
y'' = a - b*y'
y'(0) = v
y(0) = 0
y(t) = at/b + c/b*e^-bt + c2 ## per WolframAlpha
y'(t) = a/b - c*e^-bt
c = a/b-v
c2 = -c/b

=== correct equation for drag ===
y'' = g - g * y'|y'| / vmax^2
y(t) = [1: when vmax > y' > 0] ln (cosh (g/vmax * (c + t))) * vmax^2/g + c2 -- sqrt(a*b)
       [2: when        y' < 0] -ln (cos (g/vmax * (c + t))) * vmax^2/g + c2
       [3: when vmax < y'    ] ln (sinh (g/vmax * (c + t))) * vmax^2/g + c2
y'(t) = [1: when vmax > y' > 0] vmax * tanh (g/vmax * (c + t))
        [2: when        y' < 0] vmax * tan (g/vmax * (c + t))
        [3: when vmax < y'    ] vmax * coth (g/vmax * (c + t))
-- case 2
y'(0) = v = vmax * tan (c*g/vmax)
c = vmax/g * atan (v/vmax)
y(0) = 0 = -ln (cos (atan (v/vmax))) * vmax^2/g + c2
c2 = vmax^2/g * ln (isqrt(v^2/vmax^2+1)
   = -vmax^2 * ln (v^2/vmax^2 + 1) / 2*g
y'(t) = 0 = vmax * tan (g/vmax * t + atan (v/vmax))
0 = g/vmax * t + atan (v/vmax)
t = -vmax/g*atan(v/vmax)
y = -ln (cos (atan (v/vmax) - atan(v/vmax))) * vmax^2/g + c2 = c2
  = -vmax^2 * ln (v^2/vmax^2 + 1) / 2*g
-2*g*y / vmax^2 = ln (v^2/vmax^2 + 1)
v = -sqrt (exp (-2*g*y / vmax^2) - 1) * vmax
--- case 1
y'(0) = 0
c = 0
c2 = y(0)
--- generic:
y'' = a - b * y'|y'|
y = [ln.cosh,-ln.cos,ln.sinh] (sqrt(a*b) * (c + t)) / b + c2
y' = sqrt(a/b) * [tanh,tan,coth] (sqrt(a*b) * (c + t))
y'(0) = v = sqrt(a/b) * [tanh,tan,coth] (sqrt(a*b)*c)
c = [atanh,atan,acoth] (v*sqrt(b/a)) / sqrt(a*b)
y(0) = 0 = [ln.cosh.atanh,-ln.cos.atan,ln.sinh.acoth] (v*sqrt(b/a)) / b + c2
 = [1] -log(1-v^2*b/a) / (2*b) + c2
   [2] log(v^2*b/a+1) / (2*b) + c2
   [3] -log(v^2*b/a-1) / (2*b) + c2
when a = 0
y = log(b*t+c)/b + c2
y' = 1/(b*t+c)
y'(0) = v = 1/c
c=1/v
y(0) = 0 = -log(v)/b + c2

=== boosted jumps ===
not even gonna try for an analytic solution on this one
]]

function atanh(x)
	return math.log((1+x)/(1-x))/2
end

function acoth(x)
	return math.log((x+1)/(x-1))/2
end

function tanh(x)
	return sinh(x)/cosh(x)
end

function coth(x)
	return cosh(x)/sinh(x)
end

function cosh(x)
	return (math.exp(x)+math.exp(-x))/2
end

function sinh(x)
	return (math.exp(x)-math.exp(-x))/2
end
