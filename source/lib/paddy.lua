

--[[
 Paddy - an onscreen controller display for touch enabled devices
 * Copyright (C) 2017 Ricky K. Thomson
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 * u should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 --]]
--note joystick doesnt work when another button is presse before it due to pressed being called
--once
Paddy = _class:extend("Paddy")

function Paddy:__init__(kwargs)
    local kwargs = kwargs or {}
    self.debug = kwargs.debug
    if self.debug == nil then
        self.debug = true
    end

    self.parent = kwargs.parent or kwargs

    -- The size of the buttons which can be pressed.
    self.buttonw = SCREEN_WIDTH*0.0781
    self.buttonh = SCREEN_WIDTH*0.0781


    -- This lists any buttons which are currently being pressed
    self.touched = {}


    if kwargs.joysticks then
        kwargs.Ljoystick = true
        kwargs.Rjoystick = true
    end

    if kwargs.joystick then
        kwargs.Rjoystick = true
    end

    if kwargs.Ljoystick then
        if type(kwargs.joystick) ~= "table" then
            kwargs.Ljoystick = {
                r = self.buttonw*3/2,
                h = self.buttonh*3,
                y = love.graphics.getHeight()-20-self.buttonh*3/2,
                x = 20+self.buttonw*3/2
            }
        end
        self.Ljoystick = Andralog(kwargs.Ljoystick)
    end

    -- Create a dpad widget
    self.dpad = {}

    -- The properties of the canvas to draw
    self.dpad.w = self.buttonw*3
    self.dpad.h = self.buttonh*3
    self.dpad.x = 20
    self.dpad.y = SCREEN_HEIGHT-20-self.dpad.h
    self.dpad.canvas = love.graphics.newCanvas(self.dpad.w,self.dpad.h)

    -- These just make things look prettier
    self.dpad.opacity = kwargs.padding or 200
    self.dpad.padding = kwargs.padding or 5

    -- Setup the names for the buttons, and their position on the canvas
    self.dpad.buttons = {
        { name="up",   x=self.buttonw, y=0 },
        { name="left", x=0, y=self.buttonh },
        { name="right",x=self.buttonw*2, y=self.buttonh },
        { name="down", x=self.buttonw, y=self.buttonh*2 },
    }


    if kwargs.Rjoystick then
        if type(kwargs.joystick) ~= "table" then
            kwargs.Rjoystick = {
                r = self.buttonw*3/2,
              --  h = self.buttonh*3,
                y = love.graphics.getHeight()-self.buttonw*3/2-20,
                x = love.graphics.getWidth()-self.buttonw*3/2-20
            }
        end
       -- kwargs.joystick.x = self.buttonw*3
      --  kwargs.joystick.y = 0
        self.Rjoystick = Andralog(kwargs.Rjoystick)
        --self.joystick.canvas = love.graphics.newCanvas(self.joystick.w, self.joystick.h)
   --     self.joystick.y = love.graphics.getHeight()-20-self.joystick.h*3
      --  self.joystick.x = love.graphics.getWidth()-20--self.joystick.w
    end

    -- Create a buttons widget
    self.buttons = {}

    -- The properties of the canvas to draw
    self.buttons.w = self.buttonw*3
    self.buttons.h = self.buttonh*3
    self.buttons.x = SCREEN_WIDTH-20-self.buttons.w
    self.buttons.y = SCREEN_HEIGHT-20-self.buttons.h

    --self.buttons.canvas = love.graphics.newCanvas(self.buttons.w,self.buttons.h)

    -- These just make things look prettier
    self.buttons.opacity = kwargs.opacity or 200
    self.buttons.padding = kwargs.padding or 5

   -- Setup the names for the buttons, and their position on the canvas
    self.buttons.buttons = {
        { name="p", x=self.buttonw, y=0 },
        { name="q", x=0, y=self.buttonh },
        { name="e", x=self.buttonw*2, y=self.buttonh },
        { name="o", x=self.buttonw, y=self.buttonh*2 },
    }
    self.keys = {
    y = "w",
    a = "a",
    b = "z",
    x = "s",
    p = "p",
    o = "o",
    q = "q",
    e = "e",
    up = "up",
    down = "down",
    left = "left",
    right = "right"
    }

    -- Stores any widgets containing interactive buttons
    self.widgets = { self.dpad, self.buttons, self.Rjoystick, self.Ljoystick }

    if self.Rjoystick then
        self.buttons.buttons={}
        self.Rjoystick.buttons = {}
    end
    if self.Ljoystick then
        self.dpad.buttons={}
        self.Ljoystick.buttons = {}
    end

    self.setButtonName = self.changeButtonName
    self.setButtonText = self.setButtonName
    self.changeButtonText = self.changeButtonName
end

function Paddy:changeButtonName(old,new)
    for i,b in ipairs(self.buttons.buttons) do
        if b.name == old then
            self.keys[new] = self.keys[old]
            b.name = new
            return true
        end
    end
    for i,b in ipairs(self.dpad.buttons) do
        if b.name == old then
            self.keys[new] = self.keys[old]
            b.name = new
            return true
        end
    end
end

function Paddy:draw()
    -- Draw the control pad
  --  if not iux then iux=4 self.joystick:rebuild() end
    for wi,widget in ipairs(self.widgets) do
        local x ,y = widget.x,widget.y

        if wi >= 3 then
           -- widget:draw()
            x,y = widget.__x,widget.__y
        end
        if wi<3 then
        love.graphics.setColor(0.607,0.607,0.607,0.196)
        love.graphics.circle("fill", x+widget.w/2,y+widget.h/2,widget.w/2)
        aspect.stop()


        love.graphics.setCanvas(widget.canvas)
        love.graphics.clear()

        love.graphics.setColor(0.607,0.607,0.607,1)
        end

        for _,button in ipairs(widget.buttons) do
            if button.isDown then
                love.graphics.setColor(0.607,0.607,0.607,1)
                love.graphics.rectangle("fill",
                    button.x+widget.padding,
                    button.y+widget.padding,
                    self.buttonw-widget.padding*2,
                    self.buttonh-widget.padding*2,
                    10
                )
            else
                love.graphics.setColor(0.607,0.607,0.607,0.784)
                love.graphics.rectangle("line",
                    button.x+widget.padding,
                    button.y+widget.padding,
                    self.buttonw-widget.padding*2,
                    self.buttonh-widget.padding*2,
                    10
                )
            end


            -- Temporary code until  button naming can be improved
            if true then-- nil then--self.debug then
                love.graphics.setColor(1,1,1,1)
                local tr = love.graphics.getFont()
                local font = Assets.getFont("font18")--love.graphics.newFont(20)
                love.graphics.setFont(font)
                local str = button.name

                love.graphics.printf(
                    button.name,
                    button.x+self.buttonw/2,
                    button.y+self.buttonh/2,
                    font:getWidth(str),
                    "center"
                )
                love.graphics.setFont(tr)
            end
        end
        local x ,y = widget.x,widget.y
        if wi >2 then
            widget:draw()
            x,y = widget.__x,widget.__y
       -- end
        else
        aspect.start()
        love.graphics.setCanvas()
        love.graphics.setColor(1,1,1,widget.opacity)
        love.graphics.draw(widget.canvas, x, y) end
    end

    -- debug related
    if nil then--self.debug then
        for _,id in ipairs(self.touched) do
            local x,y = love.touch.getPosition(id)
            love.graphics.circle("fill",x,y,20)
        end
    end
  end

function Paddy:isDown(key)
    -- Check for any buttons which are currently being pressed

    if love.keyboard._isDown(self.keys[key] or key) then
        return true
    end

    for _,widget in ipairs(self.widgets) do
        for _,button in ipairs(widget.buttons) do
            if button.isDown and button.name == key then
                self.parent.buttonPressed = true
                return true
            end
        end
    end
    return false
end

function Paddy:update(dt)
    self.pressed = nil
    -- Decide which buttons are being pressed based on a
    -- simple collision, then change the state of the button

    self.touched = love.touch.getTouches()

     for _,widget in ipairs(self.widgets) do
        if _ >= 3 then
            widget:update(dt)
            goto continue
        end
        for _,button in ipairs(widget.buttons) do
            button.isDown = false
            for _,id in ipairs(self.touched) do
                local txx,tyy = love.touch.getPosition(id)
                local tx, ty = aspect.toGame(txx,tyy)
                if  tx >= widget.x+button.x
                and tx <= widget.x+button.x+self.buttonw
                and ty >= widget.y+button.y
                and ty <= widget.y+button.y+self.buttonh then
                    button.isDown = true
                    self.pressed = button.name
                    love.keypressed(button.name, button.name)
                end

                if self.joystick and self.joystick:overItAux(tx,ty) then
              --      self.joystick:pressed(tx,ty)
              --      cwarn("","green")
                end
            end
        end
        ::continue::
    end
end

function Paddy:released(...)
    local trash = self.Rjoystick and self.Rjoystick:released(...)
    local trash = self.Ljoystick and self.Ljoystick:released(...)
end

function Paddy:mousereleased(...)
    local trash = self.Rjoystick and self.Rjoystick:released(...)
    local trash = self.Ljoystick and self.Ljoystick:released(...)
end

function Paddy:mousepressed(...)
    local trash = self.Rjoystick and self.Rjoystick:pressed(...)
    local trash = self.Ljoystick and self.Ljoystick:pressed(...)
end


function Paddy:touchreleased(...)
    local trash = self.Rjoystick and self.Rjoystick:touchReleased(...)
    local trash = self.Ljoystick and self.Ljoystick:touchReleased(...)
end

function Paddy:touchpressed(...)
    local trash = self.Rjoystick and self.Rjoystick:touchPressed(...)
    local trash = self.Ljoystick and self.Ljoystick:touchPressed(...)
end

function Paddy:touchmoved(...)
    local trash = self.Rjoystick and self.Rjoystick:touchMoved(...)
    local trash = self.Ljoystick and self.Ljoystick:touchMoved(...)
end

function Paddy:prejssed(...)
    local trash = self.joystick and self.joystick:pressed(...)
end

return Paddy
