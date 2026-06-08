local interface = {}
local schema = {}
local meta = {
    __index = schema,
    __tostring = function(self)
        if self:empty() then
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
    if self:empty() then return end
    local result = self.data[self.min]
    self.data[self.min] = nil
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

---returns front item of queue
---@generic T
---@param self queue<T>
---@return T?
function schema:peek()
    if self:empty() then return end
    return self.data[self.min]
end

---returns size of queue
---@generic T
---@param self queue<T>
---@return T?
function schema:size()
    return math.max(self.max - self.min + 1,0)
end

---returns true/false depending on if the queue is empty
---@generic T
---@param self queue<T>
---@return T?
function schema:empty()
    return self.max - self.min < 0
end

---compacts queue into a smaller size
---@generic T
---@param self queue<T>
function schema:compact()
    if self:empty() then return end
    local size = self:size()

    for i = self.min, self.max do
        self.data[i - self.min + 1] = self.data[i]
        self.data[i] = nil
    end
    self.min = 1
    self.max = size

    print(size)
end

---@generic T
---@class queue<T>
---@field min number
---@field max number
---@field data T[]
---@field push fun(self : queue<T>,data : T)
---@field pop fun(self : queue<T>): T?
---@field peek fun(self : queue<T>): T?
---@field size fun(self : queue<T>): number
---@field empty fun(self : queue<T>): boolean
---@field compact fun(self : queue<T>)


return interface