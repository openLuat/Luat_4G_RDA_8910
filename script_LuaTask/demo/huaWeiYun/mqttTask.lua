require "mqtt"
module(..., package.seeall)
-- 这里请填写华为云后台对接信息所展示的设备信息MQTT接入方式信息
local host, port ="iot-mqtts.cn-north-4.myhuaweicloud.com", 1883
--这里设置设备的device id和密钥，之前新建设备时得到的两个字符串
--实际使用中，这两个值可以存在SN中，在生产时一个个烧录进去
local device = "6063e66caaafca02d89db9bf_asd1234"
local secret = "able6123"
--同步NTP时间，因为鉴权需要用到UTC时间
require"ntp"
local function ntbcb(r)
    if r then
        sys.publish("NTP_OK")--时间同步完成后，发送命令，开始mqtt连接
    else
        ntp.timeSync(nil,ntbcb)
    end
end
ntp.timeSync(nil,ntbcb)--开始同步时间任务
--此处参照华为云文档，生成连接时使用的密钥
local function keyGenerate(key)
    local clk = os.date("*t",os.time()-3600*8)--获取UTC时间的table
    local timeStr = string.format("%02d%02d%02d%02d",clk.year,clk.month,clk.day,clk.hour)--时间戳
    local result = crypto.hmac_sha256(key,timeStr):lower()
    log.info("keyGenerate",timeStr,key,result)
    if crypto.hmac_sha256 then
        return result
    else
        log.error("crypto.hmac_sha256","please update your lod version, higher than 0034!")
        rtos.poweroff()
    end
end

--socket.setSendMode(1)
-- 测试MQTT的任务代码
sys.taskInit(function()
    sys.waitUntil("NTP_OK")--等待时间同步成功
    while true do
        while not socket.isReady() do sys.wait(1000) end
        local clk = os.date("*t",os.time()-3600*8)--获取UTC时间的table
        local mqttc = mqtt.client(
            device.."_0_0_"..string.format("%02d%02d%02d%02d",clk.year,clk.month,clk.day,clk.hour),--时间戳鉴权模式
            300,
            device,
            keyGenerate(secret))
        while not mqttc:connect(host, port, "tcp_ssl",{caCert="hw.crt"}) do sys.wait(2000) end
        --topic订阅规则详细请见华为云文档：https://support.huaweicloud.com/api-IoT/iot_06_3008.html#ZH-CN_TOPIC_0172230104
        if mqttc:subscribe("/huawei/v1/devices/"..device.."/command/json") then
            while true do
                local r, data, param = mqttc:receive(120000, "pub_msg")
                if r then
                    log.info("这是收到了服务器下发的消息:", data.payload or "nil")
                    sys.publish("rev_msg",data.payload)--把收到的数据推送出去
                elseif data == "pub_msg" then
                    log.info("这是收到了订阅的消息和参数显示:", param)
                    --topic订阅规则详细请见华为云文档
                    mqttc:publish("/huawei/v1/devices/"..device.."/data/json", param)
                elseif data == "timeout" then
                    --等待超时，进行下一轮等待
                else
                    break
                end
            end
        end
        mqttc:disconnect()
    end
end)
--接收到mqtt之后，对数据进行处理
sys.subscribe("rev_msg",function(data)
    local t,r,e = json.decode(data)--解包收到的json数据，具体参考手册：https://support.huaweicloud.com/api-IoT/iot_06_3011.html
    if r and type(t)=="table" then
        log.info("receive.msgType",t.msgType)--表示平台下发的请求，固定值“cloudReq”
        log.info("receive.serviceId",t.serviceId)--设备服务的ID
        log.info("receive.cmd",t.cmd)--服务的命令名，参见profile的服务命令定义
        log.info("receive.mid",t.mid)--2字节无符号的命令id，平台内部分配（范围1-65535），设备命令响应平台时，需要返回该值
        if t.cmd == "testcmd" then--匹配上了之前写的cmd名称
            log.info("receive.paras.testControl",t.paras.testControl)
            local clk = os.date("*t",os.time()-3600*8)--获取UTC时间的table
            --组包回复用的json，具体参考手册：https://support.huaweicloud.com/api-IoT/iot_06_3012.html
            local reply = {
                msgType = "deviceRsp",--固定值“deviceRsp”，表示设备的应答消息
                mid = t.mid,--2字节无符号的命令ID，根据平台下发命令时的mid返回给平台。建议在消息中携带此参数
                errcode = 0,--请求处理的结果码。“0”表示成功。“1”表示失败
                body = {--命令的应答，具体字段由profile定义
                    testReply = "done",--这是之前后台设置的那个
                }
            }
            sys.publish("pub_msg",json.encode(reply))--上报返回的报文
            --组包上报用的json，具体参考手册：https://support.huaweicloud.com/api-IoT/iot_06_3010.html
            local upload = {
                msgType = "deviceReq",--表示设备上报数据，固定值“deviceReq”
                data = {--一组服务的数据（具体结构参考下表ServiceData定义表），当需要上传批量数据时，可在该字段中添加数据
                    {
                        serviceId = "testServer",--设备服务的ID
                        serviceData = {--一个服务的数据，具体字段在profile里定义
                            testProperty = t.paras.testControl,--把刚刚下发的东西，上报上去
                        },
                        eventTime = string.format("%02d%02d%02d%02d%02d%02dZ",--设备采集数据UTC时间（格式：yyyyMMddTHHmmssZ）
                                    clk.year,clk.month,clk.day,clk.hour,clk.min,clk.sec)--时间戳
                    },
                }
            }
            sys.publish("pub_msg",json.encode(upload))--上报返回的报文
        end
    else
        log.info("json.decode error",e)
    end
end)