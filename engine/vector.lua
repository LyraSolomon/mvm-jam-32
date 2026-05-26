vector = {}
vector.utils = {}

function vec(x, y)
	return {
		x = x,
		y = y,
	}
end

function vector.utils.input_vector()
	local vec = { x = 0, y = 0 }
	vec.x = vector.utils.bool_to_int(input.held(input.RIGHT)) - vector.utils.bool_to_int(input.held(input.LEFT))
	vec.y = vector.utils.bool_to_int(input.held(input.DOWN)) - vector.utils.bool_to_int(input.held(input.UP))
	return vec
end

function vector.utils.bool_to_int(b)
	if b == true then
		return 1
	else
		return 0
	end
end
