andross = require "andross"
andross.backend = require "andross.love"
dragonBones = require "andross.dragonbones"

function love.load(args)
    local attachmentMgr = andross.backend.AtlasAttachmentManager("media/dude/texture/sprites/dude_atlas.png")
    local skel, anims, skin = dragonBones.import(love.filesystem.read("media/dude/dude.json"), attachmentMgr)

    animMgr = andross.AnimationManager(skel, anims, skin)
    animMgr:play("running", 1.0)
end

function love.update(dt)
    animMgr:update(dt)
end

function love.draw()
    local lg = love.graphics
    lg.push()
        lg.translate(lg.getWidth()/2, lg.getHeight()/2)
        local scale = 0.5
        lg.scale(scale, scale)

        animMgr:poseAndRender()
    lg.pop()
end