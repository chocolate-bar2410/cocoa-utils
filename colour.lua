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
---@field Invert fun(self : colour): colour
---@field HueInvert fun(self : colour): colour
---@field HSVGreyScale fun(self : colour): colour
---@field Luminance fun(self : colour): colour
---@field Lerp fun(self : colour,other : colour,t : number): colour
---@field HSVLerp fun(self : colour,other : colour,t : number): colour
---@field HueShift fun(self : colour,hue : number): colour
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

--#region constructors

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

--#endregion

--#region methods

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

---returns a inverted version of the original colour
---@param self colour
---@return colour
function schema:Invert()
    return interface.new(1 - self.R,1 - self.G,1 - self.B,self.A)
end

---returns a version of the original colour with the hue inverted
---@param self colour
---@return colour
function schema:HueInvert()
    local hue,saturation,value = self:ToHSV()
    return interface.fromHSVA(360 - hue,saturation,value,self.A)
end

---returns a greyscale version of the original colour using HSV
---@param self colour
---@return colour
function schema:HSVGreyScale()
    local hue,saturation,value = self:ToHSV()
    return interface.fromHSVA(hue,0,value,self.A)
end

---returns a greyscale colour representing luminance
---@param self colour
---@return colour
function schema:Luminance()
    local luminance = 0.2126 * self.R + 0.7152 * self.G + 0.0722 * self.B
    return interface.new(luminance,luminance,luminance,self.A)
end

---interpolates between 2 colours and returns the result
---@param other colour
---@param t number
---@return colour
function schema:Lerp(other,t)
    local R = self.R + t * (other.R - self.R)
    local B = self.B + t * (other.B - self.B)
    local G = self.G + t * (other.G - self.G)
    local A = self.A + t * (other.A - self.A)

    return interface.new(R,G,B,A)
end

---interpolates between 2 colours and returns the result using HSV
---@param other colour
---@param t number
---@return colour
function schema:HSVLerp(other,t)
    local H1,S1,V1 = self:ToHSV()
    local H2,S2,V2 = other:ToHSV()


    local H = ((H2 - H1 + 180) % 360) - 180
    local S = S1 + t * (S2 - S1)
    local V = V1 + t * (V2 - V1)

    H = (H1 + H * t) % 360

    local A = self.A + t * (other.A - self.A)

    return interface.fromHSVA(H,S,V,A)
end

function schema:HueShift(hue)
    local H,S,V = self:ToHSV()
    return interface.fromHSVA((H + hue) % 360,S,V,self.A)
end


--#endregion

--#region metamethods

meta.__add = function(self,other)
    return interface.new(
        self.R + other.R,
        self.G + other.G,
        self.B + other.B,
        self.A
    )
end

meta.__sub = function(self,other)
    return interface.new(
        self.R - other.R,
        self.G - other.G,
        self.B - other.B,
        self.A
    )
end

meta.__mul = function(self,other)
    return interface.new(
        self.R * other.R,
        self.G * other.G,
        self.B * other.B,
        self.A * other.A
    )
end

meta.__div = function(self,other)
    return interface.new(
        self.R * other.alpha / other.R,
        self.G * other.alpha / other.G,
        self.B * other.alpha / other.B,
        self.A
    )
end



--#region


return interface