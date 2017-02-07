local andross = require "andross"
local class = require "andross.middleclass"

local backend = {}

backend.ImageAttachment = class("ImageAttachment", andross.Attachment)

function backend.ImageAttachment:initialize(name, imagePath)
    andross.Attachment.initialize(self, name)

    self.imagePath = imagePath
    self.offsetX = 0
    self.offsetY = 0
end

local imageMap = {}
local function getImage(path)
    if not imageMap[path] then
        imageMap[path] = love.graphics.newImage(path)
    end
    return imageMap[path]
end

function backend.ImageAttachment:draw(skeleton)
    local lg = love.graphics
    lg.push()

    -- apply bone transform
    -- we cannot just tell love to multiply a custom matrix to the modelview, so we have to decompose it
    -- and use the functions love provides
    local bone = skeleton.bones[self.parentBoneName]
    local bone_wT = bone.worldTransform.matrix
    lg.translate(bone_wT[5], bone_wT[6])
    -- the 2x2 upper left block of the matrix {a, b, c, d} can be decompsed into a shear and scale
    -- [s_x, 0, 0, s_y] *  [1, sh_x, sh_y, 1] = [s_x, s_x*sh_x, s_y*sh_y, s_y]
    lg.scale(bone_wT[1], bone_wT[4])
    lg.shear(bone_wT[2] / bone_wT[1], bone_wT[3] / bone_wT[4])

    -- draw
    lg.setColor(255, 255, 255, 255)
    lg.draw(getImage(self.imagePath), self.positionX, self.positionY, self.angle, self.scaleX, self.scaleY)

    if drawBones then
        lg.rectangle("fill", 0, -20, bone.length, 40)
        lg.setColor(0, 0, 0, 255)
        lg.rectangle("fill", 5, -20 + 5, bone.length - 10, 40 - 10)
    end

    lg.pop()
end

return backend