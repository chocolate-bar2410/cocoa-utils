--[[

Copyright (c) 2026 chocolate_bar2410

This library is free software; you can redistribute it and/or modify it
under the terms of the MIT license. See LICENSE for details.

]]

local interface = {}
local schema = {}
local easingFunctions = {}
local easingDirections = {}

local meta = {__index = schema}

local lerp = function(a,b,t)
    return a + t * (b - a)
end

---copies a object
---@generic T
---@param tab T
---@return T
local function clone(tab)
    if tab["Clone"] ~= nil or tab["clone"] ~= nil then
        return (tab["Clone"] or tab["clone"])(tab)
    end
    
    local result = {}

    for i,v in pairs(tab) do
        if type(v) == "table" then
            result[i] = clone(v)
        else
            result[i] = v
        end
    end

    return result
end

---construct a new tween with a tweening function
---@generic T
---@param target T
---@param duration number
---@param tweenvariables table<string, any>
---@param easingfunction fun(t : number): number
---@return tween
interface.new = function(target,duration,tweenvariables,easingfunction)
    local tween = {}
    tween.Completed = false
    tween.Time = 0
    tween.Duration = duration
    tween.Target = target
    tween.TweenVariables = tweenvariables
    tween._EasingFunction = easingfunction
    tween._OnComplete = nil

    tween.Origin = clone(target)

    return setmetatable(tween,meta)
end

---constructs a tween with a easing style and easing direction
---@generic T
---@param target T
---@param duration number
---@param tweenvariables table<string, any>
---@param easingstyle EasingStyle
---@param easingdirection EasingDirection?
---@return tween
interface.fromEasing = function(target,duration,tweenvariables,easingstyle,easingdirection)
    easingstyle = easingstyle or "Linear"
    easingdirection = easingdirection or "In"
    local easingFunction = easingFunctions[easingstyle]

    if easingstyle ~= "Linear" and easingdirection ~= "In" then
        easingFunction = easingDirections[easingdirection](easingFunction)
    end

    return interface.new(target,duration,tweenvariables,easingFunction)
end

---updates tween
---@param self tween
---@param deltatime number
function schema:Update(deltatime)
    if self.Completed then return end
    self.Time = self.Time + deltatime
    self.Time = math.min(self.Time,self.Duration)

    if self.Time >= self.Duration then
        self.Completed = true
        if self._OnComplete then self._OnComplete() end
    end

    local eased_time = self._EasingFunction(self.Time / self.Duration)

    for index, value in pairs(self.TweenVariables) do
        self.Target[index] = lerp(self.Origin[index],value,eased_time)
    end

end

---resets tween
---@param self tween
function schema:Reset()
    for index, value in pairs(self.TweenVariables) do
        self.Target[index] = self.Origin[index]
    end
    self.Completed = false
    self.Time = 0
end

---resets tween
---@param self tween
---@param callback fun(): nil
function schema:OnComplete(callback)
    self._OnComplete = callback

    return self
end



easingFunctions = {
    ["Sine"] = function(t)
        return 1 - math.cos((t * math.pi) / 2);
    end,
    ["Quad"] = function(t)
        return t ^ 2
    end,

    ["Cubic"] = function(t)
    return t * t * t
    end,
    ["Quart"] = function(t)
        return t * t * t * t
    end,
    ["Quint"] = function(t)
        return t * t * t * t * t
    end,
    ["Expo"] = function(t)
        return t == 0 and 0 or 2 ^ (10 * t - 10)
    end,
    ["Circ"] = function(t)
        return 1 - math.sqrt(1 - t ^ 2)
    end,
    ["Back"] = function(t)
        local c1 = 1.70158
        local c3 = c1 + 1
        return c3 * t * t * t - c1 * t * t
    end,
    ["Elastic"] = function(t)
        local c4 = 2 * math.pi / 3
        return t == 0 and 0 or (t == 1 and 1 or -2 ^ (10 * t - 10) * math.sin((t * 10 - 10.75) * c4))
    end,
    ["Bounce"] = function(t)
        t = 1 - t
        local n1 = 7.5625
        local d1 = 2.75
        if t < 1 / d1 then
            return 1 - n1 * t * t
        elseif t < 2 / d1 then
            t = t - 1.5 / d1
            return 1 - (n1 * t * t + 0.75)
        elseif t < 2.5 / d1 then
            t = t - 2.25 / d1
            return 1 - (n1 * t * t + 0.9375)
        else
            t = t - 2.625 / d1
            return 1 - (n1 * t * t + 0.984375)
        end
    end,
}

easingDirections = {
    ["In"] = function(ease)
        return ease
    end,
    ["Out"] = function(ease)
        return function(t) 
            return 1 - ease(1 - t) 
        end
    end,
    ["InOut"] = function(ease)
        return function(t) 
            return t < 0.5 
                and ease(2 * t) / 2
                or  1 - ease(2 - 2 * t) / 2
        end
    end,
    ["OutIn"] = function(ease)
        return function(t) 
            return t < 0.5 
                and (1 - ease(1 - t * 2)) / 2 
                or  (1 + ease(2 * t - 1)) / 2
        end
    end
}


---@alias EasingDirection "In" | "Out" | "InOut" | "OutIn"
---@alias EasingStyle "Linear" | "Sine" | "Quad" | "Cubic" | "Quart" | "Quint" | "Expo" | "Circ" | "Back" | "Elastic" | "Bounce"

---@generic T
---@class tween<T>
---@field Completed boolean
---@field Time number
---@field Duration number
---@field Target T
---@field TweenVariables table<string, any>
---@field _EasingFunction fun(t : number): number
---@field _OnComplete fun(): nil
---@field Update fun(self : tween,deltatime : number): nil
---@field Reset fun(self : tween): nil
---@field OnComplete fun(self : tween, callback : fun()): tween<T>
---@field Origin T

return interface