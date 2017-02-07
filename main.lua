andross = require "andross"
andross.backend = require "andross.love"
dragonBones = require "andross.dragonbones"

function love.load(args)
    --mgr = andross.backend.AttachmentManager("media/monstar_arm/sprites/")
    --skel, anims, skin = dragonBones.import(love.filesystem.read("media/monstar_arm/monstar_arm.json"), mgr)

    mgr = andross.backend.AttachmentManager("media/stip/sprites/")
    skel, anims, skin = dragonBones.import(love.filesystem.read("media/stip/stip.json"), mgr)

    --mgr = andross.backend.AtlasAttachmentManager("media/db_export/NewDragon_tex.png", dragonBones.importAtlasData(love.filesystem.read("media/db_export/NewDragon_tex.json")))
    --skel, anims, skin = dragonBones.import(love.filesystem.read("media/db_export/NewDragon_ske.json"), mgr)

    --mgr = andross.backend.AttachmentManager("media/dude/dude/sprites")
    --skel, anims, skin = dragonBones.import(love.filesystem.read("media/dude/dude.json"), mgr)

    scale = 0.2
    animName = args[2]
    print("anim:", animName)
    drawBones = true
end

function love.update()
    local anim = anims["ground_side"] or anims["stand"] or anims["Run"] or anims["Idle"] or anims["Claw"]
    if animName then
        anim = anims[animName]
    end
    local time = love.timer.getTime()
    local pose = anim:getPose(time)
    pose:apply(skel)
    skel:update()
end

function love.draw()
    local lg = love.graphics
    lg.push()
    lg.translate(lg.getWidth()/2, lg.getHeight()/2)
    lg.scale(scale, scale)
    skin:render(skel)
    lg.pop()

    -- lg.setColor(255, 255, 255, 255)
    -- local x, y = 0, 0
    -- for k, v in pairs(mgr.imageMap) do
    --     lg.draw(v.image, v.quad, x, y)
    --     lg.print(k, x, y)
    --     x = x + 200
    --     if x > lg.getWidth() then
    --         y = y + 200
    --         x = 0
    --     end
    -- end
end

function love.wheelmoved(dx, dy)
    scale = scale * math.pow(1.1, dy)
end

function love.keypressed(key)
    if key == "escape" then love.event.push("quit") end
    if key == "space" then drawBones = not drawBones end
end