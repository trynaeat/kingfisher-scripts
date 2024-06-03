s = screen
local insert = table.insert
local remove = table.remove
local unpack = table.unpack
local max = math.max

local wasPressed = false

local timers = {}

-- Timer to fire based on number of game ticks passing
local Timer = {}
function Timer:new (o)
	o = o or {}
	-- duration is in frames
	o.duration = o.duration or 10
	o.cb = o.cb or nil
	o.idx = 0
	o.tick = self.tick
	o.startTimer = self.startTimer
	return o
end

function Timer:tick()
	self.duration = max(self.duration - 1, 0)
	if self.duration < 1 then
		remove(timers, self.idx)
		for k,v in ipairs(timers) do
			v.idx = k	
		end
		self.cb()
	end
end

function Timer:startTimer()
	insert(timers, self)
	self.idx = #timers
end

-- Can subscribe to these 2 events:
-- mouseDown - fires when mouse is first clicked. cb called with args x, y
-- mouseUp - fires when mouse is released from being clicked. cb called with args x, y
local TouchEmitter = {}
function TouchEmitter:new (o)
	o = o or {}
	o.subscribe = self.subscribe
	o.emit = self.emit
	o.eventSubs = o.eventSubs or { mouseDown = {}, mouseUp = {} }
	return o
end
function TouchEmitter:subscribe (event, cb)
	local event = self.eventSubs[event]
	if event ~= nil then
		insert(event, cb)
	end
end
function TouchEmitter:emit (event, ...)
	local event = self.eventSubs[event]
	if event ~= nil then
		for k, v in ipairs(event) do
			v(...)	
		end
	end
end

-- Button
local Button = {}
function Button:new (o)
	o = o or {}
	o.x = o.x or 1
	o.y = o.y or 1
	o.label = o.label or nil
	o.borderColor = o.borderColor or { 84, 84, 84 }
	o.selectedColor = o.selectedColor or { 4, 140, 135 }
	o.labelColor = o.labelColor or { 4, 140, 135 }
	o.labelSelectedColor = o.labelSelectedColor or { 238, 238, 238 }
	o.selected = false
	o.cb = o.cb or nil
    o.isClicked = self.isClicked
    o.draw = self.draw
    o.onClick = self.onClick
    o.onRelease = self.onRelease
	return o
end

function Button:isClicked(x, y)
	return x >= self.x and x <= self.x + 18 and y >= self.y and y <= self.y + 7
end

function Button:onClick()
	return function(x, y)
		if (self:isClicked(x, y)) then
			self.selected = true
			if self.cb then
				self.cb()	
			end
		end
	end
end

function Button:onRelease()
	return function ()
		self.selected = false	
	end
end

function Button:draw()
	s.setColor(unpack(self.borderColor))
	s.drawRectF(self.x, self.y + 2, 1, 5)
	s.drawRectF(self.x + 1, self.y + 1, 1, 1)
	s.drawRectF(self.x + 2, self.y, 14, 1)
	s.drawRectF(self.x + 16, self.y + 1, 1, 1)
	s.drawRectF(self.x + 17, self.y + 2, 1, 5)
	if self.selected then
		s.setColor(unpack(self.selectedColor))
		s.drawRectF(self.x + 1, self.y + 2, 16, 5)
		s.drawRectF(self.x + 2, self.y + 1, 14, 1)
	end
	if self.label then
		if self.selected then
			s.setColor(unpack(self.labelSelectedColor))
		else
			s.setColor(unpack(self.labelColor))
		end
		s.drawTextBox(self.x, self.y + 2, 18, 5, self.label, 0, 0)
	end
end

function stopPulse ()
	output.setBool(1, false)	
end

-- Flare indicator
local FlareArray = {}
function FlareArray:new(o)
	o = o or {}
	o.x = o.x or 1
	o.y = o.y or 1
	o.rows = o.rows or 3
	o.fullColor = o.fullColor or { 255, 104, 0 }
	o.emptyColor = o.emptyColor or { 127, 52, 0 }
	o.maxCount = o.maxCount or 18
	o.count = o.maxCount
	o.draw = self.draw
	o.fire = self.fire
	return o
end

function FlareArray:draw()
	local columns = self.maxCount / self.rows
	for i = 1,self.rows do
		for j = 1,columns do
			if self.count < self.maxCount - ((i - 1) * columns + (j - 1)) then
				s.setColor(unpack(self.emptyColor))
			else
				s.setColor(unpack(self.fullColor))	
			end
			s.drawRectF(self.x + (j - 1) * 2, self.y + (i - 1) * 2, 1, 1)
		end
	end
end

function FlareArray:fire()
	return function ()
		self.count = max(self.count - 1, 0)
		output.setBool(1, true)
		local t = Timer:new({ cb = stopPulse })
		t:startTimer()
	end
end

-- Event emitters
local e = TouchEmitter:new()
local flareBtn = Button:new({ y = 25, label = "FLR" })
local flareArr = FlareArray:new({ x = 20, y = 26 })
flareBtn.cb = flareArr:fire()

e:subscribe("mouseDown", flareBtn:onClick())
e:subscribe("mouseUp", flareBtn:onRelease())

function onDraw()
	flareBtn:draw()
	flareArr:draw()
end

function onTick()
	-- Tick any timers
	for k,v in ipairs(timers) do
		v:tick()	
	end
	-- Click TouchEmitter handling
	local isPressed = input.getBool(1)
	local mouseX = input.getNumber(3)
	local mouseY = input.getNumber(4)
	if isPressed and not wasPressed then
		e:emit("mouseDown", mouseX, mouseY)
		wasPressed = true
	end
	if not isPressed and wasPressed then
		e:emit("mouseUp", mouseX, mouseY)
		wasPressed = false
	end
end
