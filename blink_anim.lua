-- BlinkAnim
local BlinkAnim = {}
function BlinkAnim:new(o)
	o.target = o.target
	o.count = o.count or 7
	-- In game ticks
	o.duration = o.duration
	o.currCount = 0
	o.ticks = 0
	o.stopped = true
	o.tick = self.tick
	o.start = self.start
	o.reset = self.reset
	return o
end
function BlinkAnim:tick()
	if self.stopped then
		return
	end
	self.ticks = self.ticks + 1
	if self.ticks >= self.duration then
		self.currCount = self.currCount + 1
		self.ticks = 0
		self.flipped = false
		self.target.visible = not self.target.visible
	end
	if self.currCount >= self.count then
		self.stopped = true
	end
end
function BlinkAnim:start()
	self.stopped = false
end
function BlinkAnim:reset()
	self.currCount = 0
	self.ticks = 0
	self.flipped = false
end