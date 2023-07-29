-- Button Graphics Element

local tcd     = require("scada-common.tcd")

local core    = require("graphics.core")
local element = require("graphics.element")

local CLICK_TYPE = core.events.CLICK_TYPE

---@class app_button_args
---@field text string app icon text
---@field title string app title text
---@field callback function function to call on touch
---@field app_fg_bg cpair app icon foreground/background colors
---@field active_fg_bg? cpair foreground/background colors when pressed
---@field parent graphics_element
---@field id? string element id
---@field x? integer 1 if omitted
---@field y? integer auto incremented if omitted
---@field fg_bg? cpair foreground/background colors
---@field hidden? boolean true to hide on initial draw

-- new app button
---@param args app_button_args
---@return graphics_element element, element_id id
local function app_button(args)
    assert(type(args.text) == "string", "graphics.elements.controls.app: text is a required field")
    assert(type(args.title) == "string", "graphics.elements.controls.app: title is a required field")
    assert(type(args.callback) == "function", "graphics.elements.controls.app: callback is a required field")
    assert(type(args.app_fg_bg) == "table", "graphics.elements.controls.app: app_fg_bg is a required field")

    args.height = 4
    args.width  = 5

    -- create new graphics element base object
    local e = element.new(args)

    -- write app title, centered
    e.window.setCursorPos(1, 4)
    e.window.setCursorPos(math.floor((e.frame.w - string.len(args.title)) / 2) + 1, 4)
    e.window.write(args.title)

    -- draw the button
    local function draw()
        local fgd = args.app_fg_bg.fgd
        local bkg = args.app_fg_bg.bkg

        if e.value then
            fgd = args.active_fg_bg.fgd
            bkg = args.active_fg_bg.bkg
        end

        -- draw icon
        e.window.setCursorPos(1, 1)
        e.window.setTextColor(fgd)
        e.window.setBackgroundColor(bkg)
        e.window.write("\x9f\x83\x83\x83")
        e.window.setTextColor(bkg)
        e.window.setBackgroundColor(fgd)
        e.window.write("\x90")
        e.window.setTextColor(fgd)
        e.window.setBackgroundColor(bkg)
        e.window.setCursorPos(1, 2)
        e.window.write("\x95   ")
        e.window.setTextColor(bkg)
        e.window.setBackgroundColor(fgd)
        e.window.write("\x95")
        e.window.setCursorPos(1, 3)
        e.window.write("\x82\x8f\x8f\x8f\x81")

        -- write the icon text
        e.window.setCursorPos(3, 2)
        e.window.setTextColor(fgd)
        e.window.setBackgroundColor(bkg)
        e.window.write(args.text)
    end

    -- draw the button as pressed (if active_fg_bg set)
    local function show_pressed()
        if e.enabled and args.active_fg_bg ~= nil then
            e.value = true
            e.window.setTextColor(args.active_fg_bg.fgd)
            e.window.setBackgroundColor(args.active_fg_bg.bkg)
            draw()
        end
    end

    -- draw the button as unpressed (if active_fg_bg set)
    local function show_unpressed()
        if e.enabled and args.active_fg_bg ~= nil then
            e.value = false
            e.window.setTextColor(e.fg_bg.fgd)
            e.window.setBackgroundColor(e.fg_bg.bkg)
            draw()
        end
    end

    -- handle mouse interaction
    ---@param event mouse_interaction mouse event
    function e.handle_mouse(event)
        if e.enabled then
            if event.type == CLICK_TYPE.TAP then
                show_pressed()
                -- show as unpressed in 0.25 seconds
                if args.active_fg_bg ~= nil then tcd.dispatch(0.25, show_unpressed) end
                args.callback()
            elseif event.type == CLICK_TYPE.DOWN then
                show_pressed()
            elseif event.type == CLICK_TYPE.UP then
                show_unpressed()
                if e.in_frame_bounds(event.current.x, event.current.y) then
                    args.callback()
                end
            end
        end
    end

    -- set the value (true simulates pressing the button)
    ---@param val boolean new value
    function e.set_value(val)
        if val then e.handle_mouse(core.events.mouse_generic(core.events.CLICK_TYPE.UP, 1, 1)) end
    end

    -- initial draw
    draw()

    return e.complete()
end

return app_button
