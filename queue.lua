local interface = {}
local schema = {}
local meta = {
    __index = schema
}

---creates a new queue
---@generic T
---@return queue<T>
interface.new = function()
    local queue = {}
    queue.min = 1
    queue.max = 1
    queue.size = 0
    queue.data = {}

    return setmetatable(queue,meta)
end

---dequeues item from queue
---@generic T
---@param self queue<T>
---@return T
function schema:pop()
    if self.size == 0 then return end
    local result = self.data[self.min]
    self.min = self.min + 1

    self.size = self.size - 1

    return result
end

---enqueues item into queue
---@generic T
---@param self queue<T>
---@param value T
function schema:push(value)
    self.data[self.max] = value
    self.max = self.max + 1
    self.size = self.size + 1
end

---@generic T
---@class queue<T>
---@field min number
---@field max number
---@field size number
---@field data T[]
---@field push fun(self : queue<T>,data : T)
---@field pop fun(self : queue<T>): T


return interface