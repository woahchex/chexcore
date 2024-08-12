-- CHEXCORE EXAMPLE SCENE

-- create a Scene with this syntax:
local scene = Scene.new()

-- Scenes need to have at least one Layer to do anything!
local layer = Layer.new("exampleLayer", 1280, 720) -- specify the Name, and pixel width/height
-- attach the Layer to the Scene:
scene:Adopt(layer)

-- Scenes are made with a Camera object by default; let's focus our camera such that
-- the center of the screen is at position (500, 500):
local camPos = V{500, 500} -- Vectors are written in the format V{a, b, c, ...}
                              -- This is just a simple 2D vector for the Camera's Position.
scene.Camera.Position = camPos
scene.Camera.Zoom = 1
layer.ZoomInfluence = 1
layer.TranslationInfluence = 1
layer.AutoClearCanvas = true
-- Now that the Scene is ready, let's put something visible in; generally we use "props" for this.
-- Our code could look like this:
---  local prop = Prop.new()
---  layer:Adopt(prop)
-- however, we can use a shorthand to write this in one line:
local logo = layer:Adopt( Prop.new() )
logo.Visible = true

-- let's position the Prop so it's in the center of the Camera view we set up earlier:
logo.Position = V{500, 500}

-- we're going to give this Prop an an animated texture using a spritesheet.
-- first, we'll set the Prop to the same size as its texture (in this case, 750x300):
logo.Size = V{750, 300}

-- if you ran the scene up to this point, the prop would appear (with a default texture)
-- and it would be a little down and to the right, even though its position is the same as the Camera's.
-- this is because the engine needs to make a decision about what point on a Prop is considered the
-- "root" point of that Prop, the point whose position is actually set when updating the field.
-- Chexcore makes this decision using an "AnchorPoint" field on Props.
-- by default, the AnchorPoint is set to V{0,0}, putting the root at the top-left corner of the Prop.
-- We want our Prop's center to be its "root" point, so we'll set the AnchorPoint to 
-- 50% to the right and 50% down, or V{0.5, 0.5}
logo.AnchorPoint = V{0.5, 0.5}

-- now, we'll apply the texture. There is a simple "Texture" class we could apply, but
-- since we're using an animated texture, we'll be using the Animation class:
logo.Texture = Animation.new("chexcore/assets/images/flashinglogo.png", 1,         2) 
                            -- spritesheet path,                        rowCount,  columnCount

-- we'll set our animation to loop once every 2 seconds:
logo.Texture.Duration = 2



-- let's play around with some functionality!
-- you can add an update routine to any Prop by setting a function to its "Update" field:
function logo:Update(dt)
    -- let's have our image do some funky little rotation action:
    -- Chexcore._clock will always return how many seconds Chexcore has been running
    local lifetime = Chexcore._clock * 2 -- multiply by 2 to increase rotation speed

    -- we'll just set our image to rotate along the sine wave of the Chexcore's clock:
    self.Rotation = math.sin(lifetime) / 8 -- divide by 8 so it only rotates a little bit

    -- let's have our object be attracted to the mouse:
    local mousePos, inWindow = Input.GetMousePosition()
    -- mousePos is a 2D Vector normalized from 0-1. inWindow shows whether Chexcore thinks 
    -- the mouse has gone off the screen, but it doesn't know for sure.
    
    -- we'll place the new position of our object based on its origin:
    local goalPos = V{500, 500}

    if inWindow then
        -- right now, mousePos is normalized in the 0-1 range. 
        -- first we'll re-normalize the center to be 0 instead of 0.5.
        mousePos = mousePos - 0.5  -- this will subtract 0.5 from every axis of mousePos
        -- then we'll scale mousePos up so the range is (-100) to (100).
        mousePos = mousePos * 200  -- this will multiply every axis by 200.
        -- finally, apply the transformation to the goal position
        goalPos = goalPos + mousePos
    end

    -- we could set the position directly, but to make it look smoother, we'll 
    -- interpolate to some point in the middle
    local progress = 6*dt -- "dt" is the delta time from the last frame, a small fraction of a second
                          -- using this number lets us move at the same speed across different fps

    -- Vector1:Lerp(Vector2, distance)
    self.Position = self.Position:Lerp(goalPos, progress)

    
end

local cursor = layer:Adopt(Prop.new{
    Name = "Cursor",
    AnchorPoint = V{0.5, 0.5},
    Position = V{500,500},
    Size = V{100,100},
    Update = function(self, dt)
        self.Position = self.Position:Lerp(self:GetParent():GetMousePosition(), 25*dt)
        self.Rotation = self.Rotation + dt
        self.Size = V{50,50} + math.sin(Chexcore._clock*2)*25
    end
})

print(logo:ToString(true))

return scene