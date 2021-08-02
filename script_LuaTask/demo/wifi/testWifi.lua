--- 模块功能：WIFI 功能测试
-- @author openLuat
-- @module testwifi
-- @license MIT
-- @copyright openLuat
-- @release 2020.05.11

module(...,package.seeall)

require"wifiScan"
require"lbsLoc"


sys.taskInit(function()
    while true do
        sys.wait(5000)
        
        wifiScan.request(function(result,cnt,tInfo)
            log.info("testWifi.scanCb",result,cnt)
            sys.publish("WIFI_SCAN_IND",result,cnt,tInfo)
        end)
        
        local _,result,cnt,tInfo = sys.waitUntil("WIFI_SCAN_IND")
        if result then
            for k,v in pairs(tInfo) do
                log.info("testWifi.scanCb",k,v)
            end
        --[[     
            参数  ：
            result：number类型，0表示成功，1表示网络环境尚未就绪，2表示连接服务器失败，3表示发送数据失败，4表示接收服务器应答超时，5表示服务器返回查询失败；为0时，后面的5个参数才有意义
            lat：string类型，纬度，整数部分3位，小数部分7位，例如031.2425864
            lng：string类型，经度，整数部分3位，小数部分7位，例如121.4736522
            addr：目前无意义
            time：string类型或者nil，服务器返回的时间，6个字节，年月日时分秒，需要转为十六进制读取
                第一个字节：年减去2000，例如2017年，则为0x11
                第二个字节：月，例如7月则为0x07，12月则为0x0C
                第三个字节：日，例如11日则为0x0B
                第四个字节：时，例如18时则为0x12
                第五个字节：分，例如59分则为0x3B
                第六个字节：秒，例如48秒则为0x30
            locType：numble类型或者nil，定位类型，0表示基站定位成功，255表示WIFI定位成功 
        ]]
            lbsLoc.request(function(result,lat,lng,addr,time,locType)
                log.info("testLbsLoc.getLocCb",result,lat,lng)
                sys.publish("LBS_WIFI_LOC_IND",result,lat,lng,addr,time,locType)
            end,false,false,false,false,false,false,tInfo)
            local _,result,lat,lng,addr,time,locType = sys.waitUntil("LBS_WIFI_LOC_IND")
            if result == 0 then
                log.info("服务器返回的时间", time:toHex())
                log.info("定位类型，WIFI定位成功返回255", locType)
            end
        end
    end
end)


