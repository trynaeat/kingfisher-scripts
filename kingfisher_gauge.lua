s = screen

function drawArc (x, y, radius, startAngle, arcAngle, width)
	for i=startAngle, arcAngle + startAngle, 1 do
		for r=radius, radius + width - 1 do
			local pixel = { x = x + r * math.cos(math.rad(i)), y = y - r * math.sin(math.rad(i)) }
			s.drawRect(pixel.x, pixel.y, 1, 1)
		end
	end
end

local Gauge = {}
function Gauge:new (o)
	o = o or {}
	self.__index = self
	
	o.backColor = o.backColor or { 151, 151, 151 }
	o.foreColor = o.foreColor or { 38, 192, 189 }
	o.x = o.x or 0
	o.y = o.y or 0
	o.radius = o.radius or 16
	o.width = o.width or 4
	o.startAngle = o.startAngle or -32
	o.arcAngle = o.arcAngle or 244
	o.value = 0
	o.label = o.label or nil
	o.showNum = true
	
	o.draw = self.draw
	o.setValue = self.setValue
	return o
end

function Gauge:draw ()
	screen.setColor(table.unpack(self.backColor))
	-- Draw background
	drawArc(self.x, self.y, self.radius, self.startAngle, self.arcAngle, self.width)
	-- Draw filled in bar based on value
	screen.setColor(table.unpack(self.foreColor))
	local endAngle = self.startAngle + self.arcAngle
	local startAngle = (1 - self.value) * (self.arcAngle) + self.startAngle
	drawArc(self.x, self.y, self.radius, startAngle, endAngle - startAngle, self.width)
	-- Draw label in middle of arc
	if self.label ~= nil then
		screen.drawTextBox(self.x - self.radius + 1, self.y - 2, self.radius * 2, 5, self.label, 0)
	end
	-- Draw numerical value
	if self.showNum then
		screen.setColor(255, 255, 255)
		local formatted = string.format("%0.0f", self.value * 100)
		screen.drawTextBox(self.x - self.radius + 1, self.y + 7, self.radius * 2, 5, formatted, 0)
	end
end

function Gauge:setValue(v)
	self.value = v
end

local wtrGauge = Gauge:new({x = 15, y = 18, radius = 11, label = "WTR"})
local airGauge = Gauge:new({x = 47, y = 18, radius = 11, label = "AIR"})
local pwrGauge = Gauge:new({x = 79, y = 18, radius = 11, label = "PWR"})
wtrGauge:setValue(0.759)
airGauge:setValue(0.3)
pwrGauge:setValue(0.1)

function onDraw ()
	wtrGauge:draw()
	airGauge:draw()
	pwrGauge:draw()
end