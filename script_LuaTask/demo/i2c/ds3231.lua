--- 模块功能：DS3231
-- @module DS3231
-- @author Dozingfiretruck
-- @license MIT
-- @copyright OpenLuat.com
-- @release 2021.03.14

module(...,package.seeall)
require"utils"
require"bit"

pm.wake("ds3231")

local i2cid = 2 --i2cid

local DS3231_ADDRESS            =   0x68 -- address pin low (GND), default for InvenSense evaluation board
local i2cslaveaddr              =   DS3231_ADDRESS --slave address

---器件通讯地址
local DS3231_CHIP_ID_ADDR       =   0xD0
local DS3231_ID                 =   0x58

---DS3231所用地址

local REG_SEC				    =   0x00
local REG_MIN				    =   0x01
local REG_HOUR			        =   0x02
local REG_DAY				    =   0x03
local REG_WEEK			        =   0x04
local REG_MON				    =   0x05
local REG_YEAR			        =   0x06
local REG_ALM1_SEC  		    =   0x07
local REG_ALM1_MIN 	  	        =   0x08
local REG_ALM1_HOUR     	    =   0x09
local REG_ALM1_DAY_DATE 	    =   0x0A
local REG_ALM2_MIN  		    =   0x0B
local REG_ALM2_HOUR     	    =   0x0C
local REG_ALM2_DAY_DATE 	    =   0x0D
local REG_CONTROL               =   0x0E
local REG_STATUS                =   0x0F
local REG_AGING_OFFSET          =   0x10
local REG_TEMP_MSB 		        =   0x11
local REG_TEMP_LSB 		        =   0x12


local function i2c_send(data)
    i2c.send(i2cid, i2cslaveaddr, data)
end
local function i2c_recv(data,num)
    i2c.send(i2cid, i2cslaveaddr, data)
    local revData = i2c.recv(i2cid, i2cslaveaddr, num)
    return revData
end

--器件初始化
local function DS3231_init()
    i2c_send({REG_CONTROL, 0x04})--close clock out
    log.info("i2c init_ok")
end

local function ds3231_get_temperature()
    local temp
    local T = i2c_recv(REG_TEMP_MSB,2)
    if bit.band(T:byte(1),0x80) then
        --negative temperature
        temp = T:byte(1)
        temp = temp - (bit.rshift(T:byte(2),6)*0.25)--0.25C resolution
    else
        --positive temperature
        temp =  T:byte(1)
        temp = temp + (bit.band(bit.rshift(T:byte(2),6),0x03)*0.25)
    end
	return temp;
end

local function bcd_to_hex(data)
    local hex = bit.rshift(data,4)*10+bit.band(data,0x0f)
    return hex;
end

local function hex_to_bcd(data)
    local hex = bit.lshift(data/10,4)+data%10
    return hex;
end

local function ds3231_read_time()
    -- read time
    local time_data = {}
    local data = i2c_recv(REG_SEC,7)
    time_data.tm_year  = bcd_to_hex(data:byte(7)) + 2000
    time_data.tm_mon   = bcd_to_hex(bit.band(data:byte(6),0x7f)) - 1
    time_data.tm_mday  = bcd_to_hex(data:byte(5))
    time_data.tm_hour  = bcd_to_hex(data:byte(3))
    time_data.tm_min   = bcd_to_hex(data:byte(2))
    time_data.tm_sec   = bcd_to_hex(data:byte(1))
	return time_data
end

local function ds3231_set_time(time)
    -- set time
    local data7 = hex_to_bcd(time.tm_year + 2000)
    local data6 = hex_to_bcd(time.tm_mon + 1)
    local data5 = hex_to_bcd(time.tm_mday)
    local data4 = hex_to_bcd(time.tm_wday+1)
    local data3 = hex_to_bcd(time.tm_hour)
    local data2 = hex_to_bcd(time.tm_min)
    local data1 = hex_to_bcd(time.tm_sec)
    i2c_send({REG_SEC, data1,data2,data3,data4,data5,data6,data7})
end

local function DS3231()
    sys.wait(4000)
    if i2c.setup(i2cid,i2c.SLOW) ~= i2c.SLOW then
        log.error("I2c.init","fail")
        return
    end
    DS3231_init()
    while true do
        log.info("ds3231_get_temperature", ds3231_get_temperature())
        local time = ds3231_read_time()
        log.info("ds3231_read_time",time.tm_year,time.tm_mon,time.tm_mday,time.tm_hour,time.tm_min,time.tm_sec)
        local set_time = {tm_year=2021,tm_mon=3,tm_mday=0,tm_wday=0,tm_hour=0,tm_min=0,tm_sec=0}
        ds3231_set_time(set_time)
        log.info("ds3231_read_time",time.tm_year,time.tm_mon,time.tm_mday,time.tm_hour,time.tm_min,time.tm_sec)
        sys.wait(1000)
    end
end
sys.taskInit(DS3231)




