local s = screen
local min = math.min
local unpack = table.unpack
local insert = table.insert
local match = string.match
local gmatch = string.gmatch

function merge(t1, t2)
	for k, v in ipairs(t2) do
		insert(t1, v)	
	end
end

local AnimationManager = {}
function AnimationManager:new(o)
	o = o or {}
	o.frame = 1
	o.ticks = 0
	o.fps = o.fps or 24
	o.data = o.data or {}
	o.tick = self.tick
	o.draw = self.draw
	return o
end

function AnimationManager:tick()
	self.ticks = min(self.ticks + 1, 120000)
	if self.ticks / self.frame >= 60 / self.fps then
		self.frame = min(self.frame + 1, #self.data)
	end
end

function AnimationManager:draw()
	local frame = self.data[self.frame]
	for k,v in pairs(frame) do
		s.setColor(unpack(v[1]))
		for i,p in ipairs(v[2]) do
			local x, y = unpack(p)
			s.drawRectF(x, y, 1, 1)
		end
	end
end

function decodeRGB(rgb)
	return { rgb >> 16, rgb >> 8 & ~tonumber('FF00', 16), rgb & ~tonumber('FFFF00', 16) }
end

function decodePixel(pixel)
	return { x = pixel >> 8, y = (pixel & ~tonumber('FF00', 16)) }
end

function deserialize(str)
	local ds = {}
	local frames = gmatch(str, "|([^|]+)")
	for f in frames do
		local frame = {}
		for rgb, pixels in gmatch(f, "=(%x+)=([^=]*)") do
			local pixelArr = {}
			for pixel in gmatch(pixels, "(%x+),?") do
				local pixelD = decodePixel(tonumber(pixel, 16))
				insert(pixelArr, {tonumber(pixelD.x), tonumber(pixelD.y)})
			end
			local rgbD = decodeRGB(tonumber(rgb, 16))
			insert(frame, { rgbD, pixelArr })
		end
		insert(ds, frame)
	end
	return ds
end

local dStr = ''
local dataCt = 6
for i=1,dataCt do
	local data = property.getText("data" .. i)
	dStr = dStr .. data
end
local ds = deserialize(dStr)
local a = AnimationManager:new({ data = ds, fps = 24 })
function onDraw()
	a:draw()
end

function onTick()
	a:tick()
end