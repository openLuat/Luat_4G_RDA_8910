--- 模块功能：GPIO功能测试.
-- @author openLuat
-- @module gpio.testGpioSingle
-- @license MIT
-- @copyright openLuat
-- @release 2018.03.27

module(...,package.seeall)

require"pins"

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

--[[
pmd.ldoset(x,pmd.LDO_VMMC) -- GPIO 25、26、27、28、29、30
pmd.ldoset(x,pmd.LDO_VLCD) -- GPIO 39、40、41、42、56、57、58
x=0时：关闭LDO
x=1时：LDO输出1.8V
x=2时：LDO输出1.9V
x=3时：LDO输出2.5V
x=4时：LDO输出2.8V
x=5时：LDO输出2.9V
x=6时：LDO输出3.1V
x=7时：LDO输出3.3V
x=8时：LDO输出1.7V
]]

