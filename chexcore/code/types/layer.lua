local Layer = {
    -- properties

    Name = "Layer",
    Canvases = nil,         -- table of renderable canvases, created in constructor
    TranslationInfluence = 1,
    ZoomInfluence = 1,
    AutoClearCanvas = true,
    Static = false,         -- whether the top left corner of the canvas sits at V{0, 0} or not

    -- internal properties
    _delayedDrawcalls = {}, -- created in constructor
    _super = "Object",      -- Supertype
    _global = true
}

function Layer.new(properties, width, height, static)
    local newLayer = Layer:SuperInstance()
    if type(properties) == "table" then
        for prop, val in pairs(properties) do
            newLayer[prop] = val
        end
    elseif type(properties) == "string" then
        newLayer.Name = properties
        newLayer.Canvases = { Canvas.new(width, height) }
    end

    newLayer.Static = static
    newLayer.Canvases = newLayer.Canvases or {}
    newLayer._delayedDrawcalls = {}

    return Layer:Connect(newLayer)
end

-- default update pipeline for a Layer
function Layer:Update(dt)
    -- loop through each child
    for child in self:EachDescendant("Active", true) do
        child:Update(dt)
    end
end

-- the default rendering pipeline for a Layer
local lg = love.graphics
function Layer:Draw(tx, ty)
    -- tx, ty: translation values from camera (layers are responsible for handling this)

    -- default implementation is to draw all children to Canvases[1]
    self.Canvases[1]:Activate()

    if self.AutoClearCanvas then
        lg.clear()
    end
    
    -- love.graphics.setColor(1,1,1,1)
    -- love.graphics.rectangle("fill", 0, 0, 1920,1080)
    if self.Static then
        tx, ty = 0, 0
    elseif type(self.TranslationInfluence) == "table" then
        tx = tx * self.TranslationInfluence[1] - self.Canvases[1]:GetWidth()/2
        ty = ty * self.TranslationInfluence[2] - self.Canvases[1]:GetHeight()/2
    else 
        tx = tx * self.TranslationInfluence - self.Canvases[1]:GetWidth()/2
        ty = ty * self.TranslationInfluence - self.Canvases[1]:GetHeight()/2
    end
    
    

    -- loop through each Visible child
    for child in self:EachChild() do
        if child.Visible then
            if child.DrawInForeground then
                self:DelayDrawCall(child.ZIndex or 0, child.Draw, tx, ty, true)
                
            else
                child:Draw(tx, ty)
            end
            
        elseif child.DrawChildren then
            -- i don't know if this will work
            if child.DrawInForeground then
                self:DelayDrawCall(child.ZIndex or 0, child.DrawChildren, tx, ty)
            else
                child:DrawChildren(tx, ty)
            end
        end
    end

    -- catch any DelayDrawCall calls
    local delayedCallsList = {}
    for priority in pairs(self._delayedDrawcalls) do
        delayedCallsList[#delayedCallsList+1] = priority
    end
    table.sort(delayedCallsList)

    for _, priority in ipairs(delayedCallsList) do
        local callPairs = self._delayedDrawcalls[priority]
        for i = 1, #callPairs, 2 do
            callPairs[i](unpack(callPairs[i+1]))
        end
    end


    self._delayedDrawcalls = {}

    self.Canvases[1]:Deactivate()
end

-- a Prop can choose to delay its drawcall to be drawn after everything else in the Layer
function Layer:DelayDrawCall(priority, drawFunc, ...)
    local args = {...}
    self._delayedDrawcalls[priority] = self._delayedDrawcalls[priority] or {}
    local priorityTable = self._delayedDrawcalls[priority]
    priorityTable[#priorityTable+1] = drawFunc
    priorityTable[#priorityTable+1] = args
end

local In = Input
function Layer:GetMousePosition(canvasID)
    local normalizedPos, inWindow = In:GetMousePosition()
    local activeCanvasSize = self.Canvases[canvasID or 1]:GetSize()
    local cameraPosition = self.Static and activeCanvasSize/2 or self._parent.Camera.Position
    local cameraZoom = self._parent.Camera.Zoom
    local translationInfluence = self.TranslationInfluence
    local zoomInfluence = self.Static and 0 or self.ZoomInfluence
    local masterCanvasSize = self._parent.MasterCanvas:GetSize()
    
    local realScreenSize = getWindowSize()

    local screenToMasterRatio = 1/(masterCanvasSize:Ratio()/realScreenSize:Ratio())

    -- change mouse position normalization from (0,1) to (-0.5, 0.5)
    normalizedPos = (normalizedPos - 0.5)

    if screenToMasterRatio > 1 then -- increase y range for horizontal black bars
        normalizedPos[2] = normalizedPos[2] * screenToMasterRatio
    elseif screenToMasterRatio < 1 then -- increase x range for vertical black bars
        normalizedPos[1] = normalizedPos[1] / screenToMasterRatio
    end

    -- now we can actually use the normalizedPos of the mouse to find a spot onscreen
    local cameraSize = activeCanvasSize / ((cameraZoom-1) * zoomInfluence + 1)
    local finalPos = (cameraPosition * translationInfluence) + (normalizedPos * cameraSize)

    return finalPos, inWindow
end

return Layer