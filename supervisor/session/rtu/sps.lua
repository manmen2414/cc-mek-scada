local log          = require("scada-common.log")
local types        = require("scada-common.types")
local util         = require("scada-common.util")

local unit_session = require("supervisor.session.rtu.unit_session")

local sps = {}

local RTU_UNIT_TYPE = types.RTU_UNIT_TYPE
local MODBUS_FCODE = types.MODBUS_FCODE

local TXN_TYPES = {
    FORMED = 1,
    BUILD = 2,
    STATE = 3,
    TANKS = 4
}

local TXN_TAGS = {
    "sps.formed",
    "sps.build",
    "sps.state",
    "sps.tanks"
}

local PERIODICS = {
    FORMED = 2000,
    BUILD = 1000,
    STATE = 500,
    TANKS = 1000
}

-- create a new sps rtu session runner
---@nodiscard
---@param session_id integer RTU gateway session ID
---@param unit_id integer RTU ID
---@param advert rtu_advertisement RTU advertisement table
---@param out_queue mqueue RTU message out queue
function sps.new(session_id, unit_id, advert, out_queue)
    -- type check
    if advert.type ~= RTU_UNIT_TYPE.SPS then
        log.error("attempt to instantiate sps RTU for type " .. types.rtu_type_to_string(advert.type))
        return nil
    end

    local log_tag = util.c("session.rtu(", session_id, ").sps[@", unit_id, "]: ")

    local self = {
        session = unit_session.new(session_id, unit_id, advert, out_queue, log_tag, TXN_TAGS),
        has_build = false,
        periodics = {
            next_formed_req = 0,
            next_build_req = 0,
            next_state_req = 0,
            next_tanks_req = 0
        },
        ---@class sps_session_db
        db = {
            formed = false,
            build = {
                last_update = 0,
                length = 0,
                width = 0,
                height = 0,
                min_pos = types.new_zero_coordinate(),
                max_pos = types.new_zero_coordinate(),
                coils = 0,
                input_cap = 0,
                output_cap = 0,
                max_energy = 0
            },
            state = {
                last_update = 0,
                process_rate = 0.0
            },
            tanks = {
                last_update = 0,
                input = types.new_empty_gas(),
                input_need = 0,
                input_fill = 0.0,
                output = types.new_empty_gas(),
                output_need = 0,
                output_fill = 0.0,
                energy = 0,
                energy_need = 0,
                energy_fill = 0.0
            }
        }
    }

    ---@class sps_session:unit_session
    local public = self.session.get()

    -- PRIVATE FUNCTIONS --

    -- query if the multiblock is formed
    local function _request_formed()
        -- read discrete input 1 (start = 1, count = 1)
        self.session.send_request(TXN_TYPES.FORMED, MODBUS_FCODE.READ_DISCRETE_INPUTS, { 1, 1 })
    end

    -- query the build of the device
    local function _request_build()
        -- read input registers 1 through 9 (start = 1, count = 9)
        self.session.send_request(TXN_TYPES.BUILD, MODBUS_FCODE.READ_INPUT_REGS, { 1, 9 })
    end

    -- query the state of the device
    local function _request_state()
        -- read input register 10 (start = 10, count = 1)
        self.session.send_request(TXN_TYPES.STATE, MODBUS_FCODE.READ_INPUT_REGS, { 10, 1 })
    end

    -- query the tanks of the device
    local function _request_tanks()
        -- read input registers 11 through 19 (start = 11, count = 9)
        self.session.send_request(TXN_TYPES.TANKS, MODBUS_FCODE.READ_INPUT_REGS, { 11, 9 })
    end

    -- PUBLIC FUNCTIONS --

    -- handle a packet
    ---@param m_pkt modbus_frame
    function public.handle_packet(m_pkt)
        local txn_type = self.session.try_resolve(m_pkt)
        if txn_type == false then
            -- nothing to do
        elseif txn_type == TXN_TYPES.FORMED then
            -- formed response
            -- load in data if correct length
            if m_pkt.length == 1 then
                self.db.formed = m_pkt.data[1]

                if not self.db.formed then self.has_build = false end
            else
                log.debug(log_tag .. "MODBUS transaction reply length mismatch (" .. TXN_TAGS[txn_type] .. ")")
            end
        elseif txn_type == TXN_TYPES.BUILD then
            -- build response
            -- load in data if correct length
            if m_pkt.length == 9 then
                self.db.build.last_update = util.time_ms()
                self.db.build.length      = m_pkt.data[1]
                self.db.build.width       = m_pkt.data[2]
                self.db.build.height      = m_pkt.data[3]
                self.db.build.min_pos     = m_pkt.data[4]
                self.db.build.max_pos     = m_pkt.data[5]
                self.db.build.coils       = m_pkt.data[6]
                self.db.build.input_cap   = m_pkt.data[7]
                self.db.build.output_cap  = m_pkt.data[8]
                self.db.build.max_energy  = m_pkt.data[9]
                self.has_build = true

                out_queue.push_data(unit_session.RTU_US_DATA.BUILD_CHANGED, { unit = advert.reactor, type = advert.type })
            else
                log.debug(log_tag .. "MODBUS transaction reply length mismatch (" .. TXN_TAGS[txn_type] .. ")")
            end
        elseif txn_type == TXN_TYPES.STATE then
            -- state response
            -- load in data if correct length
            if m_pkt.length == 1 then
                self.db.state.last_update  = util.time_ms()
                self.db.state.process_rate = m_pkt.data[1]
            else
                log.debug(log_tag .. "MODBUS transaction reply length mismatch (" .. TXN_TAGS[txn_type] .. ")")
            end
        elseif txn_type == TXN_TYPES.TANKS then
            -- tanks response
            -- load in data if correct length
            if m_pkt.length == 9 then
                self.db.tanks.last_update = util.time_ms()
                self.db.tanks.input       = m_pkt.data[1]
                self.db.tanks.input_need  = m_pkt.data[2]
                self.db.tanks.input_fill  = m_pkt.data[3]
                self.db.tanks.output      = m_pkt.data[4]
                self.db.tanks.output_need = m_pkt.data[5]
                self.db.tanks.output_fill = m_pkt.data[6]
                self.db.tanks.energy      = m_pkt.data[7]
                self.db.tanks.energy_need = m_pkt.data[8]
                self.db.tanks.energy_fill = m_pkt.data[9]
            else
                log.debug(log_tag .. "MODBUS transaction reply length mismatch (" .. TXN_TAGS[txn_type] .. ")")
            end
        elseif txn_type == nil then
            log.error(log_tag .. "unknown transaction reply")
        else
            log.error(log_tag .. "unknown transaction type " .. txn_type)
        end
    end

    -- update this runner
    ---@param time_now integer milliseconds
    function public.update(time_now)
        if self.periodics.next_formed_req <= time_now then
            _request_formed()
            self.periodics.next_formed_req = time_now + PERIODICS.FORMED
        end

        if self.db.formed then
            if not self.has_build and self.periodics.next_build_req <= time_now then
                _request_build()
                self.periodics.next_build_req = time_now + PERIODICS.BUILD
            end

            if self.periodics.next_state_req <= time_now then
                _request_state()
                self.periodics.next_state_req = time_now + PERIODICS.STATE
            end

            if self.periodics.next_tanks_req <= time_now then
                _request_tanks()
                self.periodics.next_tanks_req = time_now + PERIODICS.TANKS
            end
        end

        self.session.post_update()
    end

    -- invalidate build cache
    function public.invalidate_cache()
        self.periodics.next_formed_req = 0
        self.periodics.next_build_req = 0
        self.has_build = false
    end

    -- get the unit session database
    ---@nodiscard
    function public.get_db() return self.db end

    return public
end

return sps
