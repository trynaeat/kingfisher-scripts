local Toggle = {}
function Toggle:new (o)
	o = o or {}
	o.x = o.x or 1
	o.y = o.y or 1
	o.value = false
	o.label = o.label or nil
	o.width = o.width or 9
	o.height = o.height or 5
	o.borderColor = o.borderColor or { 84, 84, 84 }
	o.selectedColor = o.selectedColor or { 4, 140, 135 }
	o.buttonColor = o.buttonColor or { 238, 238, 238 }
	o.labelColor = o.labelColor or { 4, 140, 135 }
	o.backColor = o.backColor or { 68, 149, 241 }
	o.cb = o.cb or nil
	o.onChange = o.onChange or nil
	o.draw = self.draw
	o.isClicked = self.isClicked
	o.onClick = self.onClick
	o.setValue = self.setValue
	return o
end

function Toggle:isClicked(x, y)
	return x >= self.x and x <= self.x + self.width - 1 and y >= self.y and y <= self.y + self.height - 1
end

function Toggle:onClick()
	return function (x, y)
		if self:isClicked(x, y) then
			self.value = not self.value	
			if self.cb then
				self.cb()	
			end
		end	
	end
end

function Toggle:setValue()
	return function (v)
		self.value = v
		if self.onChange then
			self.onChange(self.value)	
		end
	end
end

function Toggle:draw()
	-- Draw button border
	if not self.value then
		s.setColor(unpack(self.borderColor))
	else
		s.setColor(unpack(self.selectedColor))
	end
	s.drawRect(self.x, self.y, self.width, self.height)
	-- Fill in background if selected
	if self.value then
		s.setColor(unpack(self.backColor))
		s.drawRectF(self.x + 1, self.y + 1, self.width - 1, self.height - 1)
	end
	-- Draw button square
	if not self.value then
		s.setColor(unpack(self.buttonColor))
		s.drawRectF(self.x + 2, self.y + 2, self.width / 2 - 2, self.height / 2)
	else
		s.setColor(unpack(self.selectedColor))
		s.drawRectF(self.x + self.width / 2, self.y + 2, self.width / 2 - 1, self.height / 2)
	end
	-- Draw label
	if self.label ~= nil then
		s.setColor(unpack(self.labelColor))
		s.drawTextBox(self.x + self.width + 2, self.y, string.len(self.label) * 5, self.height, self.label, -1, 0)
	end
end