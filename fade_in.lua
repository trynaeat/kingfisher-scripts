-- FadeIn
local FadeIn = {}
function FadeIn:new(o)
	o.target = o.target
	-- In game ticks
	o.duration = 120
	o.ticks = 0
	o.stopped = true
	o.tick = self.tick
	o.start = self.start
	o.reset = self.reset
	return o
end

function FadeIn:tick()
	if self.stopped then
		return
	end
	self.ticks = self.ticks + 1
	self.target.opacity = (self.ticks / self.duration) * 255
	if self.ticks >= self.duration then
		self.stopped = true
	end
end

function FadeIn:start()
	self.stopped = false
end

function FadeIn:reset()
	self.ticks = 0
end