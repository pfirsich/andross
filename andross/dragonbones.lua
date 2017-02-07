local andross = require "andross"
local json = require "andross.json"

local dragonBones = {}

function dragonBones.import(str, attachmentManager)
    local transforms = {
        "x", "y", "skX", "scX", "scY"
    }
    local transformNameMap = {
        x = "positionX",
        y = "positionY",
        skX = "angle",
        scX = "scaleX",
        scY = "scaleY",
    }

    local jsonTable = json.decode(str)
    local frameRate = jsonTable.frameRate
    local jsonArmature = jsonTable.armature[1]

    -- Skeleton
    local skel = andross.Skeleton()
    for boneIndex, bone in ipairs(jsonArmature.bone) do
        local angle = bone.transform.skX
        if angle then angle = angle * math.pi / 180.0 end
        skel:addBone(bone.name, bone.parent, bone.length,
                     bone.transform.x, bone.transform.y, angle,
                     bone.transform.scX, bone.transform.scY)
    end
    skel:update()

    -- Animation
    local anims = {}
    for animationIndex, animation in ipairs(jsonArmature.animation) do
        local anim = andross.Animation(animation.name, animation.duration / frameRate)
        for boneIndex, bone in ipairs(animation.bone) do
            local t = 0
            for frameIndex, frame in ipairs(bone.frame) do
                for _, name in ipairs(transforms) do
                    if frame.transform[name] then
                        local value = frame.transform[name]
                        if name == "skX" then value = value * math.pi / 180.0 end
                        anim:addKeyframe(t / frameRate, "bones", bone.name, transformNameMap[name], value)
                    end
                end
                t = t + frame.duration
            end
        end
        anims[animation.name] = anim
    end

    -- Skin
    local skin = andross.Skin(jsonArmature.skin[1].name)
    for attachmentIndex, attachment in ipairs(jsonArmature.skin[1].slot) do
        local data = attachment.display[1]
        if data.type == "mesh" then
            -- TODO: make this check more accurate
            -- This is optimized for coa_blender's weird way of exporting
            local isImage = #data.vertices == 8
            if data.weights then
                local boneIndex
                for i = 1, #data.weights, 3 do
                    if boneIndex and boneIndex ~= data.weights[i+1] then
                        isImage = false
                        break
                    end
                    boneIndex = data.weights[i+1]

                    if math.abs(data.weights[i+2] - 1.0) > 1e-2 then
                        isImage = false
                        break
                    end
                end
                boneIndex = boneIndex + 1 -- we use 1-based indexing, the file uses 0

                if isImage then
                    local attachment = attachmentManager:getImageAttachment(attachment.name)
                    skin:addAttachment(boneIndex, attachment)

                    -- world space in data.transform (or more accurate: in the space of the root bone)
                    attachment.positionX = data.transform.x or 0
                    attachment.positionY = data.transform.y or 0
                    attachment.angle = (data.transform.skX or 0) * math.pi/180.0
                    attachment.scaleX = data.transform.scX or 1
                    attachment.scaleY = data.transform.scY or 1

                    -- COA parents every slot to the Armature itself, not to the bone it's attached to.
                    -- So the attachment's transformation are in world space and we have to convert to the bone's space
                    local worldTransform = andross.math.Transform(attachment.positionX, attachment.positionY,
                                                                  attachment.angle, attachment.scaleX, attachment.scaleY)
                    local finalTransform = skel.bones[boneIndex].worldTransform:inverse():compose(worldTransform)

                    attachment.positionX, attachment.positionY, attachment.angle,
                    attachment.scaleX, attachment.scaleY = finalTransform:decomposeTRS()
                else
                    print("Real mesh!")
                end
            end
        end

        if data.type == "image" then
            local attachment = attachmentManager:getImageAttachment(attachment.name)
            skin:addAttachment(jsonArmature.slot[attachmentIndex].parent, attachment)
            for _, name in ipairs(transforms) do
                if data.transform[name] then
                    local value = data.transform[name]
                    if name == "skX" then value = value * math.pi / 180.0 end
                    attachment[transformNameMap[name]] = data.transform[name]
                end
            end
        end
    end

    return skel, anims, skin
end

function dragonBones.importAtlasData(str)
    return json.decode(str).SubTexture
end

return dragonBones