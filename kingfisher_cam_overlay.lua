local s = screen
local setColor = s.setColor
local drawRectF = s.drawRectF
local drawRect = s.drawRect
local drawTextBox = s.drawTextBox
local unpack = table.unpack
local insert = table.insert

local camMode = false
local totalCams = 3
local wasPressed = false
local activeCam = 1

local cams = { "BOW", "STERN", "HULL" }
local label = cams[1]

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
	return x >= self.x and x <= self.x + 8 and y >= self.y and y <= self.y + 7
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
	setColor(unpack(self.borderColor))
	drawRect(self.x, self.y, 8, 7)
	if self.selected then
		setColor(unpack(self.selectedColor))
		drawRectF(self.x + 1, self.y + 1, 7, 6)
	end
	if self.label then
		if self.selected then
			setColor(unpack(self.labelSelectedColor))
		else
			setColor(unpack(self.labelColor))
		end
		drawTextBox(self.x, self.y + 1, 9, 5, self.label, 0, 0)
	end
end

local function drawLabel()
	setColor(238, 238, 238)
	drawTextBox(1, 1, 64, 9, label, 0, 0)
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

local function onNext ()
	activeCam = activeCam + 1
	if activeCam > totalCams then
		activeCam = 1	
	end
	label = cams[activeCam]
end

local function onPrev ()
	activeCam = activeCam - 1
	if activeCam < 1 then
		activeCam = totalCams	
	end
	label = cams[activeCam]
end

local e = TouchEmitter:new()
local nextBtn = Button:new({ x = 54, y = 2, label = ">" })
local prevBtn = Button:new({ y = 2, label = "<" })
nextBtn.cb = onNext
prevBtn.cb = onPrev
e:subscribe("mouseDown", nextBtn:onClick())
e:subscribe("mouseUp", nextBtn:onRelease())
e:subscribe("mouseDown", prevBtn:onClick())
e:subscribe("mouseUp", prevBtn:onRelease())
function onTick()
	-- Input 5 tells us if we're in cam mode
	camMode = input.getBool(5)
	-- Output current cam
	output.setNumber(1, activeCam)
	if not camMode then return end
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

function onDraw()
	if not camMode then return end
	nextBtn:draw()
	prevBtn:draw()
	drawLabel()
end