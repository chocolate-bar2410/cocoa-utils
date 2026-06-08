local interface = {}
local schema = {}
local meta = {
    __index = schema,
    __tostring = function(self)
        if self.min > self.max then
            return "queue<0>:[]"
        end

        local result = ""
        for i = self.min,self.max do
            result = result .. self.data[i] .. " "
        end

        result = result:sub(1,result:len() - 1)

        return string.format("queue<%d>:[%s]",(self.max - self.min) + 1,result)
    end
}

---creates a new queue
---@generic T
---@return queue<T>
interface.new = function()
    local queue = {}
    queue.min = 1
    queue.max = 0
    queue.data = {}

    return setmetatable(queue,meta)
end

---dequeues item from queue
---@generic T
---@param self queue<T>
---@return T?
function schema:pop()
    if self.max < self.min then return end
    local result = self.data[self.min]
    self.min = self.min + 1

    return result
end

---enqueues item into queue
---@generic T
---@param self queue<T>
---@param value T
function schema:push(value)
    self.max = self.max + 1
    self.data[self.max] = value
    
end

---@generic T
---@class queue<T>
---@field min number
---@field max number
---@field data T[]
---@field push fun(self : queue<T>,data : T)
---@field pop fun(self : queue<T>): T?


return interface