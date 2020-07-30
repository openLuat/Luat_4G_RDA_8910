--- 模块功能：ADC功能测试.
-- ADC测量精度(10bit，电压测量范围为0到1.85V，分辨率为1850/1024=1.8MV，测量精度误差为20MV)
-- 每隔1s读取一次ADC值
-- @author openLuat
-- @module adc.testAdc
-- @license MIT
-- @copyright openLuat
-- @release 2018.12.19

module(...,package.seeall)

--- ADC读取测试
-- @return 无
-- @usage read2()
local function read2()
    --ADC2接口用来读取电压
    local ADC_ID = 2
    -- 读取adc
    -- adcval为number类型，表示adc的原始值，无效值为0xFFFF
    -- voltval为number类型，表示转换后的电压值，单位为毫伏，无效值为0xFFFF

    local adcval,voltval = adc.read(ADC_ID)
    log.info("testAdc2.read",adcval,voltval)
end

--- ADC读取测试
-- @return 无
-- @usage read3()
local function read3()
    --ADC3接口用来读取电压
    local ADC_ID = 3
    -- 读取adc
    -- adcval为number类型，表示adc的原始值，无效值为0xFFFF
    -- voltval为number类型，表示转换后的电压值，单位为毫伏，无效值为0xFFFF

    local adcval,voltval = adc.read(ADC_ID)
    log.info("testAdc3.read",adcval,voltval)
end

-- 开启对应的adc通道
adc.open(2)
adc.open(3)

-- 定时每秒读取adc值
sys.timerLoopStart(read2,1000)
sys.timerLoopStart(read3,1000)

require"misc"
sys.timerLoopStart(function ()
    log.info("vbatt.read",misc.getVbatt())
end,1000)
