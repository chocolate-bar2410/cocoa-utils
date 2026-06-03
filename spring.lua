local interface = {}

---comment
---@param tab table
---@return table
local function clone(tab) -- surface level copy
    local result = {}

    for i,v in tab do
        result[i] = v
    end

    return result
end

local function canClone(item)
    if item["Clone"] ~= nil and item["clone"] ~= nil then
        return true
    end

    return type(item) == "table"
end

local verletSchema = {}
local verletMeta = {__index = verletSchema}

interface.verletSpring = function(goal,position)
    local spring = {}
    spring.Position = position
    spring.PreviousPosition = position
    spring.Goal = goal


    return setmetatable(spring,verletMeta)
end

function verletSchema:update(d_time)
    
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
---@field Update fun(self : eulerSpring, deltatime : number): nil
local eulerMeta = {__index = eulerSchema}

---constructs a euler spring
---@generic T
---@param goal T
---@param position T
---@param frequency number
---@param damping number
---@param response number
---@return eulerSpring<T>
interface.eulerSpring = function(goal,position,initvelocity,frequency,damping,response)
    local spring = {}
    spring.Position = position
    spring.Velocity = initvelocity

    spring.Goal = goal
    spring.PreviousGoal = goal

    spring.K1 = damping / (frequency * math.pi)
    spring.K2 = 1 / ((2 * frequency * math.pi) ^ 2)
    spring.K3 = (response * damping) / (2 * frequency * math.pi)

    return setmetatable(spring,eulerMeta)
end

---updates euler spring
---@param self eulerSpring
---@param deltatime number
function eulerSchema:Update(deltatime)
    local velocity = (self.Goal - self.PreviousGoal) / deltatime

    -- stabilises by clamping k2 and preventing negative eigen values
    local k2_stable = math.max(self.K2,deltatime * deltatime / 2 + deltatime * self.K1 / 2,deltatime * self.K1)

    self.Position = self.Position + self.Velocity * deltatime
    self.Velocity = self.Velocity + (self.Goal + self.K3 * velocity - self.Position - self.K1 * self.Velocity) * deltatime / k2_stable

    if type(self.PreviousGoal) == "number" then
        self.PreviousGoal = self.Goal
        return
    end

    if not canClone(self.Goal) then
        error("spring input type must have clone method")
    end
    
    if self.Goal["Clone"] ~= nil or self.Goal["clone"] ~= nil then
        self.PreviousGoal = (self.Goal["Clone"] or self.Goal["clone"])(self.Goal)
    else
        self.PreviousGoal = clone(self.Goal)
    end
    
end


return interface