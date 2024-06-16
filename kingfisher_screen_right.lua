s = screen
local pi = math.pi
local cos = math.cos
local sin = math.sin
local floor = math.floor
local ceil = math.ceil
local min = math.min
local max = math.max
local abs = math.abs
local unpack = table.unpack
local setColor = screen.setColor
local drawRectF = screen.drawRectF
local clear = table.clear

local startAngle = 0
local endAngle = 2 * pi
wtr = 0
air = 0
pwr = 0

maxPressure = 60
maxPower = 28000

local function round (x)
	return floor(x + 0.5)
end

-- Bresenham algo
local function drawLine(buffer, color, x1, y1, x2, y2)
	dx = x2 - x1
    dy = y2 - y1
    d = 2 * dy - dx
    y = y1

    for x = x1,x2 do
        buffer[y][x] = color
        if d > 0 then
            y = y + 1
            d = d - 2 * dx
        end
        d = d + 2 * dy
    end
end

local function floodFill(buffer, boundsX, boundsY, color, x, y)
	if x < boundsX[1] or y < boundsY[1] or x > boundsX[2] or y > boundsY[2] or not buffer[y] or buffer[y][x] then
		return
	end
	buffer[y][x] = color
	floodFill(buffer, boundsX, boundsY, color, x + 1, y)
	floodFill(buffer, boundsX, boundsY, color, x - 1, y)
	floodFill(buffer, boundsX, boundsY, color, x, y + 1)
	floodFill(buffer, boundsX, boundsY, color, x, y - 1)
end

local function drawBuffer(buffer)
	for y,row in pairs(buffer) do
		for x,v in pairs(row) do
			if v then
				setColor(unpack(v))
				drawRectF(x, y, 1, 1)	
			end
		end
	end
end

-- Can check if point lies in one of multiple ranges
local checkRange = function(x, y, ranges)
	for k,range in ipairs(ranges) do
		if x >= range.min and x <= range.max then
			return true
		end
	end
	return false
end

local drawIfInRange = function(x, y, ranges, buffer, color)
	if checkRange(x, y, ranges) then
		buffer[y][x] = color
	end
end

local drawCirclePart = function(xc, yc, r, x, y, startPix, endPix, buffer, color)
	local arcLength = endPix.a - startPix.a
	if arcLength < 0 then
		arcLength = 2 * pi + arcLength	
	end
	local startSweep = startPix.a - arcLength
	
	local xrange
	if startPix.a > endPix.a and endPix.a <= pi then
		xrange = { min = endPix.x, max = xc + r }
	elseif startPix.a > endPix.a then
		xrange = { min = xc - r, max = xc + r }
	elseif endPix.a <= pi then
		xrange = { min = endPix.x, max = startPix.x }
	else
		xrange = { min = xc - r, max = startPix.x }
	end
	local yrange = { min = yc - r, max = yc + r }
	-- Quadrant 1
	if startSweep <= pi then
		drawIfInRange(xc + x, yc - y, { xrange }, buffer, color)
		drawIfInRange(xc + y, yc - x, { xrange }, buffer, color)
	end
	-- Quadrant 2
	if startSweep <= pi then
		drawIfInRange(xc - x, yc - y, { xrange }, buffer, color)
		drawIfInRange(xc - y, yc - x, { xrange }, buffer, color)
	end
	-- Restart range for bottom half
	local xranges = {}
	if startPix.a > endPix.a and startPix.a >= pi and endPix.a > pi then
		xranges = { { min = xc - r, max = endPix.x }, { min = startPix.x, max = xc + r } }
	elseif startPix.a > endPix.a and startPix.a >= pi and endPix.a < pi then
		xranges = { { min = startPix.x, max = xc + r } }
	elseif startPix.a >= pi and endPix.a > pi then
		xranges = { { min = startPix.x, max = endPix.x } }
	elseif startPix.a < pi and endPix.a >= pi then
		xranges = { { min = xc - r, max = endPix.x } }
	else
		xranges = { { min = xc - r, max = xc - r - 1 } }
	end
	-- Quadrant 3
	if startSweep <= 3 * pi / 2 then
		drawIfInRange(xc - x, yc + y, xranges, buffer, color)
		drawIfInRange(xc - y, yc + x, xranges, buffer, color)
	end
	-- Quadrant 4
	if startSweep <= 2 * pi then
		drawIfInRange(xc + x, yc + y, xranges, buffer, color)
		drawIfInRange(xc + y, yc + x, xranges, buffer, color)
	end
end

local drawArc = function (xc, yc, radius, startAngle, endAngle, buffer, color)
	if startAngle < 0 then
		startAngle = 2 * pi + startAngle	
	end
	local startPix = { x = xc + floor(radius * cos(startAngle)), y = yc + floor(radius * sin(startAngle)), a = startAngle }
	local endPix = { x = xc + ceil(radius * cos(endAngle)), y = yc - floor(radius * sin(endAngle)), a = endAngle }
	local x = 0
	local y = radius
	local d = 3 - 2 * radius
	drawCirclePart(xc, yc, radius, x, y, startPix, endPix, buffer, color)
	while y >= x do
		x = x + 1
		if d > 0 then
			y = y - 1
			d = d + 4 * (x - y) + 10
		else
			d = d + 4 * x + 6
		end
		drawCirclePart(xc, yc, radius, x, y, startPix, endPix, buffer, color)
	end
	return buffer
end

local Gauge = {}
function Gauge:new (o)
	o = o or {}
	self.__index = self
	
	o.backColor = o.backColor or { 84, 84, 84 }
	o.foreColor = o.foreColor or { 4, 140, 135 }
	o.x = o.x or 0
	o.y = o.y or 0
	o.radius = o.radius or 16
	o.w = o.w or 4
	o.startAngle = o.startAngle or - pi / 9
	o.endAngle = o.endAngle or 7 * pi / 6.5
	o.value = 0
	o.label = o.label or nil
	o.showNum = true
	
	o.draw = self.draw
	o.setValue = self.setValue
	return o
end

function Gauge:draw (buffer)
	setColor(table.unpack(self.backColor))
	-- Draw background
	drawArc(self.x, self.y, self.radius, self.startAngle, self.endAngle, buffer, self.backColor)
	drawArc(self.x, self.y, self.radius + self.w, self.startAngle, self.endAngle, buffer, self.backColor)
	drawLine(buffer, self.backColor, self.x - self.radius - 2, self.y + self.radius - 6, self.x + self.radius + 2, self.y + self.radius - 6)
	-- floodFill(buffer, {1, 96}, {1, 32}, self.backColor, self.x - self.radius - 2, self.y)
	-- Draw filled in bar based on value
	setColor(table.unpack(self.foreColor))
	local startAngle = max((1 - self.value) * (self.endAngle - self.startAngle), (self.endAngle - self.startAngle) / 2)
	local endX = round(self.x + (self.radius + self.w) * cos(startAngle)) + self.w
	local endY = round(self.y - (self.radius + self.w) * sin(startAngle))
	-- Initial part to "click" to start filling
	local startX = self.x - self.radius - 1
	local startY = self.y + 4
	-- First half of bar
	floodFill(buffer, { self.x - self.radius - self.w, endX }, { endY, self.y + self.radius + self.w }, self.foreColor, startX, startY)
	-- Second half of bar
	if self.value >= 0.5 then
		startAngle = (1 - self.value) * (self.endAngle - self.startAngle) + self.startAngle
		endX = round(self.x + (self.radius + self.w) * cos(startAngle) + self.w)
		endY = round(self.y - (self.radius + self.w) * sin(startAngle))
		floodFill(buffer, { self.x, endX }, { self.y - self.radius - self.w, endY }, self.foreColor, self.x + 1, self.y - self.radius - 2)
	end
	-- drawArc(self.x, self.y, self.radius, math.floor(startAngle), endAngle - startAngle, self.w)
	-- Draw label in middle of arc
	if self.label ~= nil then
		screen.drawTextBox(self.x - self.radius + 1, self.y - 2, self.radius * 2, 5, self.label, 0)
	end
	-- Draw numerical value
	if self.showNum then
		setColor(238, 238, 238)
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


function onTick ()
    wtrGauge:setValue(input.getNumber(7))
    local air = math.min(input.getNumber(8) / maxPressure, 1)
    local power = math.min(input.getNumber(9) / maxPower, 1)
    airGauge:setValue(air)
    pwrGauge:setValue(power)
end

local buffer = {}
for y=1,32 do
	buffer[y] = {}
	for x=1, 96 do
		buffer[y][x] = nil
	end
end

function onDraw ()
	timer.start()
	for y = 1, 32 do
		buffer[y] = {}	
	end
	wtrGauge:draw(buffer)
	airGauge:draw(buffer)
	pwrGauge:draw(buffer)
	drawBuffer(buffer)
	timer.stop()
end