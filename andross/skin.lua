local class = require "andross.middleclass"

local Skin = class("Skin")

function Skin:initialize(name)
    self.name = name
    self.attachments = {}
end

function Skin:addAttachment(boneName, attachment)
    attachment.parentBoneName = boneName
    assert(not self.attachments[attachment.name], "Attachment with name '" .. attachment.name .. "' already present")
    self.attachments[attachment.name] = attachment
    self.attachments[#self.attachments+1] = attachment
end

function Skin:render(skeleton)
    for i, attachment in ipairs(self.attachments) do
        attachment:draw(skeleton)
    end
end

return Skin