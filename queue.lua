--[[

Copyright (c) 2026 chocolate_bar2410

This library is free software; you can redistribute it and/or modify it
under the terms of the MIT license. See LICENSE for details.

]]

local interface = {}
local schema = {
    _OFFSET_THRESHOLD = 10
}
local meta = {
    __index = schema,
    __tostring = function(self)
        if self:empty() then
            return "queue<0>:[]"
        end

        local result = ""
        for i = self.min,self.max do
            result = result .. tostring(self.data[i]) .. " "
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

    if self.min > schema._OFFSET_THRESHOLD then
        self:_compact()
    end

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
---@return number?
function schema:size()
    return math.max(self.max - self.min + 1,0)
end

---returns true/false depending on if the queue is empty
---@generic T
---@param self queue<T>
---@return boolean?
function schema:empty()
    return self.max - self.min < 0
end

---compacts queue into a smaller size
---@generic T
---@param self queue<T>
---@private
function schema:_compact()
    if self:empty() then return end
    local size = self:size()

    local new_data = {}

    for i = self.min, self.max do
        table.insert(new_data, self.data[i])
    end

    self.min = 1
    self.max = size
    self.data = new_data
end

function schema:iterate()
    local index = 0
    local size = self:size()

    local min = self.min
    local max = self.max

    return function()
        local current = index + min
        if current > max then return end
        local value = self.data[current]

        index = index + 1

        return index,value
    end
end

---@generic T
---@class queue<T>
---@field min number
---@field max number
---@field data T[]
---@field _OFFSET_THRESHOLD number
---@field push fun(self : queue<T>,data : T)
---@field pop fun(self : queue<T>): T?
---@field peek fun(self : queue<T>): T?
---@field size fun(self : queue<T>): number
---@field empty fun(self : queue<T>): boolean
---@field private _compact fun(self : queue<T>)
---@field iterate fun(self : queue<T>): fun(): number,T


return interface