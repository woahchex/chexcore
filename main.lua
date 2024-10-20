require "chexcore"

-- love.mouse.setVisible(false)
-- some of the constructors are still somewhat manual but they'll get cleaned up !

-- Scenes contain all the components of the game
function love.load()


    -- Load the Chexcore example Scene!
    
    Chexcore:AddType(require"game.player.player")
    Chexcore:AddType(require"game.player.gameScene")
    Chexcore:AddType(require"game.player.gameCamera")
    local scene = require"game.scenes.testzone.init"
    scene.Update = function (self, dt)
        GameScene.Update(self, dt)
        
    end
    local player = Player.new():Nest(scene:GetLayer("Gameplay"))
    scene.Camera.Focus = player


    -- local scene = Scene.new{
    --     Update = function (self, dt)
    --         self.DrawSize = V{love.graphics.getDimensions()}
    --         print(self.MasterCanvas and self.MasterCanvas:GetSize())
    --         Scene.Update(self, dt)
    --     end
    -- }:With(
    --     Layer.new("Test", 400, 200):With(
    --         Text.new{Text = "Hello World", AnchorPoint=V{0.5,0.5}}
    --     )
    -- )
    


    -- scene:GetLayer("Gameplay"):SwapChildOrder(player, 1)

    -- print(tostring(player, true))

    -- local scene = require"chexcore.scenes.example.doodle" -- path to the .lua file of the scene

    -- A scene will only be processed by Chexcore while it is "mounted"
    Chexcore.MountScene(scene)


    
    -- print(player:ToString(true))
    -- You can unmount (or deactivate) a scene by using Chexcore.UnmountScene(scene)
end
