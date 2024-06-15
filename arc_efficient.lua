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
local setColor = screen.setColor
local drawRectF = screen.drawRectF

local startAngle = 0
local endAngle = 2 * pi

local checkRange = function(x, y, xrange, yrange)
	return x >= xrange.min and x <= xrange.max and y >= yrange.min and y <= yrange.max
end

local drawIfInRange = function(x, y, xrange, yrange)
	if checkRange(x, y, xrange, yrange) then
		drawRectF(x, y, 1, 1)	
	end
end

local drawCirclePart = function(xc, yc, r, x, y, startPix, endPix)
	local xrange
	if endPix.a <= pi then
		xrange = { min = endPix.x, max = startPix.x }
	else
		xrange = { min = xc - r, max = startPix.x }
	end
	local yrange = { min = yc - r, max = yc + r }
	-- Quadrant 1
	if startPix.a <= pi / 2 then
		drawIfInRange(xc + x, yc - y, xrange, yrange)
		drawIfInRange(xc + y, yc - x, xrange, yrange)
	end
	-- Quadrant 2
	if startPix.a <= pi then
		drawIfInRange(xc - x, yc - y, xrange, yrange)
		drawIfInRange(xc - y, yc - x, xrange, yrange)
	end
	-- Restart range for bottom half
	if startPix.a >= pi and endPix.a > pi then
		xrange = { min = startPix.x, max = endPix.x }
	elseif startPix.a < pi and endPix.a >= pi then
		xrange = { min = xc - r, max = endPix.x }
	else
		xrange = { min = xc - r, max = xc - r - 1 }	
	end
	-- Quadrant 3
	if startPix.a <= 3 * pi / 2 then
		drawIfInRange(xc - x, yc + y, xrange, yrange)
		drawIfInRange(xc - y, yc + x, xrange, yrange)
	end
	-- Quadrant 4
	if startPix.a <= 2 * pi then
		drawIfInRange(xc + x, yc + y, xrange, yrange)
		drawIfInRange(xc + y, yc + x, xrange, yrange)
	end
end

local drawArc = function (xc, yc, radius, startAngle, endAngle)
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