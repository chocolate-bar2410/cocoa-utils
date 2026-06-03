--[[

Copyright (c) 2026 chocolate_bar2410

This library is free software; you can redistribute it and/or modify it
under the terms of the MIT license. See LICENSE for details.

]]

local schema = {}
local interface = setmetatable({},{
    __index = function (self, index)
        if(index == "one") then
            return self.new(1,1)
        elseif(index == "zero") then
            return self.new(0,0)
        end

        return self[index]
    end


})

---@class vector
---@field X number
---@field Y number
---@field Magnitude number
---@field Unit vector
---@field Dot fun(self : vector,other : vector) : number
---@field Cross fun(self : vector,other : vector) : number
---@field Angle fun(self : vector,other : vector) : number
---@field Lerp fun(self : vector,other : vector,time : number) : vector
---@field Min fun(self : vector,other : vector) : vector
---@field Max fun(self : vector,other : vector) : vector
---@field Floor fun(self : vector) : vector
---@field Ceil fun(self : vector) : vector
---@field Abs fun(self : vector) : vector
---@field FuzzyEq fun(self : vector,other : vector,epsilon : number) : boolean
---@field Reflect fun(self : vector,normal : vector) : vector
---@field Unpack fun(self : vector) : number,number
---@field Clone fun(self : vector) : vector

local meta = {
    __index = function(self,index)
        if index == "Magnitude" then
            return math.sqrt(self:Dot(self))
        elseif index == "Perpendicular" then
            return interface.new(-self.Y,self.X) 
        elseif index == "Unit" then
            local length = math.sqrt(self:Dot(self))
            if length == 0 then return interface.new(0,0) end

            return interface.new(self.X / length,self.Y / length)
        end

        return schema[index]
    end,
    __tostring = function(self)
        return string.format("%f, %f",self.X,self.Y)
    end
}

---constructs a new vector
---@param x number
---@param y number
interface.new = function(x,y)
    local vector = {}
    vector.X = x
    vector.Y = y
    vector.Magnitude = nil          -- for type annotations 
    vector.Unit = nil               -- for type annotations 
    vector.Perpendicular = nil      -- for type annotations 

    return setmetatable(vector,meta)
end

interface.one = nil
interface.zero = nil

interface.IsVector = function(vector)
    return getmetatable(vector) == meta
end

--#region methods

---returns the dot product between 2 vectors
---@param self vector
---@param other vector
---@return number
function schema:Dot(other)
    return self.X * other.X + self.Y * other.Y
end

---returns the psuedo cross product between 2 vectors
---@param self vector
---@param other vector
---@return number
function schema:Cross(other)
    return self.X * other.Y - self.Y * other.X
end

---returns the angle between 2 vectors in radians
---@param self vector
---@param other vector
---@return number
function schema:Angle(other)
    if self.Magnitude * other.Magnitude == 0 then return 0 end

    return math.acos(self:Dot(other) / (self.Magnitude * other.Magnitude))
end

---interpolates between 2 vectors and returns a vector
---@param self vector
---@param other vector
---@param time number
---@return vector
function schema:Lerp(other,time)
    return self + time * (other - self)
end

---returns a vector of the minimum value of each component between 2 vectors
---@param self vector
---@param other vector
---@return vector
function schema:Min(other)
    return interface.new(math.min(self.X,other.X),math.min(self.Y,other.Y))
end

---returns a vector of the maximum value of each component between 2 vectors
---@param self vector
---@param other vector
---@return vector
function schema:Max(other)
    return interface.new(math.max(self.X,other.X),math.max(self.Y,other.Y))
end

---returns a vector of the floored values of the original's components
---@param self vector
---@return vector
function schema:Floor()
    return interface.new(math.floor(self.X),math.floor(self.Y))
end

---returns a vector of the Cieled values of the original's components
---@param self vector
---@return vector
function schema:Ceil()
    return interface.new(math.ceil(self.X),math.ceil(self.Y))
end

---returns a vector of the absolute values of the original's components
---@param self vector
---@return vector
function schema:Abs()
    return interface.new(math.abs(self.X),math.abs(self.Y))
end

---returns if 2 vectors's components are within epsilon range
---@param self vector
---@param other vector
---@param epsilon number
---@return boolean
function schema:FuzzyEq(other,epsilon)
    return math.abs(self.X - other.X) <= epsilon and math.abs(self.Y - other.Y) <= epsilon
end

---returns the vector that results when the original vector reflects off of the normal
---@param self vector
---@param normal vector
---@return vector
function schema:Reflect(normal)
    return self - 2 * (self:Dot(normal.Unit)) * normal.Unit
end

---returns a vector of the absolute values of the original's components
---@param self vector
---@return number x
---@return number y
function schema:Unpack()
    return self.X,self.Y
end

---returns a clone of a vector
---@param self vector
---@return vector
function schema:Clone()
    return interface.new(self.X,self.Y)
end


--#endregion

--#region metamethods

local function binary_op(self,other,callback)
    if(interface.IsVector(self) and interface.IsVector(other)) then
        return interface.new(callback(self.X,other.X),callback(self.Y,other.Y))
    end

    if(interface.IsVector(self) and tonumber(other)) then
        return interface.new(callback(self.X,other),callback(self.Y,other))
    end

    if(interface.IsVector(other) and tonumber(self)) then
        return interface.new(callback(self,other.X),callback(self,other.Y))
    end

    error(string.format("tried to do a operation between %s and %s",tostring(self),tostring(other)))
end


meta.__add = function (self,other)
    return binary_op(self,other,function(a,b)
        return a + b
    end)
end

meta.__sub = function (self,other)
    return binary_op(self,other,function(a,b)
        return a - b
    end)
end

meta.__mul = function (self,other)
    return binary_op(self,other,function(a,b)
        return a * b
    end)
end

meta.__div = function (self,other)
    return binary_op(self,other,function(a,b)
        return a / b
    end)
end

meta.__eq = function (self,other)
    return self.X == other.X and self.Y == other.Y
end

meta.__le = function (self,other)
    return self.X <= other.X and self.Y <= other.Y
end

meta.__unm = function (self)
    return interface.new(-self.X,-self.Y)
end

--#endregion

return interface