--- 模块功能：SSD 1306驱动芯片 I2C屏幕显示测试
-- @author openLuat
-- @module ui.mono_i2c_ssd1306
-- @license MIT
-- @copyright openLuat
-- @release 2018.07.03

module(..., package.seeall)


-- i2cid 1,2,3对应硬件的I2C1,I2C2,I2C3
-- 之前的i2cid为0不再使用
local i2cid = 2

local i2cslaveaddr = 0x3c
--注意：此处的i2cslaveaddr是7bit地址
--如果i2c外设手册中给的是8bit地址，需要把8bit地址右移1位，赋值给i2cslaveaddr变量
--如果i2c外设手册中给的是7bit地址，直接把7bit地址赋值给i2cslaveaddr变量即可
--发起一次读写操作时，启动信号后的第一个字节是命令字节
--命令字节的bit0表示读写位，0表示写，1表示读
--命令字节的bit7-bit1,7个bit表示外设地址
--i2c底层驱动在读操作时，用 (i2cslaveaddr << 1) | 0x01 生成命令字节
--i2c底层驱动在写操作时，用 (i2cslaveaddr << 1) | 0x00 生成命令字节

--向屏幕发送命令字
local function lcd_write_cmd(val)
    --向从设备的寄存器地址0x00中写1字节的数据val
    i2c.write(i2cid,0x00,val)

    --该代码与下面的代码等价
    --向从设备i2cslaveaddr发送寄存器地址0x00与数据val
    --i2c.send(i2cid,i2cslaveaddr,{0x00,val})
end

--向屏幕发送数据
local function lcd_write_data(val)
    --向从设备的寄存器地址0x40中写1字节的数据val
    i2c.write(i2cid,0x40,val)

    --该代码与下面的代码等价
    --向从设备i2cslaveaddr发送寄存器地址0x40与数据val
    --i2c.send(i2cid,i2cslaveaddr,{0x40,val})
end


--[[
函数名：i2cShow
功能  ：打开i2c，并设置屏幕显示内容
参数  ：无
返回值：无
说明  : 此函数演示setup、send和recv接口的使用方式
]]
local function i2cShow()

    if i2c.setup(2,i2c.SLOW,0x48) ~= i2c.SLOW then
        print("testI2c.init fail")
        return
    else
        print("testI2c.init ok")
        i2c.send(2, 0x48, 0x11)
    end

        --i2c.close(2)
end

--显示内容
sys.timerLoopStart(function ()
    i2cShow()
end, 10000)
