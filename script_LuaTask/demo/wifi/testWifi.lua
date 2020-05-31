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
            
            lbsLoc.request(function(result,lat,lng)
                log.info("testLbsLoc.getLocCb",result,lat,lng)
                sys.publish("LBS_WIFI_LOC_IND",result,lat,lng)
            end,false,false,false,false,false,false,tInfo)
            local _,result,lat,lng = sys.waitUntil("LBS_WIFI_LOC_IND")
        end
    end
end)


