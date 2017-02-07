local andross = {}

andross.Animation = require "andross.animation"
andross.Skin = require "andross.skin"
andross.Skeleton = require "andross.skeleton"

local class = require "andross.middleclass"

andross.Attachment = class("Attachment")

function andross.Attachment:initialize(name)
    self.name = name
    self.positionX = 0
    self.positionY = 0
    self.angle = 0
    self.scaleX = 1
    self.scaleY = 1
end

return andross