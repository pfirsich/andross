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
end

backend.MeshAttachment = class("MeshAttachment", andross.Attachment)

-- vertices are a list of {x, y, u, v}
-- weights are a list of {boneIndex1, weight1, boneIndex2, weight2, ...} for each vertex
-- indices are one-based, boneIndices obviously too!
function backend.MeshAttachment:initialize(name, image, vertices, weights, indices)
    assert(#indices % 3 == 0, "Draw mode is 'triangles', so indices have to be a multiple of 3")
    andross.Attachment.initialize(self, name)
    self.vertices = vertices
    self.weights = weights
    self.indices = indices
    self.static = false

    if weights then
        self.static = true
        local boneIndex
        for i = 1, #vertices do
            if #weights[i] == 2 then -- vertex only weighed to one bone
                if boneIndex == nil then
                    boneIndex = weights[i][1]
                end
                if weights[i][1] ~= boneIndex then
                    -- not all vertices are bound to the same bone -> non-static -> skinning
                    self.static = false
                    break
                end
            end
        end
        if self.static then
            self.realParent = boneIndex
        end
    end

    -- TODO: GPU skinning?
    self.mesh = love.graphics.newMesh(vertices, "triangles", self.static and "static" or "stream")
    self.mesh:setVertexMap(indices)
    self.mesh:setTexture(image)
end

function backend.MeshAttachment:draw(skeleton)
    local lg = love.graphics
    lg.push()

    -- apply bone transform
    local bone = skeleton.bones[self.parentBoneName]
    lg.multiplyMatrix(bone.worldTransform.matrix)

    if self.bindTransform then
        lg.multiplyMatrix(self.bindTransform.matrix)
    end

    -- draw
    lg.setColor(255, 255, 255, 255)
    lg.draw(self.mesh, self.positionX, self.positionY, self.angle, self.scaleX, self.scaleY)

    lg.pop()
end

backend.AttachmentManager = class("AttachmentManager")

function backend.AttachmentManager:initialize(imagePathPrefix)
    self.prefix = imagePathPrefix
end

function backend.AttachmentManager:getImageAttachment(name)
    return backend.ImageAttachment(name, love.graphics.newImage(self.prefix .. name))
end

function backend.AttachmentManager:getMeshAttachment(name, vertices, weights, indices)
    return backend.MeshAttachment(name, love.graphics.newImage(self.prefix .. name), vertices, weights, indices)
end

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

function backend.AtlasAttachmentManager:getMeshAttachment(name, vertices, weights, indices)
    return backend.MeshAttachment(name, self.image, vertices, weights, indices)
end

return backend