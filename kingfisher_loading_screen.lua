s = screen
local drawRectF = s.drawRectF
local setColor = s.setColor
local unpack = table.unpack
local insert = table.insert

local pwr = 0
local maxPower = 28000
local oldMode = 0
local done = false
local animDone = false

-- EventEmitter
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

-- FadeIn
local FadeIn = {}
function FadeIn:new(o)
	o.target = o.target
	-- In game ticks
	o.duration = 120
	o.ticks = 0
	o.stopped = true
	o.tick = self.tick
	o.start = self.start
	o.reset = self.reset
	return o
end

function FadeIn:tick()
	if self.stopped then
		return
	end
	self.ticks = self.ticks + 1
	self.target.opacity = (self.ticks / self.duration) * 255
	if self.ticks >= self.duration then
		self.stopped = true
		if self.cb then
			self.cb()	
		end
	end
end

function FadeIn:start()
	self.stopped = false
end

function FadeIn:reset()
	self.ticks = 0
end

-- BlinkAnim
local BlinkAnim = {}
function BlinkAnim:new(o)
	o.target = o.target
	o.count = o.count or 7
	-- In game ticks
	o.duration = o.duration
	o.currCount = 0
	o.ticks = 0
	o.stopped = true
	o.tick = self.tick
	o.start = self.start
	o.reset = self.reset
	return o
end
function BlinkAnim:tick()
	if self.stopped then
		return
	end
	self.ticks = self.ticks + 1
	if self.ticks >= self.duration then
		self.currCount = self.currCount + 1
		self.ticks = 0
		self.flipped = false
		self.target.visible = not self.target.visible
	end
	if self.currCount >= self.count then
		self.stopped = true
		if self.cb then
			self.cb()	
		end
	end
end
function BlinkAnim:start()
	self.stopped = false
end
function BlinkAnim:reset()
	self.currCount = 0
	self.ticks = 0
	self.flipped = false
end

-- LoadingBar
local LoadingBar = {}
function LoadingBar:new(o)
	o = o or {}
	o.x = o.x or 1
	o.y = o.y or 1
	o.color = o.color or { 4, 140, 135 }
	o.width = o.width or 96
	o.height = o.height or 1
	o.value = 0
	o.draw = self.draw
	return o
end
function LoadingBar:draw()
	setColor(unpack(self.color))
	drawRectF(self.x, self.y, self.width * self.value, self.height)
end

local Logo = {}
function Logo:new()
	o = {}
	o.visible = false
	o.draw = self.draw
	return o
end
function Logo:draw()
	if not self.visible then
		return
	end
	p={{4,140,135,255,47,2,1,1,46,3,3,1,45,4,5,1,44,5,7,1,43,6,4,1,48,6,4,1,42,7,4,1,49,7,4,1,41,8,5,1,49,8,5,1,40,9,6,1,49,9,6,1,39,10,7,1,49,10,7,1,38,11,4,1,43,11,3,1,49,11,3,1,53,11,4,1,37,12,4,1,44,12,2,2,49,12,2,2,54,12,4,1,37,13,3,1,55,13,3,1,37,14,2,1,44,14,3,1,48,14,3,1,56,14,2,1,37,15,1,2,45,15,5,2,57,15,1,2,46,17,3,2,47,19,1,2},{250,102,0,255,47,6,1,9},} for i=1,#p do setColor(p[i][1],p[i][2],p[i][3],p[i][4]) for w=5,#p[i],4 do drawRectF(p[i][w],p[i][w+1]+0.5,p[i][w+2],p[i][w+3]) end end
end

local Text = {}
function Text:new()
	o = {}
	o.opacity = 0
	o.draw = self.draw
	return o
end
function Text:draw()
	p={{250,102,0,255,19,23,1,5,22,23,1,1,25,23,1,1,30,23,1,5,33,23,1,2,37,23,1,1,42,23,1,5,48,23,1,1,54,23,1,1,59,23,1,5,62,23,1,2,65,23,1,5,71,23,1,5,21,24,1,1,26,24,1,3,36,24,1,4,49,24,1,3,53,24,1,1,74,24,1,1,38,25,1,1,54,25,1,1,21,26,1,1,33,26,1,2,39,26,1,1,55,26,2,1,62,26,1,2,74,26,1,2,22,27,1,1,25,27,1,1,48,27,1,1,53,27,1,1,19,29,57,1},{4,140,135,255,20,23,1,2,23,23,1,1,26,23,3,1,31,23,1,1,34,23,1,2,38,23,3,1,43,23,4,1,49,23,3,1,55,23,3,1,60,23,1,2,63,23,1,2,66,23,4,1,72,23,3,1,22,24,1,1,27,24,1,3,31,24,2,1,37,24,1,3,43,24,1,1,50,24,1,3,54,24,1,1,66,24,1,1,72,24,1,1,75,24,1,1,20,25,2,1,31,25,1,3,33,25,2,1,39,25,2,1,43,25,3,1,55,25,2,1,60,25,4,1,66,25,4,1,72,25,3,1,20,26,1,2,22,26,1,1,34,26,1,2,40,26,1,1,43,26,1,2,57,26,1,1,60,26,1,2,63,26,1,2,66,26,1,1,72,26,1,2,75,26,1,2,23,27,1,1,26,27,3,1,37,27,4,1,49,27,3,1,54,27,3,1,66,27,4,1},} for i=1,#p do setColor(p[i][1],p[i][2],p[i][3],self.opacity) for w=5,#p[i],4 do drawRectF(p[i][w],p[i][w+1]+0.5,p[i][w+2],p[i][w+3]) end end
end

local logo = Logo:new()
local text = Text:new()
local loader = LoadingBar:new({ y = 31 })
local onBlinkDone = function()
	animDone = true	
end
local anim = BlinkAnim:new({ target = logo, duration = 6, cb = onBlinkDone })
local onFadeInDone = function()
	anim:start()
end
local fadeIn = FadeIn:new({ target = text, cb = onFadeInDone })
function onDraw()
	if done then
		return
	end
    text:draw()
	logo:draw()
	loader:draw()
end

local e = EventEmitter:new({ eventSubs = { modeChange = {} } })
local function onModeChange(mode)
	if mode == 1 then
		animDone = false
		logo.visible = false
		text.opacity = 0
		done = false
		anim:reset()
		fadeIn:reset()
		fadeIn:start()
	end
end
e:subscribe("modeChange", onModeChange)
function onTick()
	anim:tick()
	fadeIn:tick()
	pwr = input.getNumber(9)
	loader.value = math.min(1, pwr / (maxPower / 2))
	if loader.value >= 1 and animDone then
		done = true	
	end
	
	local mode = input.getNumber(5)
	if mode ~= oldMode then
		e:emit("modeChange", mode)
		oldMode = mode
	end
	
	output.setBool(1, done)
end
