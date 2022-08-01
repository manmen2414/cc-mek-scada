--
-- Reactor Unit SCADA Coordinator GUI
--

local core   = require("graphics.core")
local tcallbackdsp = require("scada-common.tcallbackdsp")

local style = require("coordinator.ui.style")

local DisplayBox = require("graphics.elements.displaybox")
local Div        = require("graphics.elements.div")
local TextBox    = require("graphics.elements.textbox")
local ColorMap   = require("graphics.elements.colormap")

local CoreMap       = require("graphics.elements.indicators.coremap")
local DataIndicator  = require("graphics.elements.indicators.data")
local HorizontalBar  = require("graphics.elements.indicators.hbar")
local IndicatorLight = require("graphics.elements.indicators.light")
local StateIndicator = require("graphics.elements.indicators.state")

local PushButton     = require("graphics.elements.controls.push_button")
local SCRAMButton    = require("graphics.elements.controls.scram_button")
local SpinboxNumeric = require("graphics.elements.controls.spinbox_numeric")

local TEXT_ALIGN = core.graphics.TEXT_ALIGN

local cpair = core.graphics.cpair
local border = core.graphics.border

local function init(monitor, id)
    local main = DisplayBox{window=monitor,fg_bg=style.root}

    TextBox{parent=main,text="Reactor Unit #" .. id,alignment=TEXT_ALIGN.CENTER,height=1,fg_bg=style.header}

    local scram_fg_bg = core.graphics.cpair(colors.white, colors.gray)

    ---@fixme test code
    local t = 300
    if id == 1 then
        t = 340
    elseif id == 2 then
        t = 340
    elseif id == 3 then
        t = 300
    elseif id == 4 then
        t = 300
    end

    local core_map = CoreMap{parent=main,x=2,y=3}
    core_map.update(t)
    local core_shift = core_map.height()

    local f = function () print("scram!") end
    local scram = SCRAMButton{parent=main,x=2,y=core_shift+4,callback=f,fg_bg=scram_fg_bg}

    local burn_control = Div{parent=main,x=13,y=core_shift+4,width=19,height=3,fg_bg=cpair(colors.gray,colors.white)}

    local burn_rate = SpinboxNumeric{parent=burn_control,x=2,y=1,whole_num_precision=4,fractional_precision=1,arrow_fg_bg=cpair(colors.gray,colors.white),fg_bg=cpair(colors.black,colors.white)}
    local set_burn = function () print("set burn to " .. burn_rate.get_value()) end

    TextBox{parent=burn_control,x=9,y=2,text="mB/t"}
    PushButton{parent=burn_control,x=14,y=2,text="SET",min_width=5,fg_bg=cpair(colors.black,colors.yellow),active_fg_bg=cpair(colors.white,colors.gray),callback=set_burn}

    ---@fixme test code
    main.line_break()
    ColorMap{parent=main}

    local annunciator = Div{parent=main,x=34,y=3}

    -- annunciator colors per IAEA-TECDOC-812 recommendations

    -- connectivity/basic state
    local plc_online = IndicatorLight{parent=annunciator,label="PLC Online",colors=cpair(colors.green,colors.red)}
    local plc_hbeat  = IndicatorLight{parent=annunciator,label="PLC Heartbeat",colors=cpair(colors.white,colors.gray)}
    local r_active   = IndicatorLight{parent=annunciator,label="Active",colors=cpair(colors.green,colors.gray)}
    local r_auto     = IndicatorLight{parent=annunciator,label="Auto Control",colors=cpair(colors.blue,colors.gray)}

    annunciator.line_break()

    -- annunciator fields
    local r_trip = IndicatorLight{parent=annunciator,label="Reactor SCRAM",colors=cpair(colors.red,colors.gray)}
    local r_mtrp = IndicatorLight{parent=annunciator,label="Manual Reactor SCRAM",colors=cpair(colors.red,colors.gray)}
    local r_rtrp = IndicatorLight{parent=annunciator,label="RCP Trip",colors=cpair(colors.red,colors.gray)}
    local r_cflo = IndicatorLight{parent=annunciator,label="RCS Flow Low",colors=cpair(colors.yellow,colors.gray)}
    local r_temp = IndicatorLight{parent=annunciator,label="Reactor Temp. High",colors=cpair(colors.red,colors.gray)}
    local r_rhdt = IndicatorLight{parent=annunciator,label="Reactor High Delta T",colors=cpair(colors.yellow,colors.gray)}
    local r_firl = IndicatorLight{parent=annunciator,label="Fuel Input Rate Low",colors=cpair(colors.yellow,colors.gray)}
    local r_wloc = IndicatorLight{parent=annunciator,label="Waste Line Occlusion",colors=cpair(colors.yellow,colors.gray)}
    local r_hsrt = IndicatorLight{parent=annunciator,label="High Startup Rate",colors=cpair(colors.yellow,colors.gray)}

    annunciator.line_break()

    -- RPS
    local rps_trp = IndicatorLight{parent=annunciator,label="RPS Trip",colors=cpair(colors.red,colors.gray)}
    local rps_dmg = IndicatorLight{parent=annunciator,label="Damage Critical",colors=cpair(colors.yellow,colors.gray)}
    local rps_exh = IndicatorLight{parent=annunciator,label="Excess Heated Coolant",colors=cpair(colors.yellow,colors.gray)}
    local rps_exc = IndicatorLight{parent=annunciator,label="Excess Waste",colors=cpair(colors.yellow,colors.gray)}
    local rps_tmp = IndicatorLight{parent=annunciator,label="High Core Temp",colors=cpair(colors.yellow,colors.gray)}
    local rps_nof = IndicatorLight{parent=annunciator,label="No Fuel",colors=cpair(colors.yellow,colors.gray)}
    local rps_noc = IndicatorLight{parent=annunciator,label="No Coolant",colors=cpair(colors.yellow,colors.gray)}
    local rps_flt = IndicatorLight{parent=annunciator,label="PPM Fault",colors=cpair(colors.yellow,colors.gray)}
    local rps_tmo = IndicatorLight{parent=annunciator,label="Timeout",colors=cpair(colors.yellow,colors.gray)}

    annunciator.line_break()

    -- cooling
    local c_brm  = IndicatorLight{parent=annunciator,label="Boil Rate Mismatch",colors=cpair(colors.yellow,colors.gray)}
    local c_cfm  = IndicatorLight{parent=annunciator,label="Coolant Feed Mismatch",colors=cpair(colors.yellow,colors.gray)}
    local c_sfm  = IndicatorLight{parent=annunciator,label="Steam Feed Mismatch",colors=cpair(colors.yellow,colors.gray)}
    local c_mwrf = IndicatorLight{parent=annunciator,label="Max Water Return Feed",colors=cpair(colors.yellow,colors.gray)}
    local c_tbnt = IndicatorLight{parent=annunciator,label="Turbine Trip",colors=cpair(colors.red,colors.gray)}

    ---@fixme test code
    plc_hbeat.update(true)
    r_auto.update(true)
    r_trip.update(true)
    r_mtrp.update(true)
    rps_trp.update(true)
    rps_nof.update(true)

    ---@fixme test code
    local heartbeat = true
    local function _test_toggle()
        plc_hbeat.update(heartbeat)
        heartbeat = not heartbeat
        tcallbackdsp.dispatch(1, _test_toggle)
    end

    ---@fixme test code
    local rps = true
    local function _test_toggle1()
        rps_nof.update(rps)
        rps = not rps
        tcallbackdsp.dispatch(0.25, _test_toggle1)
    end

    ---@fixme test code
    tcallbackdsp.dispatch(1, _test_toggle)
    tcallbackdsp.dispatch(0.25, _test_toggle1)

    return main
end

return init
