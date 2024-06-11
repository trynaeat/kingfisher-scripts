-- BlinkAnim
local BlinkAnim = {}
function BlinkAnim:new(o)
	o = o or {}
	o.target = o.target or nil
	o.count = o.count or 3
	-- In game ticks
	o.duration = o.duration or 30
	o.currCount = 0
	o.ticks = 0
	o.stopped = true
	o.flipped = false
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
	elseif self.ticks >= self.duration / 2 and not self.flipped then
		self.target.visible = not self.target.visible
		self.flipped = true
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