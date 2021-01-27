--- 模块功能：腾讯云平台
-- @module txiot
-- @author Dozingfiretruck
-- @license MIT
-- @copyright OpenLuat.com
-- @release 2020.12.31

module(...,package.seeall)

require "ntp"
require "misc"
require "mqtt"
require "utils"
require "patch"
require "socket"
require "http"
require "common"


-- 产品ID和产品动态注册秘钥
local ProductId = "5FCW79CXYD"
local ProductSecret = "XOBuiSs4EUCjmP5NcFWrwdOe"

local tx_mqttClient
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

function txiot_publish()
    --sys.publish("APP_SOCKET_SEND_DATA")
    --mqtt发布主题
    tx_mqttClient:publish("$thing/up/property/"..ProductId.."/"..getDeviceName(), "publish from luat mqtt client", 0)
end

-- 无网络重启时间，飞行模式启动时间
local rstTim, flyTim = 600000, 300000
local enrol_end = false
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

local function cbFnc(result,prompt,head,body)
    log.info("testHttp.cbFnc",result,prompt,head,body)
    local dat, result, errinfo = json.decode(body)
    if result then
        if dat.code==0 then
            io.writeFile("/txiot.dat", body)
            log.info("腾讯云注册设备成功:", body)
        else
            log.info("腾讯云设备注册失败:", body)
        end
        enrol_end = true
    end
end

local function device_enrol()
    local deviceName = getDeviceName()
    local nonce = math.random(1,100)
    local timestamp = os.time()
    local data = "deviceName="..deviceName.."&nonce="..nonce.."&productId="..ProductId.."&timestamp="..timestamp
    local hmac_sha1_data = crypto.hmac_sha1(data,#data,ProductSecret,#ProductSecret):lower()
    local signature = crypto.base64_encode(hmac_sha1_data,#hmac_sha1_data)
    local tx_body = {
        deviceName=deviceName,
        nonce=nonce,
        productId=ProductId,
        timestamp=timestamp,
        signature=signature,
    }
    local tx_body_json = json.encode(tx_body)
    http.request("POST","https://ap-guangzhou.gateway.tencentdevices.com/register/dev",nil,{["Content-Type"]="application/json; charset=UTF-8"},tx_body_json,30000,cbFnc)
end

local function tencent_iot()
    if not io.exists("/txiot.dat") then device_enrol() while not enrol_end do sys.wait(100) end end
    if not io.exists("/txiot.dat") then device_enrol() log.warn("设备注册失败或设备已注册") return end
    local dat = json.decode(io.readFile("/txiot.dat"))
    local clientid = ProductId .. getDeviceName()    --生成 MQTT 的 clientid 部分, 格式为 ${productid}${devicename}
    local connid = math.random(10000,99999)
    local expiry = tostring(os.time() + 3600)
    local username = string.format("%s;12010126;%s;%s", clientid, connid, expiry)   --生成 MQTT 的 username 部分, 格式为 ${clientid};${sdkappid};${connid};${expiry}
    local payload = json.decode(crypto.aes_decrypt("CBC","ZERO",crypto.base64_decode(dat.payload, #dat.payload),string.sub(ProductSecret,1,16),"0000000000000000"))
    local password
    if payload.encryptionType==2 then
        local raw_key = crypto.base64_decode(payload.psk, #payload.psk) --生成 MQTT 的 设备密钥 部分
        password = crypto.hmac_sha256(username, raw_key):lower() .. ";hmacsha256" --根据物联网通信平台规则生成 password 字段
    elseif payload.encryptionType==1 then
        io.writeFile("/client.crt", payload.clientCert)
        io.writeFile("/client.key", payload.clientKey)
    end
    while true do
        if not socket.isReady() and not sys.waitUntil("IP_READY_IND", rstTim) then sys.restart("网络初始化失败!") end
        --创建一个MQTT客户端
        tx_mqttClient = mqtt.client(clientid,300,username,password)
        --阻塞执行MQTT CONNECT动作，直至成功
        if payload.encryptionType==2 then
            while not tx_mqttClient:connect(ProductId..".iotcloud.tencentdevices.com",1883,"tcp",nil,2000) do sys.wait(2000) end
        elseif payload.encryptionType==1 then
            while not tx_mqttClient:connect(ProductId..".iotcloud.tencentdevices.com",8883,"tcp_ssl",{clientCert="/client.crt",clientKey="/client.key"},2000) do sys.wait(2000) end
        end
            log.info("mqtt连接成功")
            tx_mqttClient:publish("$thing/up/property/"..ProductId.."/"..getDeviceName(), "publish from luat mqtt client", 0)
            --mqtt订阅主题
            local txiot_subscribetopic = {
                ["$thing/down/property/"..ProductId.."/"..getDeviceName()]=0
            }
            --订阅主题
            if tx_mqttClient:subscribe(txiot_subscribetopic, nil) then
                log.info("mqtt订阅成功")
                --循环处理接收和发送的数据
                while true do
                    mqtt_ready = true
                    if not proc(tx_mqttClient) then log.error("mqttTask.mqttInMsg.proc error") break end
                end
            else
                log.info("mqtt订阅失败")
            end
            mqtt_ready = false
        --断开MQTT连接
        tx_mqttClient:disconnect()
    end
end

local function iot()
    ntp.timeSync()
    if not socket.isReady() and not sys.waitUntil("IP_READY_IND", rstTim) then sys.restart("网络初始化失败!") end
    while not ntp.isEnd() do sys.wait(1000) end
    tencent_iot()
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
