--- 模块功能：阿里云功能测试.
-- 支持数据传输和OTA功能
-- @author openLuat
-- @module aLiYun.testALiYun
-- @license MIT
-- @copyright openLuat
-- @release 2018.04.14

module(...,package.seeall)

require"aLiYun"
require"misc"
require"pm"

--地域和可用区，详情参考：https://help.aliyun.com/document_detail/40654.html?spm=a2c4g.11186623.2.22.797d7c80uIGAZ7
--根据自己的产品所在地域修改
local REGION_ID = "cn-shanghai"

--三元组信息，根据实际值自行修改
--注意：这里默认的三元组无法连接上阿里云
local PRODUCT_KEY = "yourProductKey"
local PRODUCE_SECRET = "8vOb5miTNRLrFecG"
local DEVICE_NAME = "862991234567890"

--[[
函数名：getDeviceName
功能  ：获取设备名称
参数  ：无
返回值：设备名称
]]
local function getDeviceName()
    return DEVICE_NAME
end


--[[
函数名：getDeviceSecret
功能  ：获取设备密钥
参数  ：无
返回值：设备密钥
]]
local function getDeviceSecret()
    --默认使用设备的SN作为设备密钥，用户可以根据项目需求自行修改
    return misc.getSn()
end

--[[
函数名：setDeviceSecret
功能  ：修改设备密钥
参数  ：设备密钥
返回值：无
]]
local function setDeviceSecret(s)
    --默认使用设备的SN作为设备密钥，用户可以根据项目需求自行修改
    misc.setSn(s)
end

--阿里云客户端是否处于连接状态
local sConnected

local publishCnt = 1

--[[
函数名：pubqos1testackcb
功能  ：发布1条qos为1的消息后收到PUBACK的回调函数
参数  ：
		usertag：调用mqttclient:publish时传入的usertag
		result：true表示发布成功，false或者nil表示失败
返回值：无
]]
local function publishTestCb(result,para)
    log.info("testALiYun.publishTestCb",result,para)
    sys.timerStart(publishTest,20000)
    publishCnt = publishCnt+1
end

--发布一条QOS为1的消息
function publishTest()
    if sConnected then
        --注意：在此处自己去控制payload的内容编码，aLiYun库中不会对payload的内容做任何编码转换
        aLiYun.publish("/"..PRODUCT_KEY.."/"..getDeviceName().."/update","qos1data",1,publishTestCb,"publishTest_"..publishCnt)
    end
end

---数据接收的处理函数
-- @string topic，UTF8编码的消息主题
-- @number qos，消息质量等级
-- @string payload，原始编码的消息负载
local function rcvCbFnc(topic,qos,payload)
    log.info("testALiYun.rcvCbFnc",topic,qos,payload)
end

--- 连接结果的处理函数
-- @bool result，连接结果，true表示连接成功，false或者nil表示连接失败
local function connectCbFnc(result)
    log.info("testALiYun.connectCbFnc",result)
    sConnected = result
    if result then
        --订阅主题，不需要考虑订阅结果，如果订阅失败，aLiYun库中会自动重连
        --根据自己的项目需要订阅主题，下面注释掉的一行代码中的主题是非法的，所以不能打开，一旦打开，会导致订阅失败
        --aLiYun.subscribe({["/"..PRODUCT_KEY.."/"..getDeviceName().."/get"]=0, ["/"..PRODUCT_KEY.."/"..getDeviceName().."/get"]=1})
        --注册数据接收的处理函数
        aLiYun.on("receive",rcvCbFnc)
        --PUBLISH消息测试
        publishTest()
    end
end

aLiYun.on("connect",connectCbFnc)
--setMqtt接口不是必须的，aLiYun.lua中有这个接口设置的参数默认值，如果默认值满足不了需求，参考下面注释掉的代码，去设置参数
--aLiYun.setMqtt(0)
aLiYun.setRegion(REGION_ID)
aLiYun.setConnectMode("direct",PRODUCT_KEY..".iot-as-mqtt."..REGION_ID..".aliyuncs.com",1883)
aLiYun.setup(PRODUCT_KEY,PRODUCE_SECRET,getDeviceName,getDeviceSecret,setDeviceSecret)

--要使用阿里云OTA功能，必须参考本文件124或者126行aLiYun.setup去配置参数
--然后加载阿里云OTA功能模块(打开下面的代码注释)
require"aLiYunOta"
--如果利用阿里云OTA功能去下载升级合宙模块的新固件，默认的固件版本号格式为：_G.PROJECT.."_".._G.VERSION.."_"..sys.getcorever()，下载结束后，直接重启，则到此为止，不需要再看下文说明


--如果下载升级合宙模块的新固件，下载结束后，自己控制是否重启
--如果利用阿里云OTA功能去下载其他升级包，例如模块外接的MCU升级包，则根据实际情况，打开下面的代码注释，调用设置接口进行配置和处理
--设置MCU当前运行的固件版本号
--aLiYunOta.setVer("MCU_VERSION_1.0.0")
--设置新固件下载后保存的文件名
--aLiYunOta.setName("MCU_FIRMWARE.bin")

--[[
函数名：otaCb
功能  ：新固件文件下载结束后的回调函数
        通过uart1（115200,8,uart.PAR_NONE,uart.STOP_1）把下载成功的文件，发送到MCU，发送成功后，删除此文件
参数  ：
		result：下载结果，true为成功，false为失败
		filePath：新固件文件保存的完整路径，只有result为true时，此参数才有意义
返回值：无
]]
local function otaCb(result,filePath)
    log.info("testALiYun.otaCb",result,filePath)
    if result then
        local uartID = 1
        sys.taskInit(
            function()                
                local fileHandle = io.open(filePath,"rb")
                if not fileHandle then
                    log.error("testALiYun.otaCb open file error")
                    if filePath then os.remove(filePath) end
                    return
                end
                
                pm.wake("UART_SENT2MCU")
                uart.on(uartID,"sent",function() sys.publish("UART_SENT2MCU_OK") end)
                uart.setup(uartID,115200,8,uart.PAR_NONE,uart.STOP_1,nil,1)
                while true do
                    local data = fileHandle:read(1460)
                    if not data then break end
                    uart.write(uartID,data)
                    sys.waitUntil("UART_SENT2MCU_OK")
                end
                --此处上报新固件版本号（仅供测试使用）
                --用户开发自己的程序时，根据下载下来的新固件，执行升级动作
                --升级成功后，调用aLiYunOta.setVer上报新固件版本号
                --如果升级失败，调用aLiYunOta.setVer上报旧固件版本号
                aLiYunOta.setVer("MCU_VERSION_1.0.1")
                
                uart.close(uartID)
                pm.sleep("UART_SENT2MCU")
                fileHandle:close()
                if filePath then os.remove(filePath) end
            end
        )

        
    else
        --文件使用完之后，如果以后不再需求，需要自行删除
        if filePath then os.remove(filePath) end
    end    
end


--设置新固件下载结果的回调函数
--aLiYunOta.setCb(otaCb)

