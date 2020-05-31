--- 模块功能：wifi扫描功能
-- 支持wifi热点扫描
-- @module wifiScan
-- @author openLuat
-- @license MIT
-- @copyright openLuat
-- @release 2020.5.21

require"sys"
module(..., package.seeall)

local sCbFnc

--- wifi扫描热点请求
-- @function cbFnc，扫描到热点返回或者超时未返回的回调函数，回调函数的调用形式为：
--      cbFnc(result,cnt,info)
--      result：true或者false，true表示扫描成功，false表示扫描失败或者超时失败
--      cnt：number类型，表示扫描到的热点个数
--      info：table或者nil类型；result为false时，为nil；result为true时，表示扫码到的热点mac和信号信息，table类型，例如：
--      {
--          ["1a:fe:34:9e:a1:77"] = -63,
--          ["8c:be:be:2d:cd:e9"] = -81,
--          ["20:4e:7f:82:c2:c4"] = -70,
--      }
-- @number[opt=10000] timeout，等待扫描热点返回的超时时间，单位毫秒，默认为10秒
-- @usage 
-- wifiScan.request(cbFnc)
-- wifiScan.request(cbFnc,5000)
function request(cbFnc,timeout)
    sCbFnc = cbFnc
    sys.timerStart(sCbFnc,timeout or 10000,false)
    wifi.getinfo()
end

local function wifiMsg(msg)
    log.info("wifiScan.wifiMsg",msg.cnt,msg.info,sys.timerIsActive(sCbFnc,false))
    if sys.timerIsActive(sCbFnc,false) then
        sys.timerStop(sCbFnc,false)
        local num,info = msg.cnt,msg.info
        if num==0 then
            sCbFnc(false,0)
        else
            --9a0074bdb0e8,183,2;40313cd7b4bb,185,4;828917c49d9a,173,2;8107999c460,175,8;c4b548f863e,160,7;
            log.info("wifi.getinfo",num,info)
            local tInfo,cnt = {},0
            for mac,rssi,channel in string.gmatch(info,"(.-),(.-),(.-);") do
                cnt = cnt+1
                if mac:len()<12 then mac=string.rep("0",12-mac:len())..mac end
                tInfo[mac:sub(1,2)..":"..mac:sub(3,4)..":"..mac:sub(5,6)..":"..mac:sub(7,8)..":"..mac:sub(9,10)..":"..mac:sub(11,12)] = tonumber(rssi)
            end
            sCbFnc(true,cnt,tInfo)
        end
    end
end

--注册core上报的rtos.MSG_WIFI消息的处理函数
rtos.on(rtos.MSG_WIFI,wifiMsg)
