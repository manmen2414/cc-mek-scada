-- Indicator RGB LED Graphics Element

local element = require("graphics.element")

---@class indicator_led_rgb_args
---@field label string indicator label
---@field colors table colors to use
---@field min_label_width? integer label length if omitted
---@field parent graphics_element
---@field id? string element id
---@field x? integer 1 if omitted
---@field y? integer auto incremented if omitted
---@field fg_bg? cpair foreground/background colors
---@field hidden? boolean true to hide on initial draw

-- new RGB LED indicator light
---@nodiscard
---@param args indicator_led_rgb_args
---@return graphics_element element, element_id id
local function indicator_led_rgb(args)
    assert(type(args.label) == "string", "graphics.elements.indicators.ledrgb: label is a required field")
    assert(type(args.colors) == "table", "graphics.elements.indicators.ledrgb: colors is a required field")

    -- single line
    args.height = 1

    -- determine width
    args.width = math.max(args.min_label_width or 0, string.len(args.label)) + 2

    -- create new graphics element base object
    local e = element.new(args)

    -- init value for initial check in on_update
    e.value = 1

    -- on state change
    ---@param new_state integer indicator state
    function e.on_update(new_state)
        e.value = new_state
        e.w_set_cur(1, 1)
        if type(args.colors[new_state]) == "number" then
            e.w_blit("\x8c", colors.toBlit(args.colors[new_state]), e.fg_bg.blit_bkg)
        end
    end

    -- set indicator state
    ---@param val integer indicator state
    function e.set_value(val) e.on_update(val) end

    -- write label and initial indicator light
    e.on_update(1)
    if string.len(args.label) > 0 then
        e.w_set_cur(3, 1)
        e.w_write(args.label)
    end

    return e.complete()
end

return indicator_led_rgb
