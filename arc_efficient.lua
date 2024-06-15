-- Midpoint-circle/Bresenham integer method of drawing a circle used here
-- https://en.wikipedia.org/wiki/Midpoint_circle_algorithm
-- https://www.geeksforgeeks.org/bresenhams-circle-drawing-algorithm/
-- Modified to draw a partial arc (and optionally draw a thicker arc)

local pi = math.pi
local cos = math.cos
local sin = math.sin
local floor = math.floor
local ceil = math.ceil
local min = math.min
local max = math.max
local unpack = table.unpack
local setColor = screen.setColor
local drawRectF = screen.drawRectF

local startAngle = 0
local endAngle = 2 * pi

-- Can check if point lies in one of multiple ranges
local checkRange = function(x, y, ranges)
	for k,range in ipairs(ranges) do
		if x >= range.min and x <= range.max then
			return true
		end
	end
	return false
end

local drawIfInRange = function(x, y, ranges)
	if checkRange(x, y, ranges) then
		drawRectF(x, y, 1, 1)
	end
end

local drawCirclePart = function(xc, yc, r, x, y, startPix, endPix)
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
		drawIfInRange(xc + x, yc - y, { xrange })
		drawIfInRange(xc + y, yc - x, { xrange })
	end
	-- Quadrant 2
	if startSweep <= pi then
		drawIfInRange(xc - x, yc - y, { xrange })
		drawIfInRange(xc - y, yc - x, { xrange })
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
		drawIfInRange(xc - x, yc + y, xranges)
		drawIfInRange(xc - y, yc + x, xranges)
	end
	-- Quadrant 4
	if startSweep <= 2 * pi then
		drawIfInRange(xc + x, yc + y, xranges)
		drawIfInRange(xc + y, yc + x, xranges)
	end
end

local drawArc = function (xc, yc, radius, startAngle, endAngle)
	if startAngle < 0 then
		startAngle = 2 * pi + startAngle	
	end
	local startPix = { x = xc + floor(radius * cos(startAngle)), y = yc + floor(radius * sin(startAngle)), a = startAngle }
	local endPix = { x = xc + ceil(radius * cos(endAngle)), y = yc - floor(radius * sin(endAngle)), a = endAngle }
	local x = 0
	local y = radius
	local d = 3 - 2 * radius
	drawCirclePart(xc, yc, radius, x, y, startPix, endPix)
	while y >= x do
		x = x + 1
		if d > 0 then
			y = y - 1
			d = d + 4 * (x - y) + 10
		else
			d = d + 4 * x + 6
		end
		drawCirclePart(xc, yc, radius, x, y, startPix, endPix)
	end
end

function onTick ()
	startAngle = input.getNumber(5)
	endAngle = input.getNumber(6)
end
function onDraw ()
	setColor(255, 255, 255)
	drawArc(16, 16, 14, startAngle, endAngle)
end