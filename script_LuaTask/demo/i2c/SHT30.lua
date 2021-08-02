--- 模块功能：SHT30温湿度传感器
-- @author LALALALA
-- @module SHT30
-- @license MIT
-- @copyright openLuat
-- @release 2021.6.2
module(..., package.seeall)
require "utils"
require "pm"
pm.wake("WORK") -- 模块保持唤醒
local i2cId = 2 -- core 0025版本之前，0、1、2都表示i2c 2
-- core 0025以及之后的版本，1、2、3分别表示i2c 1、2、3

local function crc_8(data) -- SHT30获取温湿度结果crc校验
    local crc = 0xFF
    local len = #data
    for i = 1, len do
        crc = bit.bxor(crc, data[i])
        for j = 1, 8 do
            crc = crc * 2
            if crc > 0x100 then
                crc = bit.band(bit.bxor(crc, 0x31), 0xff)
            end
        end
    end
    return crc
end

sys.taskInit(function()
    sys.wait(5000)
    while true do
        local s = i2c.setup(i2cId, 1000000) -- 打开I²C通道
        local t, h -- 定义局部变量，用以保存温度值和湿度值
        local tempCrc = {} -- 定义局部表，保存获取的温度数据，便于进行crc校验
        local humiCrc = {} -- 定义局部表，保存获取的湿度数据，便于进行crc校验
        local w = i2c.send(2, 0x44, {0x2c, 0x06}) -- 发送单次采集命令
        sys.wait(10) -- 等待采集
        local r = i2c.recv(2, 0x44, 6) -- 读取数据采集结果

        -- b：温度高八位     c：温度低八位    d：b和c的crc校验值     e：湿度高八位      f：湿度低八位       g：e和f的crc校验值
        local a, b, c, d, e, f, g = pack.unpack(r, "b6")
        table.insert(tempCrc, b) -- 将温度高八位和温度低八位存入表中，稍后进行crc校验
        table.insert(tempCrc, c)
        table.insert(humiCrc, e) -- 将湿度高八位和湿度低八位存入表中，稍后进行crc校验
        table.insert(humiCrc, f)

        local result1 = crc_8(tempCrc) -- 温度数据crc校验
        local result2 = crc_8(humiCrc) -- 湿度数据crc校验

        --[[ if d == result1 and g == result2 then
            t = -45 + 175 * ((b * 256 + c) / 65535) -- 根据SHT30传感器手册给的公式计算温度和湿度
            h = 100 * ((e * 256 + f) / 65535)
            log.warn("这里是温度", t) -- 打印温度
            log.warn("这里是湿度", h) -- 打印湿度
        else
            log.warn("crc校验失败")
        end ]]

        if d == result1 and g == result2 then -- 将数据放大100倍，便于不带float的固件使用
            t = ((4375 * (b * 256 + c)) / 16384) - 4500 --根据SHT30传感器手册给的公式计算温度和湿度
            h = ((2500 * (e * 256 + f)) / 16384)
            log.warn("这里是温度", t / 100 .. "." .. t % 100) -- 打印温度
            log.warn("这里是湿度", h / 100 .. "." .. h % 100) -- 打印湿度
        else
            log.warn("crc校验失败")
        end

        i2c.close(i2cId) -- 关闭I²C通道
        sys.wait(1000) -- task挂起一秒
    end
end)
