--- 模块功能：onenet studio功能测试.
-- @module onenet
-- @author Dozingfiretruck
-- @license MIT
-- @copyright OpenLuat.com
-- @release 2021.4.7

module(...,package.seeall)

require "ntp"
require "pm"
require "misc"
require "mqtt"
require "utils"
require "patch"
require "socket"
require "http"
require "common"


-- 产品ID和产品动态注册秘钥
local ProductId = "vh8xhj9sxz"
local ProductSecret = "t7Ojq/VBDQO3r8l5nQXXPZdzZQ3JCY8riZMj87vX96c="

local onenet_mqttClient
--[[
函数名：getDeviceName
功能  ：获取设备名称
参数  ：无
返回值：设备名称
]]
local function getDeviceName()
    --默认使用设备的IMEI作为设备名称，用户可以根据项目需求自行修改
    return misc.getImei()

    --用户单体测试时，可以在此处直接返回阿里云的iot控制台上注册的设备名称，例如return "862991419835241"
    --return "862991419835241"
end

function onenet_publish()
    --sys.publish("APP_SOCKET_SEND_DATA")
    --mqtt发布主题根据自己需要修改
    local publish_data =
    {
        id = "123",
        version = "1.0",
        params = {},
    }
    local jsondata = json.encode(publish_data)
    onenet_mqttClient:publish("$sys/"..ProductId.."/"..getDeviceName().."/thing/property/post", jsondata, 0)
end

local function onenet_subscribe()
    --mqtt订阅主题，根据自己需要修改
    local onenet_topic = {
        ["$sys/"..ProductId.."/"..getDeviceName().."/thing/property/post/reply"]=0
    }
    if onenet_mqttClient:subscribe(onenet_topic) then
        return true
    else
        return false
    end
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

local function get_token()
    local version = '2018-10-31'
    -- 通过MQ实例名称访问MQ
    local res = "products/"..ProductId.."/devices/"..getDeviceName()
    -- 用户自定义token过期时间
    local et = tostring(os.time() + 3600)
    -- 签名方法，支持md5、sha1、sha256
    local method = 'sha256'
    -- 对access_key进行decode
    local key = crypto.base64_decode(ProductSecret,#ProductSecret)
    -- 计算sign
    local StringForSignature  = et .. '\n' .. method .. '\n' .. res ..'\n' .. version
    local sign1 = crypto.hmac_sha256(StringForSignature,key)
    local sign2 = sign1:fromHex()
    local sign = crypto.base64_encode(sign2,#sign2)
    -- value 部分进行url编码
    sign = string.urlEncode(sign)
    res = string.urlEncode(res)
    -- token参数拼接
    local token = string.format('version=%s&res=%s&et=%s&method=%s&sign=%s',version, res, et, method, sign)
    return token
end

--- MQTT客户端数据接收处理
-- @param onenet_mqttClient，MQTT客户端对象
-- @return 处理成功返回true，处理出错返回false
-- @usage mqttInMsg.proc(onenet_mqttClient)
local function proc(onenet_mqttClient)
    local result,data
    while true do
        result,data = onenet_mqttClient:receive(60000,"APP_SOCKET_SEND_DATA")
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

local function onenet_iot()
    while true do
        if not socket.isReady() and not sys.waitUntil("IP_READY_IND", rstTim) then sys.restart("网络初始化失败!") end
        local clientid = getDeviceName()
        local username = ProductId
        local password = get_token()
        --创建一个MQTT客户端
        onenet_mqttClient = mqtt.client(clientid,300,username,password)
        --阻塞执行MQTT CONNECT动作，直至成功
        while not  onenet_mqttClient:connect("218.201.45.7",1883) do sys.wait(2000) end
        log.info("mqtt连接成功")

        --订阅主题
        if onenet_subscribe() then
            log.info("mqtt订阅成功")
            --循环处理接收和发送的数据
            while true do
                mqtt_ready = true
                if not proc(onenet_mqttClient) then log.error("mqttTask.mqttInMsg.proc error") break end
            end
        else
            log.info("mqtt订阅失败")
        end
        mqtt_ready = false
        --断开MQTT连接
        onenet_mqttClient:disconnect()
    end
end

local function iot()
    if not socket.isReady() and not sys.waitUntil("IP_READY_IND", rstTim) then sys.restart("网络初始化失败!") end
    while not ntp.isEnd() do sys.wait(1000) end
    onenet_iot()
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
