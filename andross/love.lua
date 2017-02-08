local andross = require "andross"
local class = require "andross.middleclass"

local backend = {}

function love.graphics.multiplyMatrix(matrix)
    -- we cannot just tell love to multiply a custom matrix to the modelview, so we have to decompose it
    -- and use the functions love provides
    love.graphics.translate(matrix[5], matrix[6])
    -- the 2x2 upper left block of the matrix {a, b, c, d} can be decompsed into a shear and scale
    -- [s_x, 0, 0, s_y] *  [1, sh_x, sh_y, 1] = [s_x, s_x*sh_x, s_y*sh_y, s_y]
    love.graphics.scale(matrix[1], matrix[4])
    love.graphics.shear(matrix[2] / matrix[1], matrix[3] / matrix[4])
end

backend.ImageAttachment = class("ImageAttachment", andross.Attachment)

function backend.ImageAttachment:initialize(name, image, quad)
    andross.Attachment.initialize(self, name)
    self.image = image
    self.quad = quad
    self.offsetX = 0
    self.offsetY = 0
end

function backend.ImageAttachment:draw(skeleton)
    local lg = love.graphics
    lg.push()

    -- apply bone transform
    local bone = skeleton.bones[self.parentBoneName]
    lg.multiplyMatrix(bone.worldTransform.matrix)

    lg.push()
    if self.bindTransform then
        lg.multiplyMatrix(self.bindTransform.matrix)
    end

    -- draw
    lg.setColor(255, 255, 255, 255)
    if self.quad then
        lg.draw(self.image, self.quad, self.positionX, self.positionY, self.angle, self.scaleX, self.scaleY)
    else
        lg.draw(self.image, self.positionX, self.positionY, self.angle, self.scaleX, self.scaleY)
    end
    lg.pop()

    if drawBones then
        lg.rectangle("fill", 0, -20, bone.length, 40)
        lg.setColor(0, 0, 0, 255)
        lg.rectangle("fill", 5, -20 + 5, bone.length - 10, 40 - 10)
    end

    lg.pop()
end

backend.AttachmentManager = class("AttachmentManager")

function backend.AttachmentManager:initialize(imagePathPrefix)
    self.prefix = imagePathPrefix
end

function backend.AttachmentManager:getImageAttachment(name)
    return backend.ImageAttachment(name, love.graphics.newImage(self.prefix .. name))
end

--function backend.AttachmentManager:getMesh(name, otherStuff) end

backend.AtlasAttachmentManager = class("AtlasAttachmentManager")

-- atlasData = list of {x = .., y = .., width = .., height = .., name = ..}
function backend.AtlasAttachmentManager:initialize(imagePath, atlasData)
    self.image = love.graphics.newImage(imagePath)
    self.imageMap = {}

    local iW, iH = self.image:getDimensions()
    for _, image in ipairs(atlasData) do
        local quad = love.graphics.newQuad(image.x, image.y, image.width, image.height, iW, iH)
        self.imageMap[image.name] = backend.ImageAttachment(image.name, self.image, quad)
    end
end

function backend.AtlasAttachmentManager:getImageAttachment(name)
    return self.imageMap[name]
end

return backend