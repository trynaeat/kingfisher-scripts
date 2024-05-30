local GradiantBar = {}
function GradiantBar:new(o)
    o = o or {}
    o.x = o.x or 0
    o.y = o.y or 0
    o.value = o.value or 0
    o.height = o.height or 23
    o.width = o.width or 10
    -- Bar to show nominal 100% level
    o.barWidth = o.barWidth or 12
    o.infoColor = o.infoColor or { 4, 140, 135 }
    o.warnColor = o.warnColor or { 255, 181, 2 }
    o.dangerColor = o.dangerColor or { 169, 30, 30 }
    o.whiteColor = o.whiteColor or { 238, 238, 238 }
    o.backColor = o.backColor or { 84, 84, 84 }
    -- 0 to 1
    o.threshold = o.threshold or 0.75
    o.showValue = o.showValue or true
    o.label = o.label or nil
    -- Custom numerical value under bar
    o.customValue = o.customValue or nil


	o.draw = self.draw
	o.setValue = self.setValue
	o.setCustomValue = self.setCustomValue
    return o
end

function GradiantBar:setValue(v)
	self.value = v
end

function GradiantBar:setCustomValue(v)
	self.customValue = v
end

function GradiantBar:draw()
	-- Draw background gray
	screen.setColor(table.unpack(self.backColor))
	screen.drawRectF(self.x, self.y - self.height, self.width, self.height)
	-- Draw nominal (blue/green usually) bar
	local nominalHeight = math.floor(math.min(self.threshold * self.height, self.value * self.height))
	local topNom = self.y - nominalHeight
	screen.setColor(table.unpack(self.infoColor))
	screen.drawRectF(self.x, topNom, self.width, nominalHeight)
	-- Draw nominal line
	screen.setColor(table.unpack(self.whiteColor))
	screen.drawRectF(self.x - (self.barWidth - self.width) / 2, self.y - math.floor(self.threshold * self.height), self.barWidth, 1)
	-- Draw warning/danger gradiant
	local warningHeightMax = math.floor((1 - self.threshold) * self.height)
	local warningHeight = math.ceil((self.value - self.threshold) * self.height)
	
	local rSlope = (self.dangerColor[1] - self.warnColor[1]) / warningHeightMax
	local gSlope = (self.dangerColor[2] - self.warnColor[2]) / warningHeightMax
	local bSlope = (self.dangerColor[3] - self.warnColor[3]) / warningHeightMax
	for i = 1, warningHeight do
		screen.setColor(self.warnColor[1] + (rSlope * (i - 1)), self.warnColor[2] + (gSlope * (i - 1)), self.warnColor[3] + (bSlope * (i - 1)))
		screen.drawRectF(self.x, topNom - i, self.width, 1)
	end
	-- Draw value under bar
	screen.setColor(table.unpack(self.whiteColor))
	local formatted = ""
	if self.customValue ~= nil then
		formatted = string.format("%0.0f", self.customValue)
	else
		formatted = string.format("%0.0f", self.value * 100)
	end
	screen.drawTextBox(self.x - (15 - self.width / 2), self.y + 2, 30, 5, formatted, 0)
	if self.label ~= nil then
		-- Draw label
		screen.setColor(table.unpack(self.infoColor))
		screen.drawTextBox(self.x - 6, self.y - self.height + 3, 5, self.height, self.label)
	end
end

b1Bar = GradiantBar:new({ x = 10, y = 24, threshold = 0.66, label = "B1" })
b2Bar = GradiantBar:new({ x = 34, y = 24, threshold = 0.66, label = "B2"})
crBar = GradiantBar:new({ x = 58, y = 24, threshold = 0.66, label = "CR"})
rpsBar = GradiantBar:new({ x = 82, y = 24, threshold = 0.66, label = "RPS"})
b1Bar:setValue(1.0)
b1Bar:setCustomValue(300)
b2Bar:setValue(0.66)
crBar:setValue(0.4)
rpsBar:setValue(0.85)
function onDraw ()
	b1Bar:draw()
	b2Bar:draw()
	crBar:draw()
	rpsBar:draw()
end