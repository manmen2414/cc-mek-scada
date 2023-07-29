-- local style   = require("pocket.ui.style")

local iocontrol      = require("pocket.iocontrol")

local core           = require("graphics.core")

local Div            = require("graphics.elements.div")
local MultiPane      = require("graphics.elements.multipane")
local TextBox        = require("graphics.elements.textbox")

local IndicatorLight = require("graphics.elements.indicators.light")

local App            = require("graphics.elements.controls.app")
local Checkbox       = require("graphics.elements.controls.checkbox")
local PushButton     = require("graphics.elements.controls.push_button")
local SwitchButton   = require("graphics.elements.controls.switch_button")

local cpair = core.cpair

local NAV_PAGE = iocontrol.NAV_PAGE

local TEXT_ALIGN = core.TEXT_ALIGN

-- new diagnostics page view
---@param root graphics_element parent
local function new_view(root)
    local db = iocontrol.get_db()

    local main = Div{parent=root,x=1,y=1}

    local diag_home = Div{parent=main,x=1,y=1}

    TextBox{parent=diag_home,text="Diagnostic Apps",x=1,y=2,height=1,alignment=TEXT_ALIGN.CENTER}

    local alarm_test = Div{parent=main,x=1,y=1}

    local panes = { diag_home, alarm_test }

    local page_pane = MultiPane{parent=main,x=1,y=1,panes=panes}

    local function navigate_diag()
        page_pane.set_value(1)
        db.nav.page = NAV_PAGE.DIAG
        db.nav.sub_pages[NAV_PAGE.DIAG] = NAV_PAGE.DIAG
    end

    local function navigate_alarm()
        page_pane.set_value(2)
        db.nav.page = NAV_PAGE.D_ALARMS
        db.nav.sub_pages[NAV_PAGE.DIAG] = NAV_PAGE.D_ALARMS
    end

    ------------------------
    -- Alarm Testing Page --
    ------------------------

    db.nav.register_task(NAV_PAGE.D_ALARMS, db.diag.tone_test.get_tone_states)

    local ttest = db.diag.tone_test

    local c_wht_gray = cpair(colors.white, colors.gray)
    local c_red_gray = cpair(colors.red, colors.gray)
    local c_yel_gray = cpair(colors.yellow, colors.gray)
    local c_blue_gray = cpair(colors.blue, colors.gray)

    local audio = Div{parent=alarm_test,x=1,y=1}

    TextBox{parent=audio,y=1,text="Alarm Sounder Tests",height=1,alignment=TEXT_ALIGN.CENTER}

    ttest.ready_warn = TextBox{parent=audio,y=2,text="",height=1,alignment=TEXT_ALIGN.CENTER,fg_bg=cpair(colors.yellow,colors.black)}

    PushButton{parent=audio,x=13,y=18,text="\x11 BACK",min_width=8,fg_bg=cpair(colors.black,colors.lightGray),active_fg_bg=c_wht_gray,callback=navigate_diag}

    local tones = Div{parent=audio,x=2,y=3,height=10,width=8,fg_bg=cpair(colors.black,colors.yellow)}

    TextBox{parent=tones,text="Tones",height=1,alignment=TEXT_ALIGN.CENTER,fg_bg=audio.get_fg_bg()}

    local test_btns = {}
    test_btns[1] = SwitchButton{parent=tones,text="TEST 1",min_width=8,active_fg_bg=c_wht_gray,callback=ttest.test_1}
    test_btns[2] = SwitchButton{parent=tones,text="TEST 2",min_width=8,active_fg_bg=c_wht_gray,callback=ttest.test_2}
    test_btns[3] = SwitchButton{parent=tones,text="TEST 3",min_width=8,active_fg_bg=c_wht_gray,callback=ttest.test_3}
    test_btns[4] = SwitchButton{parent=tones,text="TEST 4",min_width=8,active_fg_bg=c_wht_gray,callback=ttest.test_4}
    test_btns[5] = SwitchButton{parent=tones,text="TEST 5",min_width=8,active_fg_bg=c_wht_gray,callback=ttest.test_5}
    test_btns[6] = SwitchButton{parent=tones,text="TEST 6",min_width=8,active_fg_bg=c_wht_gray,callback=ttest.test_6}
    test_btns[7] = SwitchButton{parent=tones,text="TEST 7",min_width=8,active_fg_bg=c_wht_gray,callback=ttest.test_7}
    test_btns[8] = SwitchButton{parent=tones,text="TEST 8",min_width=8,active_fg_bg=c_wht_gray,callback=ttest.test_8}

    ttest.tone_buttons = test_btns

    local function stop_all_tones()
        for i = 1, #test_btns do test_btns[i].set_value(false) end
        ttest.stop_tones()
    end

    PushButton{parent=tones,text="STOP",min_width=8,active_fg_bg=c_wht_gray,fg_bg=cpair(colors.black,colors.red),callback=stop_all_tones}

    local alarms = Div{parent=audio,x=11,y=3,height=15,fg_bg=cpair(colors.lightGray,colors.black)}

    TextBox{parent=alarms,text="Alarms (\x13)",height=1,alignment=TEXT_ALIGN.CENTER,fg_bg=audio.get_fg_bg()}

    local alarm_btns = {}
    alarm_btns[1] = Checkbox{parent=alarms,label="BREACH",min_width=15,box_fg_bg=c_red_gray,callback=ttest.test_breach}
    alarm_btns[2] = Checkbox{parent=alarms,label="RADIATION",min_width=15,box_fg_bg=c_red_gray,callback=ttest.test_rad}
    alarm_btns[3] = Checkbox{parent=alarms,label="RCT LOST",min_width=15,box_fg_bg=c_red_gray,callback=ttest.test_lost}
    alarm_btns[4] = Checkbox{parent=alarms,label="CRIT DAMAGE",min_width=15,box_fg_bg=c_red_gray,callback=ttest.test_crit}
    alarm_btns[5] = Checkbox{parent=alarms,label="DAMAGE",min_width=15,box_fg_bg=c_red_gray,callback=ttest.test_dmg}
    alarm_btns[6] = Checkbox{parent=alarms,label="OVER TEMP",min_width=15,box_fg_bg=c_red_gray,callback=ttest.test_overtemp}
    alarm_btns[7] = Checkbox{parent=alarms,label="HIGH TEMP",min_width=15,box_fg_bg=c_yel_gray,callback=ttest.test_hightemp}
    alarm_btns[8] = Checkbox{parent=alarms,label="WASTE LEAK",min_width=15,box_fg_bg=c_red_gray,callback=ttest.test_wasteleak}
    alarm_btns[9] = Checkbox{parent=alarms,label="WASTE HIGH",min_width=15,box_fg_bg=c_yel_gray,callback=ttest.test_highwaste}
    alarm_btns[10] = Checkbox{parent=alarms,label="RPS TRANS",min_width=15,box_fg_bg=c_yel_gray,callback=ttest.test_rps}
    alarm_btns[11] = Checkbox{parent=alarms,label="RCS TRANS",min_width=15,box_fg_bg=c_yel_gray,callback=ttest.test_rcs}
    alarm_btns[12] = Checkbox{parent=alarms,label="TURBINE TRP",min_width=15,box_fg_bg=c_red_gray,callback=ttest.test_turbinet}

    ttest.alarm_buttons = alarm_btns

    local function stop_all_alarms()
        for i = 1, #alarm_btns do alarm_btns[i].set_value(false) end
        ttest.stop_alarms()
    end

    PushButton{parent=alarms,x=3,y=15,text="STOP \x13",min_width=8,fg_bg=cpair(colors.black,colors.red),active_fg_bg=c_wht_gray,callback=stop_all_alarms}

    local states = Div{parent=audio,x=2,y=14,height=5,width=8}

    TextBox{parent=states,text="States",height=1,alignment=TEXT_ALIGN.CENTER}
    local t_1 = IndicatorLight{parent=states,label="1",colors=c_blue_gray}
    local t_2 = IndicatorLight{parent=states,label="2",colors=c_blue_gray}
    local t_3 = IndicatorLight{parent=states,label="3",colors=c_blue_gray}
    local t_4 = IndicatorLight{parent=states,label="4",colors=c_blue_gray}
    local t_5 = IndicatorLight{parent=states,x=6,y=2,label="5",colors=c_blue_gray}
    local t_6 = IndicatorLight{parent=states,x=6,label="6",colors=c_blue_gray}
    local t_7 = IndicatorLight{parent=states,x=6,label="7",colors=c_blue_gray}
    local t_8 = IndicatorLight{parent=states,x=6,label="8",colors=c_blue_gray}

    ttest.tone_indicators = { t_1, t_2, t_3, t_4, t_5, t_6, t_7, t_8 }

    --------------
    -- App List --
    --------------

    App{parent=diag_home,x=3,y=4,text="\x0f",title="Alarm",callback=navigate_alarm,app_fg_bg=cpair(colors.black,colors.red),active_fg_bg=cpair(colors.white,colors.gray)}
    App{parent=diag_home,x=10,y=4,text="\x1e",title="LoopT",callback=function()end,app_fg_bg=cpair(colors.black,colors.cyan)}
    App{parent=diag_home,x=17,y=4,text="@",title="Comps",callback=function()end,app_fg_bg=cpair(colors.black,colors.orange)}

    return main
end

return new_view
