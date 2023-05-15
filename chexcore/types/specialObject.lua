local SpecialObject = {
    -- properties
    Name = "SpecialObject",        -- Easy identifier

    -- internal properties
    _super = "Object",      -- Supertype
    _global = true
}
SpecialObject.__index = SpecialObject

---------------- Constructor -------------------
function SpecialObject.new()
    local myObj = SpecialObject:SuperInstance()
    
    return setmetatable(myObj, SpecialObject)
end
------------------------------------------------

------------------ Methods ---------------------
function SpecialObject:Meow()
    print("meow!")
end
----------------------------------------

return SpecialObject