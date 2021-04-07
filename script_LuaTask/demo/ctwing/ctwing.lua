--- 模块功能：ctwing平台
-- @module ctwingiot
-- @author Dozingfiretruck
-- @license MIT
-- @copyright OpenLuat.com
-- @release 2021.2.1

module(...,package.seeall)

require "ntp"
require "misc"
require "mqtt"
require "utils"
require "patch"
require "socket"
require "http"
require "common"


local DevicetId = "15027217123456789"
local DeviceSecret = "jnwnpBJvZGL5JDQKtnDjhGVn34gQ1a6uUKdhYYfAHSw"

local ctwing_mqttClient
--[[
函数名：getDeviceName
功能  ：获取设备名称
参数  ：无
返回值：设备名称
]]
local function getDeviceName()
    --默认使用设备的IMEI作为设备名称，用户可以根据项目需求自行修改
    return misc.getImei()
end

--mqtt订阅主题，根据自己需要修改
local ctwing_iot_subscribetopic = {
    ["test"]=0
}

function ctwingiot_publish()
    --sys.publish("APP_SOCKET_SEND_DATA")
    --mqtt发布主题根据自己需要修改
    --ctwing_mqttClient:publish("$thing/up/property/"..ProductId.."/"..getDeviceName(), "publish from luat mqtt client", 0)
    local body = {
        pci=-32768,
        rsrp=-32768,
        cell_id=-2147483648,
        sinr=-32768,
        ecl=-33333,
    }
    local body_json = json.encode(body)

    ctwing_mqttClient:publish("signal_report", body_json, 0)
end

-- 无网络重启时间，飞行模式启动时间
local rstTim, flyTim = 600000, 300000
local mqtt_ready = false
--- MQTT连接是否处于激活状态
-- @return 激活状态返回true，非激活状态返回false
-- @usage mqttTask.isReady()
function isReady()
    return mqtt_ready
end

--- MQTT客户端数据接收处理
-- @param mqttClient，MQTT客户端对象
-- @return 处理成功返回true，处理出错返回false
-- @usage mqttInMsg.proc(mqttClient)
local function proc(mqttClient)
    local result,data
    while true do
        result,data = mqttClient:receive(120000,"APP_SOCKET_SEND_DATA")
        --接收到数据
        if result then
            log.info("mqttInMsg.proc",data.topic,string.toHex(data.payload))

            --TODO：根据需求自行处理data.payload
        else
            break
        end
    end
    return result or data=="timeout" or data=="APP_SOCKET_SEND_DATA"
end


local function ctwing_iot()
    while true do
        if not socket.isReady() and not sys.waitUntil("IP_READY_IND", rstTim) then sys.restart("网络初始化失败!") end
        --创建一个MQTT客户端
        ctwing_mqttClient = mqtt.client(DevicetId,300,"123456789",DeviceSecret)
        --阻塞执行MQTT CONNECT动作，直至成功
            while not ctwing_mqttClient:connect("mqtt.ctwing.cn",1883,"tcp",nil,2000) do sys.wait(2000) end
            log.info("mqtt连接成功")

            --订阅主题
            if ctwing_mqttClient:subscribe(ctwing_iot_subscribetopic, nil) then
                log.info("mqtt订阅成功")
                --循环处理接收和发送的数据
                while true do
                    mqtt_ready = true
                    if not proc(ctwing_mqttClient) then log.error("mqttTask.mqttInMsg.proc error") break end
                end
            else
                log.info("mqtt订阅失败")
            end
            mqtt_ready = false
        --断开MQTT连接
        ctwing_mqttClient:disconnect()
    end
end

local function iot()
    ntp.timeSync()
    if not socket.isReady() and not sys.waitUntil("IP_READY_IND", rstTim) then sys.restart("网络初始化失败!") end
    while not ntp.isEnd() do sys.wait(1000) end
    ctwing_iot()
end

net.switchFly(false)
-- NTP同步失败强制重启
local tid = sys.timerStart(function()
    net.switchFly(true)
    sys.timerStart(net.switchFly, 5000, false)
end, flyTim)
sys.subscribe("IP_READY_IND", function()
    sys.timerStop(tid)
    log.info("---------------------- 网络注册已成功 ----------------------")
end)

sys.taskInit(iot)
