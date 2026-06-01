local schema = {}
local interface = {}

---@class vector
---@field x number
---@field y number
---@field magnitude vector
---@field dot fun(self : vector,other : vector) : number
---@field cross fun(self : vector,other : vector) : number
---@field angle fun(self : vector,other : vector) : number
---@field lerp fun(self : vector,other : vector,time : number) : vector
local meta = {
    __index = function(self,index)
        if index == "magnitude" then
            return math.sqrt(self:dot(self))
        elseif index == "unit" then
            local length = math.sqrt(self:dot(self))
            if length == 0 then return interface.new(0,0) end

            return interface.new(self.x / length,self.y / length)
        end

        return schema[index]
    end
}

---constructs a new vector
---@param x number
---@param y number
interface.new = function(x,y)
    local vector = {}
    vector.x = x
    vector.y = y
    vector.magnitude = nil -- for type annotations 
    vector.unit = nil      -- for type annotations 

    return setmetatable(vector,meta)
end

interface.is_vector2 = function(vector)
    return getmetatable(vector) == meta
end

--#region methods

---returns the dot product between 2 vectors
---@param self vector
---@param other vector
---@return number
function schema:dot(other)
    return self.x * other.x + self.y * other.y
end

---returns the psuedo cross product between 2 vectors
---@param self vector
---@param other vector
---@return number
function schema:cross(other)
    return self.x * other.y - self.y * other.x
end

---returns the angle between 2 vectors in radians
---@param self vector
---@param other vector
---@return number
function schema:angle(other)
    return self:dot(other) / (self.magnitude * other.magnitude)
end

---interpolates between 2 vectors
---@param self vector
---@param other vector
---@param time number
---@return number
function schema:lerp(other,time)
    return self + time * (other - self)
end

--#endregion

--#region metamethods

local function binary_op(self,other,callback)
    if(interface.is_vector2(self) and interface.is_vector2(self)) then
        
    end
end

--#endregion

return interface