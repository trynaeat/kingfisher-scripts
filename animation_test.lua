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
		s.setColor(unpack(k))
		for i,p in ipairs(v) do
			local x, y = unpack(p)
			s.drawRectF(x, y, 1, 1)
		end
	end
end

function deserialize(str)
	local ds = {}
	local frames = gmatch(str, "{({{%d+,%d+,%d+}={[{%d,%d},?]+},?)}")
	for f in frames do
		local frame = {}
		local colorArrs = gmatch(f, "({%d+,%d+,%d+}={[{%d,%d},?]+}[,}])")
		for w in colorArrs do
			local r, g, b, pixels = match(w, "{(%d+),(%d+),(%d+)}={(%g*)}")
			local pixelArr = {}
			for x, y in gmatch(pixels, "{(%d+),(%d+)},?") do
				insert(pixelArr, {tonumber(x), tonumber(y)})
			end
			frame[{tonumber(r), tonumber(g), tonumber(b)}] = pixelArr
		end
		insert(ds, frame)
	end
	return ds
end

local dStr = ''
local dataCt = 4
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