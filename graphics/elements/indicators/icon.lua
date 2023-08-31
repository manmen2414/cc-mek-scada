-- Icon Indicator Graphics Element

local element = require("graphics.element")

---@class icon_sym_color
---@field color cpair
---@field symbol string

---@class icon_indicator_args
---@field label string indicator label
---@field states table state color and symbol table
---@field value? integer default state, defaults to 1
---@field min_label_width? integer label length if omitted
---@field parent graphics_element
---@field id? string element id
---@field x? integer 1 if omitted
---@field y? integer auto incremented if omitted
---@field fg_bg? cpair foreground/background colors
---@field hidden? boolean true to hide on initial draw

-- new icon indicator
---@nodiscard
---@param args icon_indicator_args
---@return graphics_element element, element_id id
local function icon(args)
    assert(type(args.label) == "string", "graphics.elements.indicators.icon: label is a required field")
    assert(type(args.states) == "table", "graphics.elements.indicators.icon: states is a required field")

    -- single line
    args.height = 1

    -- determine width
    args.width = math.max(args.min_label_width or 1, string.len(args.label)) + 4

    -- create new graphics element base object
    local e = element.new(args)

    -- state blit strings
    local state_blit_cmds = {}
    for i = 1, #args.states do
        local sym_color = args.states[i]    ---@type icon_sym_color

        table.insert(state_blit_cmds, {
            text = " " .. sym_color.symbol .. " ",
            fgd = string.rep(sym_color.color.blit_fgd, 3),
            bkg = string.rep(sym_color.color.blit_bkg, 3)
        })
    end

    -- write label and initial indicator light
    e.w_set_cur(5, 1)
    e.w_write(args.label)

    -- on state change
    ---@param new_state integer indicator state
    function e.on_update(new_state)
        local blit_cmd = state_blit_cmds[new_state]
        e.value = new_state
        e.w_set_cur(1, 1)
        e.w_blit(blit_cmd.text, blit_cmd.fgd, blit_cmd.bkg)
    end

    -- set indicator state
    ---@param val integer indicator state
    function e.set_value(val) e.on_update(val) end

    -- initial icon draw
    e.on_update(args.value or 1)

    return e.complete()
end

return icon
