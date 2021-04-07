--- 模块功能：BH1750
-- @module BH1750
-- @author Dozingfiretruck
-- @license MIT
-- @copyright OpenLuat.com
-- @release 2021.03.14

module(...,package.seeall)
require"utils"
require"bit"

pm.wake("bh1750")

local i2cid = 2 --i2cid

local BH1750_ADDRESS_AD0_LOW     =   0x23 -- address pin low (GND), default for InvenSense evaluation board
local BH1750_ADDRESS_AD0_HIGH    =   0x24 -- address pin high (VCC)

local i2cslaveaddr = BH1750_ADDRESS_AD0_LOW

-- bh1750 registers define
local BH1750_POWER_DOWN   	    =   0x00	-- power down
local BH1750_POWER_ON			=   0x01	-- power on
local BH1750_RESET			    =   0x07	-- reset
local BH1750_CON_H_RES_MODE	    =   0x10	-- Continuously H-Resolution Mode
local BH1750_CON_H_RES_MODE2	=   0x11	-- Continuously H-Resolution Mode2
local BH1750_CON_L_RES_MODE	    =   0x13	-- Continuously L-Resolution Mode
local BH1750_ONE_H_RES_MODE	    =   0x20	-- One Time H-Resolution Mode
local BH1750_ONE_H_RES_MODE2	=   0x21	-- One Time H-Resolution Mode2
local BH1750_ONE_L_RES_MODE	    =   0x23	-- One Time L-Resolution Mode

local function i2c_send(data)
    i2c.send(i2cid, i2cslaveaddr, data)
end
local function i2c_recv(num)
    local revData = i2c.recv(i2cid, i2cslaveaddr, num)

    return revData
end

local function bh1750_power_on()
    i2c_send(BH1750_POWER_ON)
end

local function bh1750_power_down()
    i2c_send(BH1750_POWER_DOWN)
end

local function bh1750_set_measure_mode(mode,time)
    i2c_send(BH1750_RESET)
    i2c_send(mode)
    sys.wait(time)
end

local function bh1750_read_light()
    bh1750_set_measure_mode(BH1750_CON_H_RES_MODE2, 180)
    local _,light = pack.unpack(i2c_recv(2),">h")
    light = light / 1.2
    return light;
end

local function bh1750_test()
    sys.wait(4000)
    if i2c.setup(i2cid,i2c.SLOW) ~= i2c.SLOW then
        log.error("I2c.init","fail")
        return
    end
    bh1750_power_on()
    sys.wait(180)
    while true do
        log.info("bh1750_read_light", bh1750_read_light()*10)
        sys.wait(1000)
    end
end
sys.taskInit(bh1750_test)




