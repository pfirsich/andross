andross = require "andross"
andross.backend = require "andross.love"
importDragonBones = require "andross.dragonbones"

function love.load(args)
    --skel, anims, skin = importDragonBones(love.filesystem.read("media/monstar_arm/monstar_arm.json"), "media/monstar_arm/sprites/")
    skel, anims, skin = importDragonBones(love.filesystem.read("media/stip/stip.json"), "media/stip/sprites/")
    --skel, anims, skin = importDragonBones(love.filesystem.read("media/db_export/NewDragon_ske.json"), "")
    --skel, anims, skin = importDragonBones(love.filesystem.read("media/hampelmann/hampelmann.json"), "")
    --skel, anims, skin = importDragonBones(love.filesystem.read("media/wobble/wobble.json"), "")
    --skel, anims, skin = importDragonBones(love.filesystem.read("media/dude/dude.json"), "media/dude/dude/sprites/")

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
    time = time - math.floor(time / anim.duration) * anim.duration
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
end

function love.wheelmoved(dx, dy)
    scale = scale * math.pow(1.1, dy)
end

function love.keypressed(key)
    if key == "escape" then love.event.push("quit") end
    if key == "space" then drawBones = not drawBones end
end