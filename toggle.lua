s = screen
local insert = table.insert
local unpack = table.unpack

local wasPressed = false

-- Can subscribe to these 2 events:
-- mouseDown - fires when mouse is first clicked. cb called with args x, y
-- mouseUp - fires when mouse is released from being clicked. cb called with args x, y
local TouchEmitter = {}
function TouchEmitter:new (o)
	o = o or {}
	o.subscribe = self.subscribe
	o.emit = self.emit
	o.eventSubs = { mouseDown = {}, mouseUp = {} }
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

local Toggle = {}
function Toggle:new (o)
	o = o or {}
	o.x = o.x or 1
	o.y = o.y or 1
	o.value = false
	o.label = o.label or nil
	o.width = o.width or 9
	o.height = o.height or 5
	o.borderColor = o.borderColor or { 84, 84, 84 }
	o.selectedColor = o.selectedColor or { 4, 140, 135 }
	o.buttonColor = o.buttonColor or { 238, 238, 238 }
	o.labelColor = o.labelColor or { 4, 140, 135 }
	o.backColor = o.backColor or { 68, 149, 241 }
	o.draw = self.draw
	o.isClicked = self.isClicked
	o.onClick = self.onClick
	return o
end

function Toggle:isClicked(x, y)
	return x >= self.x and x <= self.x + self.width - 1 and y >= self.y and y <= self.y + self.height - 1
end

function Toggle:onClick()
	return function (x, y)
		if self:isClicked(x, y) then
			self.value = not self.value	
		end	
	end
end

function Toggle:draw()
	-- Draw button border
	if not self.value then
		s.setColor(unpack(self.borderColor))
	else
		s.setColor(unpack(self.selectedColor))
	end
	s.drawRect(self.x, self.y, self.width, self.height)
	-- Fill in background if selected
	if self.value then
		s.setColor(unpack(self.backColor))
		s.drawRectF(self.x, self.y, self.width, self.height)
	end
	-- Draw button square
	if not self.value then
		s.setColor(unpack(self.buttonColor))
		s.drawRectF(self.x + 1, self.y + 1, self.width / 2 - 2, self.height / 2)
	else
		s.setColor(unpack(self.selectedColor))
		s.drawRectF(self.x + self.width / 2, self.y + 1, self.width / 2 - 2, self.height / 2)
	end
	-- Draw label
	if self.label ~= nil then
		s.setColor(unpack(self.labelColor))
		s.drawTextBox(self.x + self.width + 1, self.y, string.len(self.label) * 5, self.height, self.label, -1, 0)
	end
end

e = TouchEmitter:new()
toggle = Toggle:new({ label = "ALTH" })
e:subscribe("mouseDown", toggle:onClick())

function onDraw()
	toggle:draw()
end

function onTick()
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
