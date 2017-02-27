andross = require "andross"
andross.backend = require "andross.love"
dragonBones = require "andross.dragonbones"

-- excuse all the globals and such, but I just want to get this out there and don't think at all if possible

function love.load(args)
    --local attachmentMgr = andross.backend.AttachmentManager("media/dude/dude/sprites/")
    local attachmentMgr = andross.backend.AtlasAttachmentManager("media/dude/texture/sprites/dude_atlas.png")
    skel, anims, skin = dragonBones.import(love.filesystem.read("media/dude/dude.json"), attachmentMgr)

    animNameList = {}
    currentAnimationNameIndex = 1
    for name, _ in pairs(anims) do
        table.insert(animNameList, name)
        if name == args[2] then currentAnimationNameIndex = #animNameList end
    end

    scale = 0.2
    drawBones = true
end

function love.update(dt)
    -- essentially you can get a pose from an animation for a specified time
    -- then you can blend them yourself with Pose.static.mix() and Pose.static.overlay()
    -- then apply to the skeleton and update it

    -- you can also look at the AnimationManager class (which implements the high level api)
    -- specifically the :update() function will show you how to use the low level api for most cases!

    local time = love.timer.getTime()
    local anim = anims[animNameList[currentAnimationNameIndex]]
    local pose = anim:getPose(time)
    -- This seems a little weird and maybe it is, but poses only set values that they have keyed
    -- (so you can overlay them easier)
    -- But this also means that if you apply a pose with some keys and then apply another one, which
    -- does not have those keys, the values set before will not reset! So you would have to reset
    -- the skeleton probably once per frame (reset all transforms of all bones)
    skel:reset()
    pose:apply(skel)
    skel:update()
end

function love.draw()
    local lg = love.graphics
    lg.push()
        lg.translate(lg.getWidth()/2, lg.getHeight()/2)
        lg.scale(scale, scale)

        -- drawing is easy too, if you want to flip it, use lg.scale
        skin:render(skel)

        if drawBones then
            andross.backend.debugDrawBones(skel)
        end
    lg.pop()

    lg.setColor(255, 255, 255, 255)
    lg.print(animNameList[currentAnimationNameIndex], 5, 5)
end

function love.wheelmoved(dx, dy)
    scale = scale * math.pow(1.1, dy)
end

function love.keypressed(key)
    if key == "escape" then love.event.push("quit") end
    if key == "space" then drawBones = not drawBones end

    local deltaAnimIndex = 0
    if key == "up" then deltaAnimIndex = 1 end
    if key == "down" then deltaAnimIndex = -1 end
    currentAnimationNameIndex = ((currentAnimationNameIndex + deltaAnimIndex - 1) % #animNameList) + 1
end