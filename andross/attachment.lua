local class = require "andross.middleclass"

Attachment = class("Attachment")

function Attachment:initialize(name)
    self.name = name
    self.positionX = 0
    self.positionY = 0
    self.angle = 0
    self.scaleX = 1
    self.scaleY = 1
end

return Attachment