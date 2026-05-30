require("spritepage")

animations = usagi.read_json("animations.json")
-- TODO validation check

function animation_frame(animation, time)
	for _, frame in pairs(animation) do
		if time < frame.end_at or frame.end_at == 1 then
			return frame.frame
		end
	end
end

