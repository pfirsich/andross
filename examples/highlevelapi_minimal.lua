andross = require "andross"
andross.backend = require "andross.love"
dragonBones = require "andross.dragonbones"

function love.load(args)
    local attachmentMgr = andross.backend.AtlasAttachmentManager("media/dude/texture/sprites/dude_atlas.png")
    skel, anims, skin = dragonBones.import(love.filesystem.read("media/dude/dude.json"), attachmentMgr)

    animMgr = andross.AnimationManager(skel, anims)
    animMgr:play("running")
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

        skin:render(skel)
    lg.pop()
end