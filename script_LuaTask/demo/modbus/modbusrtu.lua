--- modbus模块功能
-- @module modbus
-- @author Dozingfiretruck
-- @license MIT
-- @copyright openLuat
-- @release 2020.12.17

module(...,package.seeall)

require"utils"
require"common"

--保持系统处于唤醒状态，此处只是为了测试需要，所以此模块没有地方调用pm.sleep("testUart")休眠，不会进入低功耗休眠状态
--在开发“要求功耗低”的项目时，一定要想办法保证pm.wake("modbusrtu")后，在不需要串口时调用pm.sleep("testUart")
pm.wake("modbusrtu")

local uart_id = 1
local uart_baud = 9600
--[[
--   起始        地址    功能代码    数据    CRC校验    结束
-- 3.5 字符     8 位      8 位    N x 8 位   16 位   3.5 字符
--- 发送modbus数据函数
@function   modbus_send
@param      slaveaddr : 从站地址
            Instructions:功能码
		    reg : 寄存器编号
            value : 写入寄存器值或读取寄存器个数,2字节
@return     无
@usage modbus_send("0x01","0x01","0x0101","0x04")
]]
local function modbus_send(slaveaddr,Instructions,reg,value)
    local data = (string.format("%02x",slaveaddr)..string.format("%02x",Instructions)..string.format("%04x",reg)..string.format("%04x",value)):fromHex()
    local modbus_crc_data= pack.pack('<h', crypto.crc16("MODBUS",data))
    local data_tx = data..modbus_crc_data
    uart.write(uart_id,data_tx)
end

local function modbus_read()
    local cacheData = ""
    while true do
        local s = uart.read(uart_id,1)
        if s == "" then
            if not sys.waitUntil("UART_RECEIVE",35000/uart_baud) then
                -- 3.5个字符的时间间隔，只是用在RTU模式下面，因为RTU模式没有开始符和结束符，
                -- 两个数据包之间只能靠时间间隔来区分，Modbus定义在不同的波特率下，间隔时间是不一样的，
                -- 所以就是3.5个字符的时间，波特率高，这个时间间隔就小，波特率低，这个时间间隔相应就大
                -- 4800  = 7.297ms
                -- 9600  = 3.646ms
                -- 19200  = 1.771ms
                -- 38400  = 0.885ms
                --uart接收数据，如果 35000/uart_baud 毫秒没有收到数据，则打印出来所有已收到的数据，清空数据缓冲区，等待下次数据接收
                --注意：
                --因为在整个GSM模块软件系统中，软件定时器的精确性无法保证，例如本demo配置的是100毫秒，在系统繁忙时，实际延时可能远远超过100毫秒，达到200毫秒、300毫秒、400毫秒等
                --设置的延时时间越短，误差越大
                if cacheData:len()>0 then
                    local a,_ = string.toHex(cacheData)
                    log.info("modbus接收数据:",a)
                    --用户逻辑处理代码
                    --
                    cacheData = ""
                end
            end
        else
            cacheData = cacheData..s
        end
    end
end

--注册串口的数据发送通知函数
uart.on(uart_id,"receive",function() sys.publish("UART_RECEIVE") end)
--配置并且打开串口
uart.setup(uart_id,uart_baud,8,uart.PAR_NONE,uart.STOP_1)
--启动串口数据接收任务
sys.taskInit(modbus_read)

sys.taskInit(function ()
    while true do
        sys.wait(5000)
        modbus_send("0x01","0x01","0x0101","0x04")
    end
end)


