local s = screen
local setColor = s.setColor
local drawRectF = s.drawRectF
local drawRect = s.drawRect
local drawTextBox = s.drawTextBox
local unpack = table.unpack
local insert = table.insert

local camMode = false
local ldgMode = false
local totalCams = 3
local wasPressed = false
local activeCam = 1

local wasCam = false
local wasLdg = false

local cams = { "BOW", "STERN", "HULL" }
local ldgCams = { "LDG1", "LDG2", "LDG3" }
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
	o.sideLabel = o.sideLabel or nil
	o.selected = false
	o.cb = o.cb or nil
    o.isClicked = self.isClicked
    o.draw = self.draw
    o.onClick = self.onClick
    o.onRelease = self.onRelease
    o.visible = true
	return o
end

function Button:isClicked(x, y)
	return x >= self.x and x <= self.x + 8 and y >= self.y and y <= self.y + 7
end

function Button:onClick()
	return function(x, y)
		if not self.visible then return end
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
		if not self.visible then return end
		self.selected = false	
	end
end

function Button:draw()
	if not self.visible then return end
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
	if self.sideLabel then
		setColor(unpack(self.labelSelectedColor))
		drawTextBox(self.x + 10, self.y, 10, 7, self.sideLabel, 0, 0)
	end
end

local function drawLabel()
	setColor(238, 238, 238)
	drawTextBox(1, 1, 64, 9, label, 0, 0)
end

-- Can subscribe to these 2 events:
-- mouseDown - fires when mouse is first clicked. cb called with args x, y
-- mouseUp - fires when mouse is released from being clicked. cb called with args x, y
local EventEmitter = {}
function EventEmitter:new (o)
	o = o or {}
	o.subscribe = self.subscribe
	o.emit = self.emit
	o.eventSubs = o.eventSubs or { mouseDown = {}, mouseUp = {} }
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

local function onNext ()
	activeCam = activeCam + 1
	if activeCam > totalCams then
		activeCam = 1	
	end
	if ldgMode then
		label = ldgCams[activeCam]	
	else
		label = cams[activeCam]
	end
end

local function onPrev ()
	activeCam = activeCam - 1
	if activeCam < 1 then
		activeCam = totalCams	
	end
	if ldgMode then
		label = ldgCams[activeCam]	
	else
		label = cams[activeCam]
	end
end

--  mode 0 == nothing (we're not displaying)
--  mode 1 == cam
--  mode 2 == ldg
local function onModeChange (mode)
	activeCam = 1
	if mode == 1 then
		label = cams[activeCam]
	elseif mode == 2 then
		label = ldgCams[activeCam]
	end
end

local e = EventEmitter:new()
local modeChange = EventEmitter:new({ eventSubs = { mode = {}}})
local nextBtn = Button:new({ x = 54, y = 2, label = ">" })
local prevBtn = Button:new({ y = 2, label = "<" })
nextBtn.cb = onNext
prevBtn.cb = onPrev
e:subscribe("mouseDown", nextBtn:onClick())
e:subscribe("mouseUp", nextBtn:onRelease())
e:subscribe("mouseDown", prevBtn:onClick())
e:subscribe("mouseUp", prevBtn:onRelease())

local release1Btn = Button:new({ y = 15, label = ">", sideLabel = "R1" })
local release2Btn = Button:new({ y = 25, label = ">", sideLabel = "R2" })
local release3Btn = Button:new({ y = 35, label = ">", sideLabel = "R3" })
e:subscribe("mouseDown", release1Btn:onClick())
e:subscribe("mouseDown", release2Btn:onClick())
e:subscribe("mouseDown", release3Btn:onClick())
e:subscribe("mouseUp", release1Btn:onRelease())
e:subscribe("mouseUp", release2Btn:onRelease())
e:subscribe("mouseUp", release3Btn:onRelease())
modeChange:subscribe("mode", onModeChange)

function onTick()
	-- Input 5 tells us if we're in cam mode
	camMode = input.getBool(5)
	-- Input 6 tells us if we're in loading mode
	ldgMode = input.getBool(6)
	if camMode ~= wasCam or ldgMode ~= wasLdg then
		if not camMode and not ldgMode then
			modeChange:emit("mode", 0)	
		end
		if camMode then
			modeChange:emit("mode", 1)	
		end
		if ldgMode then
			modeChange:emit("mode", 2)	
		end
	end
	wasCam = camMode
	wasLdg = ldgMode
	if ldgMode then
		release1Btn.visible = true
		release2Btn.visible = true
		release3Btn.visible = true
	else
		release1Btn.visible = false
		release2Btn.visible = false
		release3Btn.visible = false
	end
	-- Output current cam
	if camMode then
		output.setNumber(1, activeCam)
	elseif ldgMode then
		output.setNumber(1, activeCam + 3)	
	end
	-- Ouptut current release
	output.setBool(1, release1Btn.selected)
	output.setBool(2, release2Btn.selected)
	output.setBool(3, release3Btn.selected)
	if not (camMode or ldgMode) then return end
	if camMode then
		totalCams = #cams	
	elseif ldgMode then
		totalCams = #ldgCams
	end
	-- Click EventEmitter handling
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
	if not (camMode or ldgMode) then return end
	nextBtn:draw()
	prevBtn:draw()
	release1Btn:draw()
	release2Btn:draw()
	release3Btn:draw()
	drawLabel()
end