--class.lua modified from rotlove's class

local BaseClass = {timeMade=-1}
CLASSES = {BaseClase=BaseClass}
POOLS = {}


local function destroyFunc(self,...)
    local notActive = POOLS[self.__class].notActive local te = #notActive
    local te = #notActive
            --if self.isBullet then --log(#notActive.." pool at "..self.__id.." is being freed.") end
    --assert(self.__active,self.__id)
    self.__active = false
    notActive[#notActive+1] = self.__id
    assert(#notActive<=self.poolSize,#notActive)
            --if self.isBullet or self.isPuffv then --log(#notActive.." des2") end

    local re = self._destroy(self,...)
    assert(#notActive-te==1,self.class)
    return re
end

local function passiveDestroyFunc(self,...)
    local notActive = POOLS[self.__class].notActive local te = #notActive
    local te = #notActive
            --if self.isBullet then --log(#notActive.." pool at "..self.__id.." is being freed.") end
    --assert(self.__active,self.__id)
    self.__active = false
    notActive[#notActive+1] = self.__id
    assert(#notActive<=self.poolSize,#notActive)
            --if self.isBullet or self.isPuffv then --log(#notActive.." ppes2") end

    local re = self._pdestroy(self,...)
    assert(#notActive-te==1,self.class)
    return re
end

local function oldNew(self,...)
    local t = setmetatable({}, self)
    t:__init__(...)
    local kw = ...
    t._kwargs = t._kwargs or t.kwargs or (kw and type(kw)=="table" and kw)
    t.timeMade = love.timer.getTime()
    if store then
        store(t)
    end
    return t
end

function BaseClass:new(...)
    local t = setmetatable({}, self)
    t:__init__(...)
    local kw = ...
    t._kwargs = t._kwargs or t.kwargs or (kw and type(kw)=="table" and kw)
    t.timeMade = love.timer.getTime()
    if store then
        store(t)
    end
    return t
end

function BaseClass:extend(name, t, tt)
    assert(name, "Class must have a name!")

    local p = t
    if type(t)~="table" then
        t = nil
    else
        p = tt
    end

    t = t or {}
    if type(p)=="number" then
        t.poolSize = p
    end
    t.__index = t
    t.__class = name
    t.class = name
    t.super = self

    t.poolSize = t.poolSize or 1000
    t.pool = p

    local tclass = setmetatable(t, { __call = self.new, __index = self })
    tclass.__lt = self.__lt

    CLASSES[name] = tclass
    t["is"..name] = true
    t.oldnew = t.oldnew or t.new

    return tclass
end

function BaseClass:__init__()
end

function BaseClass:getCenter()
    return self.x+self.w/2, self.y+self.h/2
end

function BaseClass.__lt(self,b)
    return self.timeMade<b.timeMade
end

function BaseClass:callSuper(func,...)
    if not self.super[func] then
        return
    end
    return self.super[func](self,...)
end

return BaseClass
