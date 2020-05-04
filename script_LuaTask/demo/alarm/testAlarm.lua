--- 模块功能：闹钟功能测试(支持开机闹钟和关机闹钟，同时只能存在一个闹钟，如果想实现多个闹钟，等当前闹钟触发后，再次调用闹钟设置接口去配置下一个闹钟).
-- @author openLuat
-- @module alarm.testAlarm
-- @license MIT
-- @copyright openLuat
-- @release 2018.03.14

require"ntp"
require "sys"
require"misc"
module(...,package.seeall)


sys.taskInit(function()
    sys.wait(10000)
    log.info("alarm test start")
    misc.setClock({year=2020,month=5,day=1,hour=12,min=12,sec=12})
    sys.wait(2000)
    local onTimet = os.date("*t",os.time() + 60)  --下次要开机的时间为60秒后
    log.info("alarm restart time", 60)
    rtos.set_alarm(1,onTimet.year,onTimet.month,onTimet.day,onTimet.hour,onTimet.min,onTimet.sec)   --设定闹铃
    --如果要测试关机闹钟，打开下面这2行代码
    --sys.wait(2000)
    --rtos.poweroff()
end)

--[[
函数名：alarMsg
功能  ：开机闹钟事件的处理函数
参数  ：无
返回值：无
]]
local function alarMsg()
	print("alarMsg")
end

--如果是关机闹钟开机，则需要软件主动重启一次，才能启动GSM协议栈
if rtos.poweron_reason()==rtos.POWERON_ALARM then
	sys.restart("ALARM")
end

--注册闹钟模块
rtos.init_module(rtos.MOD_ALARM)
--注册闹钟消息的处理函数（如果是开机闹钟，闹钟事件到来时会调用alarmsg）
rtos.on(rtos.MSG_ALARM,alarMsg)
