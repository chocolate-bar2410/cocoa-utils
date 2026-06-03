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
    

    if tab["Clone"] ~= nil or tab["clone"] ~= nil then
        return (tab["Clone"] or tab["clone"])(tab)
    end

    local result = {}

    for i,v in tab do
        result[i] = v
    end

    return result
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
---@field Update fun(self : eulerSpring<T>, deltatime : number): nil
local eulerMeta = {
    __index = function(self,index)
        return eulerSchema[index]
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
interface.eulerSpring = function(goal,position,initvelocity,frequency,damping,response)
    local spring = {}
    spring.Position = position
    spring.Velocity = initvelocity

    spring.Goal = goal
    spring.PreviousGoal = clone(goal)

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

    self.Velocity = self.Velocity + (self.Goal + self.K3 * velocity - self.Position - self.K1 * self.Velocity) * deltatime / k2_stable
    self.Position = self.Position + self.Velocity * deltatime
    
    self.PreviousGoal = clone(self.Goal)
end


return interface