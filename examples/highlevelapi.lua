andross = require "andross"
andross.backend = require "andross.love"
dragonBones = require "andross.dragonbones"

function love.load(args)
    --mgr = andross.backend.AttachmentManager("media/dude/dude/sprites/")
    local attachmentMgr = andross.backend.AtlasAttachmentManager("media/dude/texture/sprites/dude_atlas.png")
    local skel, anims, skin = dragonBones.import(love.filesystem.read("media/dude/dude.json"), attachmentMgr)
    animMgr = andross.AnimationManager(skel, anims, skin)

    animMgr:setLooping("jump", false)

    animMgr:setLooping("land", false)
    animMgr:setSpeed("land", anims["land"].duration/0.5)
    animMgr:setCallback("land", anims["land"].duration, function()
        animMgr:fadeOut("land", 0.2)
    end)

    animMgr:play("idle")
    animMgr:play("running")
    animMgr:addAnimationGroup("idleRun")
    animMgr:setBlendWeight("idleRun", 1.0)

    velocityX = 0
    velocityY = 0
    height = 0

    scale = 0.4
    drawBones = false
end

function love.update(dt)
    if love.keyboard.isDown("s") then
        dt = dt * 0.1
        love.timer.sleep(0.1)
    end

    -- "Physics"
    -- increase velocity when pressing left or right
    -- apply friction when nothing is pressed and give an acceleration bonus if directions are different
    local accell = (love.keyboard.isDown("right") and 1 or 0) - (love.keyboard.isDown("left") and 1 or 0)
    if math.abs(accell) > 0 then
        if accell * velocityX < 0 then -- pointing in different directions
            accell = accell * 5
        end
        velocityX = velocityX + accell * dt
    else
        velocityX = velocityX - velocityX * dt
    end

    local maxSpeed = 3.0 -- maxSpeed / accell = seconds of acceleration needed to reach max speed
    velocityX = math.min(maxSpeed, velocityX)

    -- gravity
    velocityY = velocityY + 1000 * dt
    height = math.min(0, height + velocityY * dt)
    local onGround = height == 0
    if onGround then velocityY = 0 end

    -- Animation
    local runWeight = math.abs(velocityX / maxSpeed)
    local idleWeight = 1.0 - runWeight

    if velocityY > 0 and animMgr:getBlendWeight("falling") <= 0 then
        animMgr:fadeInEx("falling", 0.3)
    end

    if onGround and animMgr:getBlendWeight("idleRun") <= 0 then
        animMgr:fadeInEx("land", 0.1)
        animMgr:fadeIn("idleRun", 0.6)
    end

    animMgr:setBlendWeight("idle", idleWeight * animMgr:getBlendWeight("idleRun"))
    animMgr:setBlendWeight("running", runWeight * animMgr:getBlendWeight("idleRun"))

    animMgr:update(dt)
end

function love.draw()
    local lg = love.graphics
    lg.push()
        lg.translate(lg.getWidth()/2, lg.getHeight()/2)
        local scaleX = 1.0
        if velocityX < 0 then scaleX = -1.0 end
        lg.scale(scale * scaleX, scale)

        lg.setColor(80, 80, 80, 255)
        local groundSize = 6000
        lg.rectangle("fill", -groundSize/2, 0, groundSize, groundSize)

        lg.translate(0, height)
        lg.setColor(255, 255, 255, 255)
        animMgr:poseAndRender()

        if drawBones then
            andross.backend.debugDrawBones(animMgr.skeleton)
        end
    lg.pop()
    lg.print("Left/Right to run, space to jump", 5, 5)
    lg.print("'F' to toggle bone debug draw", 5, 30)
end

function love.wheelmoved(dx, dy)
    scale = scale * math.pow(1.1, dy)
end

function love.keypressed(key)
    if key == "space" then
        animMgr:fadeInEx("jump", 0.35)
        velocityY = -1000
    end

    if key == "f" then -- pay respects, lul
        drawBones = not drawBones
    end
end