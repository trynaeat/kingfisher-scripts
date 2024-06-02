-- Inputs:
-- 1: touchscreen press (bool)
-- 2: altH on (bool)
-- 3: stab on (bool)
-- 4: ap on (bool)
-- 3: touchscreen x (num)
-- 4: touchscreen y (num)

-- Outputs:
-- 1: AltH (bool)
-- 2: STB (bool)
-- 3: A/P (bool)

s = screen
local insert = table.insert
local unpack = table.unpack

local wasPressed = false

local tickLimit = 35

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
	o.cb = o.cb or nil
	o.onChange = o.onChange or nil
	o.draw = self.draw
	o.isClicked = self.isClicked
	o.onClick = self.onClick
	o.setValue = self.setValue
	return o
end

function Toggle:isClicked(x, y)
	return x >= self.x and x <= self.x + self.width - 1 and y >= self.y and y <= self.y + self.height - 1
end

function Toggle:onClick()
	return function (x, y)
		if self:isClicked(x, y) then
			self.value = not self.value	
			if self.cb then
				self.cb()	
			end
		end	
	end
end

function Toggle:setValue()
	return function (v)
		self.value = v
		if self.onChange then
			self.onChange(self.value)	
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
		s.drawRectF(self.x + 1, self.y + 1, self.width - 1, self.height - 1)
	end
	-- Draw button square
	if not self.value then
		s.setColor(unpack(self.buttonColor))
		s.drawRectF(self.x + 2, self.y + 2, self.width / 2 - 2, self.height / 2)
	else
		s.setColor(unpack(self.selectedColor))
		s.drawRectF(self.x + self.width / 2, self.y + 2, self.width / 2 - 1, self.height / 2)
	end
	-- Draw label
	if self.label ~= nil then
		s.setColor(unpack(self.labelColor))
		s.drawTextBox(self.x + self.width + 2, self.y, string.len(self.label) * 5, self.height, self.label, -1, 0)
	end
end

function setAltH (btn)
	return function ()
		output.setBool(1, btn.value)
	end
end

function setStb (btn)
	return function ()
		output.setBool(2, btn.value)	
	end
end

function setAP (btn)
	return function ()
		output.setBool(3, btn.value)	
	end
end

-- Event emitters
local e = TouchEmitter:new()
local apInput = TouchEmitter:new({ eventSubs = { alt = {}, stb = {}, ap = {} } })

-- We 2-way data-bind the buttons by:
-- sub to click events and change state/outputs
-- sub to events from the AP controller and change state output as well
-- cb - callback when clicked
-- onChange - callback when state change is driven by input from AP controller
local altToggle = Toggle:new({ label = "ALTH", y = 2})
altToggle.cb = setAltH(altToggle)
altToggle.onChange = setAltH(altToggle)
local stbToggle = Toggle:new({ label = "STB", y = 9 })
stbToggle.cb = setStb(stbToggle)
stbToggle.onChange = setStb(stbToggle)
local apToggle = Toggle:new({ label = "A/P", y = 16 })
apToggle.cb = setAP(apToggle)
apToggle.onChange = setAP(apToggle)

e:subscribe("mouseDown", altToggle:onClick())
apInput:subscribe("alt", altToggle:setValue())
e:subscribe("mouseDown", stbToggle:onClick())
apInput:subscribe("stb", stbToggle:setValue())
e:subscribe("mouseDown", apToggle:onClick())
apInput:subscribe("ap", apToggle:setValue())

function onDraw()
	altToggle:draw()
	stbToggle:draw()
	apToggle:draw()
end

local altTickCount = 0
local stbTickCount = 0
local apTickCount = 0
function onTick()
	-- Emit events when the input autopilot composite values change
	-- (i.e. autopilot turns itself off because user changed pitch etc)
	local inputAltH = input.getBool(2)
	if altToggle.value ~= inputAltH then
		altTickCount = altTickCount + 1
		if altTickCount > tickLimit then
			apInput:emit("alt", inputAltH)
			altTickCount = 0
		end
		return
	end
	local inputStb = input.getBool(3)
	if stbToggle.value ~= inputStb then
		stbTickCount = stbTickCount + 1
		if stbTickCount > tickLimit then
			apInput:emit("stb", inputStb)
			stbTickCount = 0
		end
		return
	end
	local inputAP = input.getBool(4)
	if apToggle.value ~= inputAP then
		apTickCount = apTickCount + 1
		if apTickCount > tickLimit then
			apInput:emit("ap", inputAP)
			apTickCount = 0	
		end
		return
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
