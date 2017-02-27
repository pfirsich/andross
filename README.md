andross is a Lua library for 2D skeletal/bone animations. 

It provides different backends, where a backend for [löve](https://love2d.org/) is already provided.

There is also the possibility to implement different importers, where an importer for the DragonBones format is already provided as well. 
Originally it is written as a runtime for the [Cutout Animation Tools](https://github.com/ndee85/coa_tools) plugin for Blender, so that there are still quite some compatibility issues with files exported by DragonBones itself.

# Usage
The animation can be handled through a low and a high level API. For more expanded upon examples, have a look into the [examples folder](https://github.com/pfirsich/andross/tree/master/examples)!
A [minimal example using the high level api](https://github.com/pfirsich/andross/tree/master/examples/highlevelapi_minimal.lua) would look like this:
```lua 
andross = require "andross"
andross.backend = require "andross.love"
dragonBones = require "andross.dragonbones"

function love.load(args)
    local attachmentMgr = andross.backend.AtlasAttachmentManager("media/dude/texture/sprites/dude_atlas.png")
    local skel, anims, skin = dragonBones.import(love.filesystem.read("media/dude/dude.json"), attachmentMgr)

    animMgr = andross.AnimationManager(skel, anims, skin)
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

        animMgr:render()
    lg.pop()
end
```

For more detailed documentation, have a look into the [Wiki](https://github.com/pfirsich/andross/wiki) (coming soon).

# License 
This project is licensed under the MIT license, excluding the assets. 
I'd love if you tell me, when you use it in your project and I can be happy about people using my work for cool things. 

Also I chose MIT (so it's not mandatory) because I'm nice, but I would really love if you would contribute when you have fixes or feature additions.

# Contributing
If you want to contribute, pitch me a mail or open an issue. You may also just pull request any feature/fix. Style-wise etc. I would prefer if it just looked like the rest. That is very vague, I know. 

There is a todo.txt in the root of the project, which includes everything that I have in mind for future improvements. I should probably open some issues on these. 

Also I'm not very experienced with animation and such, so if you have nice insights on how things I do are usually (hopefully better) done or what kind of functionality is very common and needed, hit me up too!

# Libraries
andross makes use of the following awesome libraries:
* [middleclass by kikito](https://github.com/kikito/middleclass)
* [json by rxi](https://github.com/rxi/json.lua)

Thanks a lot for your good work!