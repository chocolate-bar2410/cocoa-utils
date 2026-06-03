--[[

Copyright (c) 2026 chocolate_bar2410

This library is free software; you can redistribute it and/or modify it
under the terms of the MIT license. See LICENSE for details.

]]

local interface = {}

local function canClone(item)
    if item["Clone"] ~= nil or item["clone"] ~= nil then
        return true
    end

    return type(item) == "table"
end

---copies a object
---@generic T
---@param tab T
---@return T
local function clone(tab)

    if type(tab) == "number" or type(tab) == "userdata" then
        return tab
    end

    if not canClone(tab) then
        error("spring input type must have clone method")
    end
    

    return (tab["Clone"] or tab["clone"])(tab)
end

local verletSchema = {}

---@generic T
---@class verletSpring<T>
---@field Position T
---@field PreviousPosition T
---@field Goal T
---@field Damping number
---@field Stiffness number
---@field Update fun(self : verletSpring<T>, deltatime : number): nil

local verletMeta = {__index = verletSchema}

---constructs new verlet spring
---@generic T
---@param position T
---@param goal T
---@param damping number
---@param stiffness number
---@return verletSpring<T>
interface.verletSpring = function(goal,position,stiffness,damping)
    local spring = {}
    spring.Position = position
    spring.PreviousPosition = clone(position)
    spring.Goal = goal

    spring.Damping = damping
    spring.Stiffness = stiffness

    return setmetatable(spring,verletMeta)
end

---updates verlet spring
---@param self verletSpring
---@param deltatime number
function verletSchema:Update(deltatime)
    local velocity = (self.Position - self.PreviousPosition) * self.Damping
    local displacement = self.Goal - self.Position
    local acceleration = displacement * self.Stiffness

    self.PreviousPosition = clone(self.Position)

    self.Position = self.Position + velocity + (acceleration * deltatime)
end

local eulerSchema = {}

---@generic T
---@class eulerSpring<T>
---@field Position T
---@field Velocity T
---@field Goal T
---@field PreviousGoal T
---@field K1 number
---@field K2 number
---@field K3 number
---@field Frequency number
---@field Damping number
---@field Response number
---@field Update fun(self : eulerSpring<T>, deltatime : number): nil

local eulerMeta = {
    __index = function(self,index)

        if index == "Frequency" then
            return 1 / (2 * math.pi * math.sqrt(self.K2))
        end

        if index == "Damping" then
            return self.K1 / (2 * math.sqrt(self.K2))
        end

        if index == "Response" then
            return 2 * self.K3 / self.K1
        end        

        return eulerSchema[index]
    end,

    ---@param self eulerSpring
    ---@param index any
    ---@param value any
    __newindex = function(self,index,value)
        if index == "Frequency" then
            local damping = self.K1 / (2 * math.sqrt(self.K2))
            local response = 2 * self.K3 / self.K1

            rawset(self,"K1",damping / (value * math.pi))
            rawset(self,"K2",1 / ((2 * value * math.pi) ^ 2))
            rawset(self,"K3",(response * damping) / (2 * value * math.pi))
            return
        end

        if index == "Damping" then
            local frequency = 1 / (2 * math.pi * math.sqrt(self.K2))
            local response = 2 * self.K3 / self.K1

            rawset(self,"K1",value / (frequency * math.pi))
            rawset(self,"K2",1 / ((2 * frequency * math.pi) ^ 2))
            rawset(self,"K3",(response * value) / (2 * frequency * math.pi))
            return
        end

        if index == "Response" then
            local frequency = 1 / (2 * math.pi * math.sqrt(self.K2))
            local damping = self.K1 / (2 * math.sqrt(self.K2))

            rawset(self,"K3",(value * damping) / (2 * frequency * math.pi))
            return
        end


        rawset(self,index,value)
    end
}

---constructs a euler spring
---@generic T
---@param goal T
---@param position T
---@param frequency number
---@param damping number
---@param response number
---@return eulerSpring<T>
interface.eulerSpring = function(goal,position,velocity_0,frequency,damping,response)
    local spring = {}
    spring.Position = position
    spring.Velocity = velocity_0

    spring.Goal = goal
    spring.PreviousGoal = clone(goal)

    spring.K1 = damping / (frequency * math.pi)
    spring.K2 = 1 / ((2 * frequency * math.pi) ^ 2)
    spring.K3 = (response * damping) / (2 * frequency * math.pi)

    spring.Frequency = nil
    spring.Damping = nil
    spring.Response = nil

    return setmetatable(spring,eulerMeta)
end

---updates euler spring
---@param self eulerSpring
---@param deltatime number
function eulerSchema:Update(deltatime)
    local velocity = (self.Goal - self.PreviousGoal) / deltatime

    -- stabilises by clamping k2 and preventing negative eigen values
    local k2_stable = math.max(self.K2,deltatime * deltatime / 2 + deltatime * self.K1 / 2,deltatime * self.K1)

    self.Velocity = self.Velocity + (self.Goal + self.K3 * velocity - self.Position - self.K1 * self.Velocity) * deltatime / k2_stable
    self.Position = self.Position + self.Velocity * deltatime

    self.PreviousGoal = clone(self.Goal)
end

interface.smoothDamp = function(goal,position,velocity_0)
    return interface.eulerSpring(goal,position,velocity_0,1,1,0)
end

interface.stiff = function(goal,position,velocity_0)
    return interface.eulerSpring(goal,position,velocity_0,7,0.4,0)
end

interface.bouncy = function(goal,position,velocity_0)
    return interface.eulerSpring(goal,position,velocity_0,5,0.1,0)
end

return interface