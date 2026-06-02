local interface = {}
local schema = {}

---@class colour
---@field R number
---@field G number
---@field B number
---@field A number
---@field ToHex fun(self : colour): string
---@field ToHSV fun(self : colour): number,number,number
---@field ToOKLCH fun(self : colour): number,number,number
---@field Unpack fun(self : colour): number,number,number,number
---@field Clone fun(self : colour): colour
---@field Invert fun(self : colour): colour
---@field HueInvert fun(self : colour): colour
---@field HSVGreyScale fun(self : colour): colour
---@field Luminance fun(self : colour): colour
---@field Lerp fun(self : colour,other : colour,t : number): colour
---@field HSVLerp fun(self : colour,other : colour,t : number): colour
---@field HueShift fun(self : colour,hue : number): colour
---@field SaturationShift fun(self : colour,hue : number): colour
---@field BrightnessShift fun(self : colour,hue : number): colour
---@field Complementary fun(self : colour): colour
---@field Analogous fun(self : colour,layer : number): colour[]
---@field Triadic fun(self : colour): colour,colour
---@field SplitComplementary fun(self : colour): colour,colour
local meta = {
    __index = schema,
    __tostring = function(self)
        return string.format("%.2f, %.2f, %.2f, %.2f",self.R,self.G,self.B,self.A)
    end
}

--#region helper functions
local function clamp(x,min,max) 
    if x == nil then return max end
    return math.min(math.max(x,min),max) 
end

local function toSRGB(c)
    if c <= 0.0031308 then
        return 12.92 * c
    else
        return 1.055 * (c ^ (1/2.4)) - 0.055
    end
end

local function toLinearRGB(c)
    if c <= 0.04045 then
        return c / 12.92
    else
        return ((c + 0.055) / 1.055) ^ 2.4
    end
end

local function adaptiveHueShift(H, C, baseshift)
    local Cmax = 0.32
    local factor = math.exp(-2 * (C / Cmax))
    local shift = baseshift * factor

    if shift < 0 and (H >= 270 and H <= 315) then
        shift = shift * 0.5 
    end

    return (H + shift) % 360
end

local function atan2(y, x)
    if x > 0 then
        return math.atan(y / x)
    elseif x < 0 then
        return math.atan(y / x) + (y >= 0 and math.pi or -math.pi)
    elseif y > 0 then
        return math.pi / 2
    elseif y < 0 then
        return -math.pi / 2
    else
        return 0
    end
end

-- for OKLAB gamut clipping
local function find_cusp(a,b)
    local hr = atan2(b,a)

    local l_cusp = 0.5 + 0.3 * math.cos(hr) - 0.09 * math.sin(hr)
    local c_cusp = 0.3 + 0.1 * math.cos(hr) + 0.05 * math.sin(hr)

    return l_cusp, c_cusp
end

local function oklab_clip(lightness,chroma,a,b)

    local l = (lightness + 0.3963377774 * a + 0.2158037573 * b) ^ 3
    local m = (lightness - 0.1055613458 * a - 0.0638541728 * b) ^ 3
    local s = (lightness - 0.0894841775 * a - 1.2914855480 * b) ^ 3

    local R = 4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s
    local G = -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s
    local B = -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s

    if R >= 0 and R <= 1 and G >= 0 and G <= 1 and B >= 0 and B <= 1 then
        return R,G,B
    end

    local l_cusp ,c_cusp  = find_cusp(a,b)

    local t = 0
    if lightness < l_cusp then
        t = (lightness * c_cusp) / (chroma * l_cusp + lightness * (c_cusp - chroma))
    else
        t = ((1 - lightness) * c_cusp) / (chroma * (1 - l_cusp) + (1 - lightness) * (c_cusp - chroma))
    end

    t = clamp(t,0,1)

    a = a * t
    b = b * t

    local l = (lightness + 0.3963377774 * a + 0.2158037573 * b) ^ 3
    local m = (lightness - 0.1055613458 * a - 0.0638541728 * b) ^ 3
    local s = (lightness - 0.0894841775 * a - 1.2914855480 * b) ^ 3

    local R = 4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s
    local G = -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s
    local B = -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s

    return R,G,B
end

local function lerp(a,b,t)
    return a + t * (b - a)
end

--#endregion
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
---@return colour
interface.fromHex = function(hexstring)
    hexstring = hexstring:gsub("^#","")

    if type(hexstring) ~= "string" or hexstring:find("[^0-9A-Fa-f]", 2) then
        error(tostring(hexstring) .. " is an invalid hex string")
    end

    if hexstring:len() < 8 then
        hexstring = hexstring .. ("F"):rep(8 - hexstring:len())
    end

    local r = tonumber(hexstring:sub(1,2),16) / 255
    local g = tonumber(hexstring:sub(3,4),16) / 255
    local b = tonumber(hexstring:sub(5,6),16) / 255
    local a = tonumber(hexstring:sub(7,8),16) / 255

    return interface.new(r,g,b,a)
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

---creates a colour using lightness, chroma (0 - 0.2 or 0.37) and hue (0 - 360)
---@param lightness number
---@param chroma number
---@param hue number
---@param alpha number
---@return colour
interface.fromOKLCH = function(lightness, chroma, hue, alpha)
    
    lightness = clamp(lightness,0,1)
    chroma = math.max(chroma,0)
    hue = clamp(hue,0,360)

    hue = math.rad(hue)
    local a = chroma * math.cos(hue)
    local b = chroma * math.sin(hue)

    local R,G,B = oklab_clip(lightness,chroma,a,b)

    R = toSRGB(R)
    G = toSRGB(G)
    B = toSRGB(B)

    return interface.new(R,G,B,alpha)
end

--#endregion

--#region util methods

---returns a hex string
---@param self colour
---@return string
function schema:ToHex()
    return string.format("#%02X%02X%02X%02X",self.R * 255,self.G * 255,self.B * 255,self.A * 255)
end

---returns the hue, saturation and value of a colour
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

    return hue, saturation, value
end


---returns lightness, chroma and hue of a colour
---@param self colour
---@return number
---@return number
---@return number
function schema:ToOKLCH()
    local r = toLinearRGB(self.R)
    local g = toLinearRGB(self.G)
    local b = toLinearRGB(self.B)

    local l = (0.4122214708*r + 0.5363325363*g + 0.0514459929*b) ^ (1/3)
    local m = (0.2119034982*r + 0.6806995451*g + 0.1073969566*b) ^ (1/3)
    local s = (0.0883024619*r + 0.2817188376*g + 0.6299787005*b) ^ (1/3)

    local lightness = 0.2104542553*l + 0.7936177850*m - 0.0040720468*s
    local A = 1.9779984951*l - 2.4285922050*m + 0.4505937099*s
    local B = 0.0259040371*l + 0.7827717662*m - 0.8086757660*s

    local chroma = math.sqrt(A * A + B * B)
    local hue = math.deg(atan2(B,A))
    if hue < 0 then hue = hue + 360 end 

    return lightness, chroma, hue
end

---returns RGBA values from 0 - 1
---@param self colour
---@return number r
---@return number g
---@return number b
---@return number a
function schema:Unpack()
    return self.R,self.G,self.B,self.A
end

---returns a copy of the colour
---@param self colour
---@return colour
function schema:Clone()
    return interface.new(self.R,self.G,self.B,self.A)
end

--#endregion
--#region transformations

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
    local luminance = 0.2126 * toLinearRGB(self.R) + 0.7152 * toLinearRGB(self.G) + 0.0722 * toLinearRGB(self.B)
    
    luminance = toSRGB(luminance)
    return interface.new(luminance,luminance,luminance,self.A)
end

--#endregion
--#region interpolation

---interpolates between 2 colours and returns the result
---@param other colour
---@param t number
---@return colour
function schema:Lerp(other,t)
    local R = lerp(self.R,other.R,t)
    local G = lerp(self.G,other.G,t)
    local B = lerp(self.B,other.B,t)
    local A = lerp(self.A,other.A,t)

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
    H = (H1 + H * t) % 360

    local S = lerp(S1,S2,t)
    local V = lerp(V1,V2,t)

    local A = lerp(self.A,other.A,t)

    return interface.fromHSVA(H,S,V,A)
end

--#endregion
--#region HSV shifts

function schema:HueShift(hue)
    local H,S,V = self:ToHSV()
    return interface.fromHSVA((H + hue) % 360,S,V,self.A)
end

function schema:SaturationShift(saturation)
    local H,S,V = self:ToHSV()
    return interface.fromHSVA(H,S + saturation,V,self.A)
end

function schema:BrightnessShift(brightness)
    local H,S,V = self:ToHSV()
    return interface.fromHSVA(H,S,V + brightness,self.A)
end

--#endregion
--#region colour pallets

---returns the complementary colour of the original colour
---@param self colour
---@return colour
function schema:Complementary()
    local L,C,H = self:ToOKLCH()
    return interface.fromOKLCH(L,C,adaptiveHueShift(H,C,180),self.A)
end

---returns analogous colours of the original colour
---@param self colour
---@param layer number
---@return colour[]
function schema:Analogous(layer)
    local L,C,H = self:ToOKLCH()
    
    local pallete = {}
    local inc = 30
    local angle = -inc * layer

    for i = 1, layer * 2 + 1 do
        local hue = adaptiveHueShift(H,C,angle)
        table.insert(pallete,interface.fromOKLCH(L,C,hue,self.A))
        angle = angle + inc
    end

    return pallete

end

---returns triadic colours of the original colour
---@param self colour
---@return colour
---@return colour
function schema:Triadic()
    local L,C,H = self:ToOKLCH()

    return interface.fromOKLCH(L,C,adaptiveHueShift(H,C,-120),self.A),
           interface.fromOKLCH(L,C,adaptiveHueShift(H,C,120) ,self.A)
end

---returns the split complement of the original colour
---@param self colour
---@return colour
---@return colour
function schema:SplitComplementary()
    local L,C,H = self:ToOKLCH()

    return interface.fromOKLCH(L,C,adaptiveHueShift(H,C,-150),self.A),
           interface.fromOKLCH(L,C,adaptiveHueShift(H,C,150) ,self.A)
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
        self.R / other.R,
        self.G / other.G,
        self.B / other.B,
        self.A
    )
end

meta.__call = function(self)
    return self:Unpack()
end


--#endregion


return interface