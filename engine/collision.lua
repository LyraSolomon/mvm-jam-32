collision = {}
collision.colliders = {}

collision.debug = false

function collision.draw()
	for _, v in pairs(collision.colliders) do
		gfx.rect(v.x, v.y, v.w, v.h, gfx.COLOR_BLUE)
	end
end

function collision.add(tbl)
	table.insert(collision.colliders, tbl)
end

function collision.get_collider(x, y)
	local collider = nil
	local index = nil
	for i, v in pairs(collision.colliders) do
		if x >= v.x and x <= v.x + v.w and y >= v.y and y <= v.y + v.h then
			collider = v
			index = i
		end
	end
	return index, collider
end

function collision.remove(index)
	table.remove(collision.colliders, index)
end

function collision.move(aabb, dx, dy)
	local normal = { x = 0, y = 0 }
	if aabb.normal ~= nil then
		aabb.normal = normal
	end

	-- move x
	aabb.x = aabb.x + dx

	for _, v in pairs(collision.colliders) do
		if aabb ~= v and collision.aabb_check(aabb, v) then
			if dx > 0 then
				aabb.x = v.x - aabb.w
				normal.x = -1
			elseif dx < 0 then
				aabb.x = v.x + v.w
				normal.x = 1
			end
		end
	end

	-- move y
	aabb.y = aabb.y + dy

	for _, v in pairs(collision.colliders) do
		if aabb ~= v and collision.aabb_check(aabb, v) then
			if dy > 0 then
				aabb.y = v.y - aabb.h
				normal.y = -1
			elseif dy < 0 then
				aabb.y = v.y + v.h
				normal.y = 1
			end
		end
	end

	return normal
end

function collision.aabb_check(a, b)
	return a.x < b.x + b.w and b.x < a.x + a.w and a.y < b.y + b.h and b.y < a.y + a.h
end
