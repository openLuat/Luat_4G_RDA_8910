--- 模块功能：GPIO功能测试.
-- @author openLuat
-- @module gpio.testGpioSingle
-- @license MIT
-- @copyright openLuat
-- @release 2018.03.27

module(...,package.seeall)

require"pins"

--[[
有些GPIO需要打开对应的ldo电压域才能正常工作，电压域和对应的GPIO关系如下
pmd.ldoset(x,pmd.LDO_VSIM1) -- GPIO 29、30、31

pmd.ldoset(x,pmd.LDO_VLCD) -- GPIO 0、1、2、3、4
--注意：
--Air724 A11以及之前的开发板丝印有误:
--丝印中的IO_0、IO_1、IO_2、IO_3、IO_4并不对应GPIO0、1、2、3、4
--丝印中的LCD_DIO、LCD_RS、LCD_CLK、LCD_CS对应GPIO0、1、2、3；模块的LCD_SEL引脚对应GPIO4


pmd.ldoset(x,pmd.LDO_VMMC) -- GPIO 24、25、26、27、28
x=0时：关闭LDO
x=1时：LDO输出1.716V
x=2时：LDO输出1.828V
x=3时：LDO输出1.939V
x=4时：LDO输出2.051V
x=5时：LDO输出2.162V
x=6时：LDO输出2.271V
x=7时：LDO输出2.375V
x=8时：LDO输出2.493V
x=9时：LDO输出2.607V
x=10时：LDO输出2.719V
x=11时：LDO输出2.831V
x=12时：LDO输出2.942V
x=13时：LDO输出3.054V
x=14时：LDO输出3.165V
x=15时：LDO输出3.177V
]]


local level = 0
--GPIO18配置为输出，默认输出低电平，可通过setGpio18Fnc(0或者1)设置输出电平
local setGpio18Fnc = pins.setup(pio.P0_18,0)
sys.timerLoopStart(function()
    level = level==0 and 1 or 0
    setGpio18Fnc(level)
    log.info("testGpioSingle.setGpio18Fnc",level)
end,1000)

--GPIO19配置为输入，可通过getGpio19Fnc()获取输入电平
local getGpio19Fnc = pins.setup(pio.P0_19)
sys.timerLoopStart(function()
    log.info("testGpioSingle.getGpio19Fnc",getGpio19Fnc())
end,1000)
--pio.pin.setpull(pio.PULLUP,pio.P0_19)  --配置为上拉
--pio.pin.setpull(pio.PULLDOWN,pio.P0_19)  --配置为下拉
--pio.pin.setpull(pio.NOPULL,pio.P0_19)  --不配置上下拉



function gpio13IntFnc(msg)
    log.info("testGpioSingle.gpio13IntFnc",msg,getGpio13Fnc())
    --上升沿中断
    if msg==cpu.INT_GPIO_POSEDGE then
    --下降沿中断
    else
    end
end

--GPIO13配置为中断，可通过getGpio13Fnc()获取输入电平，产生中断时，自动执行gpio13IntFnc函数
getGpio13Fnc = pins.setup(pio.P0_13,gpio13IntFnc)


---------------------------------------脉冲统计个数功能演示---------------------------------------
--脉冲产生器：GPIO11一直输出1KHz的方波
pio.pin.pwm(pio.P0_11,500,500,-1)


--脉冲检测：GPIO23用来检测，短接GPIO11和GPIO23
sys.taskInit(function()
    --关闭软件和硬件防抖功能
    pio.pin.setdebounce(0xffffffff)
    --配置GPIO23位脉冲检测模式
    pio.pin.setdir(pio.INT,pio.P0_23,pio.CONT)
    --恢复默认防抖配置20毫秒
    pio.pin.setdebounce(20)
    
    --每隔一秒检测一次输入脉冲的数量
    --检测1分钟
    local seconds = 0
    while seconds<60 do
        -- 读取检测到的脉冲个数，数据为table类型，格式如下：
        -- {
        --     low = 10, -- 低电平个数
        --     high = 10, -- 高电平个数
        --     duration = 2000000, -- 距离上次读取的时间（单位us）
        -- }
        local tPlusInfo = pio.pin.getval(pio.P0_23)
        log.info("testGpioSingle.gpio23 tPlusInfo",tPlusInfo.low,tPlusInfo.high,tPlusInfo.duration)
        sys.wait(1000)
        seconds = seconds+1
    end
    
    --关闭GPIO23脉冲检测功能
    pio.pin.close(pio.P0_23)
end)
---------------------------------------脉冲统计个数功能演示---------------------------------------


--[[
pmd.ldoset(1,pmd.LDO_VMMC)

getGpio24Fnc = pins.setup(24,nil,pio.PULLUP)
getGpio25Fnc = pins.setup(25,nil,pio.PULLUP)
getGpio26Fnc = pins.setup(26,nil,pio.PULLUP)
getGpio27Fnc = pins.setup(27,nil,pio.PULLUP)

sys.timerLoopStart(function()
    log.info("getGpio24Fnc",getGpio24Fnc())
    log.info("getGpio25Fnc",getGpio25Fnc())
    log.info("getGpio26Fnc",getGpio26Fnc())
    log.info("getGpio27Fnc",getGpio27Fnc())
end,2000)]]


--[[
pmd.ldoset(0,pmd.LDO_VLCD)
pins.setup(pio.P0_0,1)
levelTest = 0

pmd.ldoset(15,pmd.LDO_VMMC)
pins.setup(pio.P0_27,1)

pmd.ldoset(15,pmd.LDO_VSIM1)
pins.setup(pio.P0_29,1)
pins.setup(pio.P0_30,1)
pins.setup(pio.P0_31,1)


sys.timerLoopStart(function()
    pmd.ldoset(levelTest,pmd.LDO_VMMC)
    pmd.ldoset(levelTest,pmd.LDO_VLCD)
    pmd.ldoset(levelTest,pmd.LDO_VSIM1)
    log.info("levelTest",levelTest)
    
    levelTest = levelTest+1
    if levelTest>15 then levelTest=0 end
end,10000)
]]

--[[
local intCnt = 0
sys.taskInit(function()
    while true do
        local setGpio14Fnc = pins.setup(pio.P0_14,1)
        sys.wait(2000)
        log.info("intCnt",intCnt)
        sys.wait(2000)
        intCnt = 0
        for i=1,10 do
           setGpio14Fnc(0)
           sys.wait(3)
           setGpio14Fnc(1)
           sys.wait(3)
        end
    end
end)


function gpio15IntFnc(msg)
    log.info("testGpioSingle.gpio15IntFnc",msg,getGpio15Fnc())
    intCnt = intCnt+1
    --上升沿中断
    if msg==cpu.INT_GPIO_POSEDGE then
    --下降沿中断
    else
    end
end

pio.pin.setdebounce(2)
--GPIO13配置为中断，可通过getGpio13Fnc()获取输入电平，产生中断时，自动执行gpio13IntFnc函数
getGpio15Fnc = pins.setup(pio.P0_15,gpio15IntFnc)
]]




