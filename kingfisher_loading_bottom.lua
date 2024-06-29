local s = screen
local min = math.min
local unpack = table.unpack
local insert = table.insert
local match = string.match
local gmatch = string.gmatch

local wasLoaded = false

-- Property "fps" (num)
local fps = 24
-- Property "dataFrames" (num)
local dataFrames = 1

function merge(t1, t2)
	for k, v in ipairs(t2) do
		insert(t1, v)	
	end
end

local EventEmitter = {}
function EventEmitter:new (o)
	o = o or {}
	o.subscribe = self.subscribe
	o.emit = self.emit
	o.eventSubs = o.eventSubs or {}
	return o
end
function EventEmitter:subscribe (event, cb)
	local event = self.eventSubs[event]
	if event ~= nil then
		insert(event, cb)
	end
end
function EventEmitter:emit (event, ...)
	local event = self.eventSubs[event]
	if event ~= nil then
		for k, v in ipairs(event) do
			v(...)	
		end
	end
end

local AnimationManager = {}
function AnimationManager:new(o)
	o = o or {}
	o.frame = 1
	o.ticks = 0
	o.loop = o.loop or false
	o.fps = o.fps or 24
	o.data = o.data or {}
	o.stopped = true
	o.onDone = o.onDone or nil
	o.tick = self.tick
	o.draw = self.draw
	o.reset = self.reset
	o.start = self.start
	o.stop = self.stop
	return o
end

function AnimationManager:start()
	self.stopped = false	
end

function AnimationManager:stop()
	self.stopped = true	
end

function AnimationManager:tick()
	if self.stopped then
		return	
	end
	if self.frame >= #self.data then
		if self.loop then
			self.ticks = 0
			self.frame = 1
			return
		end
		if self.onDone then
			self.onDone()	
		end
	end
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
			local x, y, width, height = unpack(p)
			s.drawRectF(x, y, width, height)
		end
	end
end

function AnimationManager:reset()
	self.frame = 1
	self.ticks = 0
end

function decodeRGB(rgb)
	return { rgb >> 16, rgb >> 8 & ~tonumber('FF00', 16), rgb & ~tonumber('FFFF00', 16) }
end

function decodeRect(rect)
	return { x = rect >> 24, y = (rect >> 16 & ~tonumber('FF00', 16)), width = (rect >> 8 & ~tonumber('FFFF00', 16)), height = rect & ~tonumber('FFFFFF00', 16) }
end

function deserialize(str)
	local ds = {}
	local frames = gmatch(str, "|([^|]+)")
	for f in frames do
		local frame = {}
		for rgb, rects in gmatch(f, "=(%x+)=([^=]*)") do
			local rectArr = {}
			for rect in gmatch(rects, "(%x+),?") do
				local rectD = decodeRect(tonumber(rect, 16))
				insert(rectArr, { tonumber(rectD.x), tonumber(rectD.y), tonumber(rectD.width), tonumber(rectD.height) })
			end
			local rgbD = decodeRGB(tonumber(rgb, 16))
			insert(frame, { rgbD, rectArr })
		end
		insert(ds, frame)
	end
	return ds
end

local dStr = ''
dataFrames = 3
for i=3,3 + dataFrames do
	local data = property.getText("data" .. i)
	dStr = dStr .. data
end
local ds = deserialize(dStr)
fps =12
local a = AnimationManager:new({ data = ds, fps = fps, loop = true })
local function onLoadedChange(loaded)
    if loaded then
        a:stop()
        a:rest()
    else
        a:start()
    end
end
a:start()

local emitter = EventEmitter:new({ eventSubs = { loadChange = {} }})

function onDraw()
    if loaded then
        return
    end
    a:draw()
end

function onTick()
	a:tick()
    loaded = input.getBool(1)
    if loaded ~= wasLoaded then
        emitter:emit("loadChange", loaded)
    end
    wasLoaded = loaded
end