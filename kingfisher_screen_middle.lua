s=screen
local screenWidth = 0
local screenHeight = 0

local speed = 0
local mode = 0

-- Custom font stuff
-- ======================
dl=s.drawLine

function Txt(x,y,t)for i=1,#t do c=t:sub(i,i):upper():byte()*3-95if c>193then c=c-78 end a="0x"..string.sub("0000B0101F6F5FAB6DEDA010096690A4A4E4048444080168F9F8FABDDDB9F47DBBDDF3D1FDFF570500580A4AAA4A0391B96E5E6DF99669F9DF15FD96F4F9F978496F88FF3FF1F69625F79FA5FDDA1F1F8F787FCFB4B3C3BFD09F861F902128880219F60F06F9426",c,c+2)for j=0,11 do if a&(1<<j)>0then b=x+j//4+i*4-4g=y+j%4 dl(b,g,b,g+1)end end end end
-- ===========================


function drawBackgroundLines ()
	local p={{4,140,135,255,24,0,2,1,70,0,2,1,25,1,2,1,69,1,2,1,26,2,2,1,68,2,2,1,27,3,2,1,67,3,2,1,28,4,2,1,66,4,2,1,29,5,38,1,29,23,38,1,28,24,2,1,66,24,2,1,27,25,2,1,67,25,2,1,26,26,2,1,68,26,2,1,25,27,2,1,69,27,2,1,24,28,2,1,70,28,2,1,23,29,2,1,71,29,2,1,0,30,24,1,72,30,24,1},{76,156,242,255,26,0,1,1,69,0,1,1,27,1,1,1,68,1,1,1,28,2,1,1,67,2,1,1,29,3,1,1,66,3,1,1,30,4,1,1,65,4,1,1,30,24,1,1,65,24,1,1,29,25,1,1,66,25,1,1,28,26,1,1,67,26,1,1,27,27,1,1,68,27,1,1,26,28,1,1,69,28,1,1,25,29,1,1,70,29,1,1,24,30,1,1,71,30,1,1},}
	for i=1,#p do s.setColor(p[i][1],p[i][2],p[i][3],p[i][4]) for w=5,#p[i],4 do s.drawRectF(p[i][w],p[i][w+1]+0.5,p[i][w+2],p[i][w+3]) end end
end

function drawSpeed ()
	local kph = speed * 3.6
	if kph < 0 then
		kph = 0
	end
	local output = string.format("%0.0f", kph)
	s.setColor(255, 255, 255)
	s.drawTextBox(screenWidth / 2 - 10, screenHeight / 2 - 3, 20, 5, output, 0)
end

function drawSpeedUnits ()
	local p={{4,140,135,255,38,26,1,2,41,26,1,1,43,26,1,1,47,26,1,1,53,26,1,1,55,26,1,2,58,26,1,2,40,27,1,1,43,27,2,1,46,27,2,1,52,27,1,1,38,28,2,1,43,28,1,3,45,28,1,1,47,28,1,3,51,28,1,1,55,28,4,1,38,29,1,2,40,29,1,1,50,29,1,1,55,29,1,2,58,29,1,2,41,30,1,1,49,30,1,1},}
	for i=1,#p do s.setColor(p[i][1],p[i][2],p[i][3],p[i][4]) for w=5,#p[i],4 do s.drawRectF(p[i][w],p[i][w+1]+0.5,p[i][w+2],p[i][w+3]) end end
end

function onTick ()
	speed = input.getNumber(2)
	mode = input.getNumber(5)
end

function onDraw ()
	screenWidth = screen.getWidth()
	screenHeight = screen.getHeight()
	drawBackgroundLines()
	drawSpeed()
	drawSpeedUnits()

	s.setColor(238, 238, 238)
	Txt(1, 19, "ALT")
	Txt(1, 25, "1234")
	Txt(1, 2, "FLIGHT")
	Txt(74, 2, "00:00")
end
