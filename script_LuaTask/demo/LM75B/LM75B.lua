module(..., package.seeall)
require "utils"
local i2cslaveaddr = 0x48 
local function read_am2320(id)
    i2c.close(id)
    if i2c.setup(id, i2c.SLOW, i2cslaveaddr) ~= i2c.SLOW then
        log.error("I2C.init is: fail ", id, i2cslaveaddr)
        i2c.close(id)
        return
    else
        local buf = i2c.read(2, 0x00, 2)
        log.info("LM75B", "HEX data:", buf:toHex())
        -- 传感器返回数据格式：
        --     1   2   3   4   5   6   7   8
        --  符号位 [ 温度数据（单位 0.5摄氏度）]
        if buf == nil or buf == 0 then
            return
        end
        local data = byte2bin(string.byte(buf)) .. byte2bin(string.byte(buf, 2))
        log.info("LM75", "DATA(full)", data)
        -- log.error("LM75"," buf LEN",string.len(buf))
        -- 提取符号位
        zero_tem = data:sub(1, 1)
        data = data:sub(2, 9)
        log.info("LM75", "DATA(2-9)", data)
        local _, tmp = pack.unpack(data, 'b8')
        if zero_tem == "0" then
            log.info("LM75B", "温度+", tmp / 2)
        else
            log.info("LM75B", "温度-", 128-tmp / 2)
        end

        return
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
        read_am2320(2)
        log.info("!!!", "************************END************************")
    end
end)
