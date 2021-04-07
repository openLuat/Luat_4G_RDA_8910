require "utils"
module(..., package.seeall)
local i2cslaveaddr = 0x5C -- 8bit地址为0xb8 7bit 为0x5C
local function i2c_open(id)
    if i2c.setup(id, i2c.SLOW) ~= i2c.SLOW then
        log.error("AM2320", "I2C.init is: fail")
        i2c.close(id)
        return
    else
        log.error("AM2320", "I2C.init is: succeed")
    end
    return i2c.SLOW
end

function read(id)
    i2c.send(id, i2cslaveaddr, 0x03)
    -- 查询功能码：0x03 查询的寄存器首地址：0 长度：4
    i2c.send(id, i2cslaveaddr, {0x03, 0x00, 0x04})
    sys.wait(2)
    local data = i2c.recv(id, i2cslaveaddr, 8)

    -- 传感器返回的8位数据格式：
    --    1       2       3       4       5       6       7       8
    --  0x03    0x04    0x03    0x39     0x01    0x15    0xE1    0XFE
    -- 功能码  数据长度   湿度高位 湿度数据 温度高位  温度低位 CRC低  CRC高

    if data == nil or data == 0 then
        return
    end
    -- log.info("AM2320", "buf data:", buf)
    log.info("AM2320", "HEX data:", data:toHex())
    i2c.close(id)

    local _, crc = pack.unpack(data, '<H', 7)
    data = data:sub(1, 6)
    if crc == crypto.crc16_modbus(data, 6) then
        local _, hum, tmp = pack.unpack(string.sub(data, 3, -1), '>H2')
        -- 正负温度处理
        if tmp >= 0x8000 then
            tmp = 0x8000 - tmp
        end
        tmp, hum = tmp / 10, hum / 10
        log.info("AM2320", "data(tmp hum):", tmp, hum)
        return tmp, hum
    end
end

function byte2bin(n)
    local t = {}
    for i = 7, 0, -1 do
        t[#t + 1] = math.floor(n / 2 ^ i)
        n = n % 2 ^ i
    end
    return table.concat(t)
end

sys.taskInit(function()
    while true do
        sys.wait(5000)
        log.info("!!!", "************************START************************")
        i2c_open(2)
        read(2)
        log.info("!!!", "************************END************************")
    end
end)
