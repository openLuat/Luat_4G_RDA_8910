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




