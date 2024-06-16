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
