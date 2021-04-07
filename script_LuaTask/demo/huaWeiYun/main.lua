PROJECT = "HWMQTT"
VERSION = "1.0.0"
--加载日志功能模块，并且设置日志输出等级
require "log"
LOG_LEVEL = log.LOGLEVEL_TRACE
require "sys"
require "net"
--每1分钟查询一次GSM信号强度
--每1分钟查询一次基站信息
net.startQueryAll(60000, 60000)

--此处关闭RNDIS网卡功能
--否则，模块通过USB连接电脑后，会在电脑的网络适配器中枚举一个RNDIS网卡，电脑默认使用此网卡上网，导致模块使用的sim卡流量流失
--如果项目中需要打开此功能，把ril.request("AT+RNDISCALL=0,1")修改为ril.request("AT+RNDISCALL=1,1")即可
--注意：core固件：V0030以及之后的版本、V3028以及之后的版本，才以稳定地支持此功能
ril.request("AT+RNDISCALL=0,1")

--加载硬件看门狗功能模块
--require "wdt"
--wdt.setup(pio.P0_30, pio.P0_31)
--加载网络指示灯功能模块
require "netLed"
pmd.ldoset(15,pmd.LDO_VLCD)
netLed.setup(true,pio.P0_1,pio.P0_4)
--加载MQTT功能测试模块
require "mqttTask"
--启动系统框架
sys.init(0, 0)
sys.run()