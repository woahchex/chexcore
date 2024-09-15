local GameScene = {
    -- properties
    Name = "GameScene",

    Player = nil,   -- will search for this at runtime
    
    DeathHeight = 300, -- if the player's height is greater than this, respawn it
    InRespawn = false,  -- whether the player is in a respawn sequence or not

    ShowStats = false,  -- show stats of the player

    GuiLayer = nil,     -- set in constructor


    -- internal properties
    _super = "Scene",      -- Supertype
    _global = true
}

function GameScene.new(properties)
    local newGameScene = GameScene:SuperInstance()
    if properties then
        for prop, val in pairs(properties) do
            newGameScene[prop] = val
        end
    end


    newGameScene.GuiLayer = newGameScene:Adopt(Layer.new("GUI", 1280, 720, true))

    newGameScene.fallGuiTop = newGameScene.GuiLayer:Adopt(Prop.new{
        Name = "FallGuiTop",
        Texture = Texture.new("chexcore/assets/images/test/fallGui.png"),
        Size = V{1280, 720},
        Position = V{1280/2, 720},
        AnchorPoint = V{0.5, 0},
        Visible = false,
    })

    newGameScene.fallGuiBottom = newGameScene.GuiLayer:Adopt(Prop.new{
        Name = "FallGuiBottom",
        Texture = Texture.new("chexcore/assets/images/test/fallGui.png"),
        Size = V{1280, 720},
        Position = V{1280/2, 720*2},
        AnchorPoint = V{0.5, 1},
        Rotation = math.rad(180),
        Visible = false,
    })

    newGameScene.statsGui = newGameScene.GuiLayer:Adopt(Gui.new{
        Name = "StatsGui",
        Size = V{350, 340},
        Position = V{0, 0},
        Texture = Texture.new("chexcore/assets/images/square.png"),
        Color = V{0, 0, 0, 0.8},
        Visible = false,

        active = false,
        originPos = nil,
        originMousePos = nil,
        timePressed = 0,
        drawChildren = true,
        goalRotation = 0,

        OnSelectStart = function (self)
            self.active = true
            self.originPos = self.Position
            self.originMousePos = self:GetLayer():GetMousePosition()
        end,
        OnHoverWhileSelected = function (self)
            self:OnSelectStart()
        end,
        OnSelectEnd = function (self)
            self.active = false
            if self.timePressed < 0.3 and (self.originPos - self.Position):Magnitude() < 20 then
                self.Position = self.originPos
                self.drawChildren = not self.drawChildren

            end
            self.timePressed = 0
        end,
        Update = function (self, dt)
            if self.active then
                self.timePressed = self.timePressed + dt
                local newPos = self.Position:Lerp(self.originPos + (self:GetLayer():GetMousePosition() - self.originMousePos), 50*dt)
                local xDiff = newPos.X - self.Position.X
                self.goalRotation = self.goalRotation + xDiff/500
                self.Position = newPos

                self:SetEdge("left", math.max(self:GetEdge("left"), 0))
                self:SetEdge("right", math.min(self:GetEdge("right"), 1280))
                self:SetEdge("top", math.max(self:GetEdge("top"), 0))
                self:SetEdge("bottom", math.min(self:GetEdge("bottom"), 720))
            end
        end
    })

    newGameScene.GuiLayer:GetChild("StatsGui"):Adopt(Text.new{
        AlignMode = "justify",
        TextColor = V{1, 1, 1},
        -- Font = Font.new(20--[["chexcore/assets/fonts/chexfont_bold.ttf"]]),
        Font = Font.new("chexcore/assets/fonts/futura.ttf", 20),
        Text = "STATS:",
        Visible = true,
        -- FontSize = 20,
        Size = V{330, 330},
        AnchorPoint = V{0.5, 0.5},
        Position = V{10, 10},
        Draw = function (self, tx, ty)
            if self:GetParent().Visible then
                self.Position = self:GetParent().Position + self:GetParent().Size/2
                Text.Draw(self, tx, ty)
            end
        end
    })

    return GameScene:Connect(newGameScene)
end

local Scene = Scene
function GameScene:Update(dt)
    if not self.Player then
        self.Player = self:GetDescendant(Object.IsA, "Player")
    else
        -- print(self.Player.Position)
        
        if self.statsGui.Visible then
            local curFpsRatio = (1/self.Player:GetLayer():GetParent().FrameLimit)/Chexcore._lastFrameTime
            self.lastFpsRatio = self.lastFpsRatio or curFpsRatio

            self.lastFpsRatio = math.lerp(self.lastFpsRatio, curFpsRatio, 0.05)

            self.statsGui:GetChild("Text").Text = {V{1,1,1,.8},"- STATS: -\n" , V{1,1,1}, 
                                        "Speed: V{ ", V{1,1 - ((math.abs(self.Player.Velocity.X) - self.Player.RollPower) / self.Player.MaxSpeed.X),1 - (math.abs(self.Player.Velocity.X) / self.Player.MaxSpeed.X)}, ("%0.2f"):format(self.Player.Velocity.X) .. ", ", V{1 - math.abs(self.Player.Velocity.Y)/self.Player.MaxSpeed.Y, 1, 1 - math.abs(self.Player.Velocity.Y)/self.Player.MaxSpeed.Y}, ("%0.2f"):format(self.Player.Velocity.Y), Constant.COLOR.WHITE, " }\n" ..
                                        "Force: V{ ", self.Player.Acceleration.X == 0 and Constant.COLOR.WHITE:AddAxis(0.5) or Constant.COLOR.PINK, ("%0.2f"):format(self.Player.Acceleration.X) .. ", ", self.Player.Acceleration.Y == 0 and (Constant.COLOR.WHITE:AddAxis(0.5) or true) or Constant.COLOR.PURPLE + 0.5, ("%0.2f"):format(self.Player.Acceleration.Y), Constant.COLOR.WHITE, " }\n"  ..
                                        "Floor:               ", self.Player.Floor and Constant.COLOR.GREEN or Constant.COLOR.RED + 0.5, tostring(self.Player.Floor or "NONE"), Constant.COLOR.WHITE, 
                                        "\nFramesSincePounce: ", self.Player.TimeSincePounce == -1 and Constant.COLOR.ORANGE or Constant.COLOR.RED + 0.8, self.Player.TimeSincePounce,
                                        Constant.COLOR.WHITE, "\nFramesSinceJump: ", self.Player.FramesSinceJump == -1 and Constant.COLOR.ORANGE or Constant.COLOR.BLUE + 0.8, self.Player.FramesSinceJump,
                                        Constant.COLOR.WHITE, "\nFramesSinceDoubleJump: ", self.Player.FramesSinceDoubleJump == -1 and Constant.COLOR.ORANGE or Constant.COLOR.GREEN + 0.8, self.Player.FramesSinceDoubleJump,
                                        Constant.COLOR.WHITE, "\nFramesSinceCrouch: ", self.Player.CrouchTime == 0 and Constant.COLOR.ORANGE or Constant.COLOR.PURPLE + 0.5, self.Player.CrouchTime,
                                        Constant.COLOR.WHITE, "\nFramesSinceRoll: ", self.Player.FramesSinceRoll == -1 and Constant.COLOR.ORANGE or Constant.COLOR.ORANGE + 0.5, self.Player.FramesSinceRoll,
                                        Constant.COLOR.WHITE, "\nLastRollPower: ", V{1, 1 - (self.Player.LastRollPower - 0.5) / self.Player.RollPower, 1 - self.Player.LastRollPower / self.Player.RollPower}, self.Player.LastRollPower,
                                        Constant.COLOR.WHITE, "\nFrameTime: ", Constant.COLOR.GREEN:Lerp(Constant.COLOR.RED, 1-curFpsRatio), ("%.2fms"):format(Chexcore._lastFrameTime*1000), V{1 ,self.lastFpsRatio, self.lastFpsRatio}, ("\n            (%05.1f%% target FPS)"):format(self.lastFpsRatio*100),
                                        Constant.COLOR.WHITE, "\nLOVE Drawcalls:                 ", V{0.5, 0.5, 1}, Chexcore._graphicsStats.drawcalls,
                                    
                                        
                                    }
           
        end
        
        if not self.InRespawn and self.Player.Position.Y > self.DeathHeight and self.Player.LastSafePosition then
            self.InRespawn = true
            self.fallGuiBottom.Visible = true
            self.fallGuiTop.Visible = true

            Timer.Schedule(0.5, function ()
                self.Player:Respawn(self.Player.LastSafePosition)
            end)

            Timer.Schedule(1.2, function ()
                self.InRespawn = false
                self.fallGuiBottom.Visible = false
                self.fallGuiTop.Visible = false
                self.fallGuiTop.Position = V{1280/2, 720}
                self.fallGuiBottom.Position = V{1280/2, 720*2}
                self.fallGuiTop.Rotation = 0
                self.fallGuiBottom.Rotation = math.rad(180)
            end)
            

        end

        if self.InRespawn then
            -- self.fallGuiTop.Rotation = self.fallGuiTop.Rotation + 0.002
            -- self.fallGuiBottom.Rotation = self.fallGuiBottom.Rotation - 0.002
            self.fallGuiTop.Position.Y = self.fallGuiTop.Position.Y - 35
            self.fallGuiBottom.Position.Y = self.fallGuiBottom.Position.Y - 35

            -- self.fallGuiTop.Size.Y = self.fallGuiTop.Size.Y + 5
        end
    end

    -- make sure gui layer is on top
    
    local guiID = self.GuiLayer:GetChildID()
    if guiID ~= #self._children then
        self:SwapChildOrder(guiID, #self._children)
    end

    return Scene.Update(self, dt)
end

return GameScene