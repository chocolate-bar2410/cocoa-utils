local interface = {}
local schema = {}

---@class colour
---@field R number
---@field G number
---@field B number
---@field A number
---@field ToHex fun(self : colour): string
---@field ToHSV fun(self : colour): number,number,number
---@field Unpack fun(self : colour): number,number,number,number
local meta = {
    __index = schema,
    __tostring = function(self)
        return string.format("%.2f, %.2f, %.2f, %.2f",self.R,self.G,self.B,self.A)
    end
}

local function clamp(x,min,max) 
    if x == nil then return max end
    return math.min(math.max(x,min),max) 
end

---constructs a new colour
---@param r number
---@param g number
---@param b number
---@param a number
---@return colour
interface.new = function(r,g,b,a)
    r = clamp(r,0,1)
    g = clamp(g,0,1)
    b = clamp(b,0,1)
    a = clamp(a,0,1)

    local colour = {}
    colour.R = r
    colour.G = g
    colour.B = b
    colour.A = a

    return setmetatable(colour,meta)
end

---creates a colour from a hex string and alpha value from 0 - 1
---@param hexstring string
---@param alpha number
---@return colour
interface.fromHex = function(hexstring,alpha)
    if hexstring:sub(1,1) == "#" then
        hexstring = hexstring:sub(2,hexstring:len())
    end

    local r = tonumber(hexstring:sub(1,2),16) / 255
    local g = tonumber(hexstring:sub(3,4),16) / 255
    local b = tonumber(hexstring:sub(5,6),16) / 255

    return interface.new(r,g,b,alpha)
end

---creates a colour from rgba values from 0 - 255
---@param r number
---@param g number
---@param b number
---@param a number
---@return colour
interface.fromRGBA = function(r,g,b,a)
    r = clamp(r,0,255)
    g = clamp(g,0,255)
    b = clamp(b,0,255)
    a = clamp(a,0,255)

    return interface.new(r / 255,g / 255,b / 255,a / 255)
end

---creates a colour from hue(0 - 360), saturation, value and alpha
---@param hue any
---@param saturation any
---@param value any
---@param alpha any
---@return colour
interface.fromHSVA = function(hue, saturation, value, alpha)
    hue = clamp(hue,0,360)
    saturation = clamp(saturation,0,1)
    value = clamp(value,0,1)

    if(saturation == 0) then
        return interface.new(value,value,value,alpha)
    end

    local hue_prime = hue / 60
    local sector = math.floor(hue_prime) % 6
    local fractional = hue_prime - sector

    local v1 = value * (1 - saturation)
    local v2 = value * (1 - saturation * fractional)
    local v3 = value * (1 - saturation * (1 - fractional))

    if     sector == 0 then return interface.new(value, v3,    v1,    alpha)
    elseif sector == 1 then return interface.new(v2,    value, v1,    alpha)
    elseif sector == 2 then return interface.new(v1,    value, v3,    alpha)
    elseif sector == 3 then return interface.new(v1,    v2,    value, alpha)
    elseif sector == 4 then return interface.new(v3,    v1,    value, alpha)
    elseif sector == 5 then return interface.new(value, v1,    v2,    alpha)
    end

    error("invalid parameters")
    return interface.new(0,0,0,0)
end

---returns a hex string
---@param self colour
---@return string
function schema:ToHex()
    return string.format("#%02X%02X%02X",self.R * 255,self.G * 255,self.B * 255)
end

---returns values for hue, saturation and value
---@param self colour
---@return number hue
---@return number saturation
---@return number value
function schema:ToHSV()
    local min = math.min(self.R,self.G,self.B)
    local max = math.max(self.R,self.G,self.B)
    local chroma = max - min

    local hue = 0
    local saturation = 0
    local value = max

    if value > 0 then
        saturation = chroma / value
    end


    if chroma <= 0 then return hue, saturation,value end

    if max == self.R then hue = ((self.G - self.B) / chroma) % 6
    elseif max == self.G then hue = ((self.B - self.R) / chroma) + 2
    elseif max == self.B then hue = ((self.R - self.G) / chroma) + 4
        
    end

    hue = hue * 60
    if hue < 0 then hue = hue + 360 end

    hue = math.ceil(hue)

    return hue, saturation, value
end

---returns values for hue, saturation and value
---@param self colour
---@return number r
---@return number g
---@return number b
---@return number a
function schema:Unpack()
    return self.R,self.G,self.B,self.A
end


return interface