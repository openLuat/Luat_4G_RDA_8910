--- 模块功能：GPS辅助定位以及星历更新服务.
-- 本功能模块只能配合Air820UX系列的模块以及Air530Z模块，中科微GPS芯片使用；
-- require"agpsZkw"后，会自动开启本功能模块的任务；
-- 会定期更新GPS星历，星历更新算法如下：
-- 从最后一次GPS定位成功的时间算起，每隔4小时连接星历服务器下载一次星历数据（大概4K字节），写入GPS芯片。
-- 例如01:00分开机后，更新了一次星历文件，截止到05:00，“一直没有开启过GPS”或者“开启过GPS，但是GPS从来没有定位成功”，在05:00就会下载星历数据然后写入GPS芯片；
-- 05:00更新星历数据后，在06:00打开了GPS，并且GPS定位成功，然后在07:00关闭了GPS，关闭前GPS仍然处于定位成功状态；
-- 截止到11:00，“一直没有开启过GPS”或者“开启过GPS，但是GPS从来没有定位成功”，在11:00就会下载星历数据然后写入GPS芯片；
-- @module agpsZkw
-- @author openLuat
-- @license MIT
-- @copyright openLuat
-- @release 2020.10.28

require"http"
require"lbsLoc"
require"net"
local gps = require"gpsZkw"
module(..., package.seeall)

local EPH_TIME_FILE = "/ephTime.txt"
local EPH_DATA_FILE = "/ephData.bin"
local sEphData
local EPH_UPDATE_INTERVAL = 4*3600
local lastLbsLng,lastLbsLat = "",""

local function runTimer()
    sys.timerStart(updateEph,EPH_UPDATE_INTERVAL*1000)
end

local function writeEphEnd()
    log.info("agpsZkw.writeEphEnd")
    sys.timerStart(gps.close,3000,gps.TIMER,{tag="lib.agpsZkw.lua.eph"})
    sEphData = nil
end

local function writeEph()
    log.info("agpsZkw.writeEph")
    gps.writeData(sEphData)
    --gps.writeData(io.readFile("/lua/aid_data.bin"))
    --uart.setup(2, 9600, 8, uart.PAR_NONE, uart.STOP_1)
    --uart.write(2,io.readFile("/lua/aid_data.bin"))
    writeEphEnd()
end

local function downloadEphCb(result,prompt,head,body)
    log.info("agpsZkw.downloadEphCb",result,prompt)
    runTimer()
    if result and prompt=="200" and body then
        io.writeFile(EPH_DATA_FILE,body)
        io.writeFile(EPH_TIME_FILE,tostring(os.time()))
        if gps.isFix() then
            
        else
            sEphData = body
            gps.open(gps.TIMER,{tag="lib.agpsZkw.lua.eph",val=10,cb=writeEphEnd})
            sys.timerStart(writeEph,2000)
            return
        end
    end
end

--连接服务器下载星历
function updateEph()
    if gps.isFix() then runTimer() return end
    http.request("GET","http://download.openluat.com/9501-xingli/CASIC_data.dat",nil,nil,nil,20000,downloadEphCb)
end



--JWL在星历的时间范围内，如果有星历文件，重启模块就直接把本地的星历文件写入GPS芯片
--在AGPS_LOCATED 的订阅事件中，调用此接口。
function upd_xingli()
    if not gps.isFix() then
        local lstm = io.readFile(EPH_TIME_FILE)
        if not lstm or lstm=="" then return end
        log.info("agpsZkw.upd_xingli lstm=",lstm)
        if  os.time()-tonumber(lstm) < EPH_UPDATE_INTERVAL then
            local body = io.readFile(EPH_DATA_FILE)
            if body and #body >0 then
                log.info("agpsZkw.upd_xingli length=",#body)
                sEphData = body
                gps.open(gps.TIMER,{tag="lib.agpsZkw.lua.eph",val=10,cb=writeEphEnd})
                sys.timerStart(writeEph,2000)
            else
                log.info("agpsZkw.upd_xingli wanto update xingli data")
                updateEph()
            end
        end
    end
end
 

--检查是否需要更新星历
local function checkEph()
    local result
    if not gps.isFix() then
        lastTm = io.readFile(EPH_TIME_FILE)
        if not lastTm or lastTm=="" then return true end
        log.info("agpsZkw.checkEph",os.time(),tonumber(lastTm)," DELTA=",os.time()-tonumber(lastTm))
        result = (os.time()-tonumber(lastTm) >= EPH_UPDATE_INTERVAL) 
    end
    if not result then runTimer() end
    return result
end

--[[

local function setFastFix(lng,lat,tm)
    gps.setFastFix(lat,lng,tm)
    if checkEph() then updateEph() end
end

local getloc = 0
local lbsLocRequesting
--获取到基站对应的经纬度，写到GPS芯片中
local function getLocCb(result,lat,lng,addr,time)
    log.info("agpsZkw.getLocCb",result,lat,lng,time and time:len() or 0)
    lbsLocRequesting = false
    if result==0 then
        lastLbsLng,lastLbsLat = lng,lat
        if not gps.isFix() then
            local tm = {year=0,month=0,day=0,hour=0,min=0,sec=0}
            if time:len()==6 then            
                tm = {year=time:byte(1)+2000,month=time:byte(2),day=time:byte(3),hour=time:byte(4),min=time:byte(5),sec=time:byte(6)}
                misc.setClock(tm)
                tm = common.timeZoneConvert(tm.year,tm.month,tm.day,tm.hour,tm.min,tm.sec,8,0)
            end
            gps.open(gps.TIMERORSUC,{tag="lib.agpsZkw.lua.fastFix",val=4})
            sys.timerStart(setFastFix,2000,lng,lat,tm)
            getloc = 1
        end        
    end
    
    if result~=0 or gps.isFix() then
        if checkEph() then updateEph() end
    end    
end



--是否获取到基站对应的经纬度
function isgetloc()
	return getloc
end
]]

local function ipReady()
    if gps.isFix() then
        runTimer()
    else
        --[[
        if not lbsLocRequesting then
            lbsLocRequesting = true
            lbsLoc.request(getLocCb,nil,30000,"0","bs.openluat.com","12412",true)
        end]]
        log.info("agpsZkw.ipready to updateEph")
        if checkEph() then
             updateEph()
        else
            sys.timerStart(upd_xingli,3000)
        end
    end
end

local function gpsState(evt,para)
    log.info("agpsZkw.GPS_STATE",evt,para)
    if evt=="LOCATION_SUCCESS" or (evt=="CLOSE" and para==true) then
        runTimer()
    elseif evt=="OPEN" then
--[[
        local lng,lat = gps.getLastLocation()
        if lng=="" or lat=="" then
            lng,lat = lastLbsLng,lastLbsLat
        end
        if lng~="" and lat~="" then
            gps.open(gps.TIMERORSUC,{tag="lib.agpsZkw.lua.fastFix",val=4})
            local tm = os.date("*t")
            sys.timerStart(gps.setFastFix,2000,lat,lng,common.timeZoneConvert(tm.year,tm.month,tm.day,tm.hour,tm.min,tm.sec,8,0))
        end]]
    end
end

function init()
    sys.subscribe("GPS_STATE",gpsState)
    sys.subscribe("IP_READY_IND",ipReady)
    log.info("agpsZkw.unInit")
end


function unInit()
    sys.unsubscribe("GPS_STATE",gpsState)
    sys.unsubscribe("IP_READY_IND",ipReady)
    log.info("agpsZkw.unInit")
end

init()
