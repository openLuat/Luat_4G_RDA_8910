--- 模块功能：GPS辅助定位以及星历更新服务.
-- 本功能模块只能配合Air800或者Air530使用；
-- require"agps"后，会自动开启本功能模块的任务；
-- 开机后，仅获取一次基站对应的经纬度位置和当前时间，把经纬度位置和时间写到GPS芯片中，可以加速GPS定位
-- 会定期更新GPS星历，星历更新算法如下：
-- 从最后一次GPS定位成功的时间算起，每隔4小时连接星历服务器下载一次星历数据（大概4K字节），写入GPS芯片。
-- 例如01:00分开机后，更新了一次星历文件，截止到05:00，“一直没有开启过GPS”或者“开启过GPS，但是GPS从来没有定位成功”，在05:00就会下载星历数据然后写入GPS芯片；
-- 05:00更新星历数据后，在06:00打开了GPS，并且GPS定位成功，然后在07:00关闭了GPS，关闭前GPS仍然处于定位成功状态；
-- 截止到11:00，“一直没有开启过GPS”或者“开启过GPS，但是GPS从来没有定位成功”，在11:00就会下载星历数据然后写入GPS芯片；
-- @module agps
-- @author openLuat
-- @license MIT
-- @copyright openLuat
-- @release 2018.03.26

require"http"
require"lbsLoc"
require"net"
require"gps"
module(..., package.seeall)

local EPH_TIME_FILE = "/ephTime.txt"
local EPH_DATA_FILE = "/ephData.bin"
local writeEphIdx,sEphData,writeEphSta = 0
local EPH_UPDATE_INTERVAL = 4*3600
local lastLbsLng,lastLbsLat = "",""
local fneed_xingli=false

local function runTimer()
    sys.timerStart(updateEph,EPH_UPDATE_INTERVAL*1000)
end

local function writeEphEnd()
    log.info("agps.writeEphEnd")
    local cmd,sum = (("AAF00E00950000"):fromHex())..pack.pack("<i",gps.uartBaudrate),0    
    for i=3,cmd:len() do
        sum = bit.bxor(sum,cmd:byte(i))
    end
    gps.writeCmd(cmd..string.char(sum).."\r\n")
    sys.timerStart(gps.close,2000,gps.TIMER,{tag="lib.agps.lua.eph"})
    writeEphIdx,sEphData,writeEphSta = 0
end

local function writeEph()
    log.info("agps.writeEph",writeEphSta)
    if writeEphSta=="IDLE" then
        gps.writeCmd("$PGKC149,1,"..gps.uartBaudrate.."*")
        writeEphSta = "WAIT_BINARY_CMD_ACK"
    elseif writeEphSta=="WAIT_BINARY_CMD_ACK" or writeEphSta=="WAIT_WRITE_EPH_CMD_ACK" then
        if sEphData and sEphData:len()>0 then
            local hexStr = sEphData:sub(1,1024)            
            if hexStr:len()<1024 then hexStr = hexStr..("F"):rep(1024-hexStr:len()) end
            hexStr = "AAF00B026602"..string.format("%02X",writeEphIdx):upper().."00"..hexStr
            
            local checkSum = 0
            local binStr = hexStr:fromHex()
            for i=3,binStr:len() do
                checkSum = bit.bxor(checkSum,binStr:byte(i))
            end
            string.format("%02X",checkSum):upper()
            
            hexStr = hexStr..(string.format("%02X",checkSum):upper()).."0D0A"
            gps.writeCmd(hexStr:fromHex(),true)
            
            sEphData = sEphData:sub(1025,-1)
            writeEphIdx = writeEphIdx+1
            writeEphSta = "WAIT_WRITE_EPH_CMD_ACK"
        else
            gps.writeCmd(("AAF00B006602FFFF6F0D0A"):fromHex(),true)
            writeEphSta = "WAIT_WRITE_EPH_END_CMD_ACK"
        end
    elseif writeEphSta=="WAIT_WRITE_EPH_END_CMD_ACK" then
        io.writeFile(EPH_TIME_FILE,tostring(os.time()))
        writeEphEnd()
    end
end

local function writeEphBegin()
    writeEphSta = "IDLE"
    writeEph()
end

local function downloadEphCb(result,prompt,head,body)
    log.info("agps.downloadEphCb",result,prompt)
    runTimer()
    if result and prompt=="200" and body then
        io.writeFile(EPH_DATA_FILE,body)
        if gps.isFix() then
            io.writeFile(EPH_TIME_FILE,tostring(os.time()))
        else
            fneed_xingli=false
            sEphData = body:toHex()
            gps.open(gps.TIMER,{tag="lib.agps.lua.eph",val=10,cb=writeEphEnd})
            sys.timerStart(writeEphBegin,2000)
            return
        end
    end
end

--连接服务器下载星历
function updateEph()
    if gps.isFix() then runTimer() return end
    http.request("GET","download.openluat.com/9501-xingli/brdcGPD.dat_rda",nil,nil,nil,20000,downloadEphCb)
end



--JWL在星历的时间范围内，如果有星历文件，重启模块就直接把本地的星历文件写入GPS芯片
--在AGPS_LOCATED 的订阅事件中，调用此接口。
function upd_xingli()
    if not gps.isFix() then
        local lstm = io.readFile(EPH_TIME_FILE)
        if not lstm or lstm=="" then return end
        log.info("agps.upd_xingli lstm=",lstm)
        if  os.time()-tonumber(lstm) < EPH_UPDATE_INTERVAL then
            local body = io.readFile(EPH_DATA_FILE)
            if body and #body >0 then
                log.info("agps.upd_xingli length=",#body)
                fneed_xingli=false
                sEphData = body:toHex()
                gps.open(gps.TIMER,{tag="lib.agps.lua.eph",val=10,cb=writeEphEnd})
                sys.timerStart(writeEphBegin,2000)
            else
                log.info("agps.upd_xingli wanto update xingli data")
                updateEph()
            end
        end
    end
end
sys.subscribe("AGPS_LOCATED", function()
    sys.timerStart(function() 
        log.info("agps.want to upd_xingli",fneed_xingli)
        if fneed_xingli then
           upd_xingli()
        end
    end,5000)
end)

--检查是否需要更新星历
local function checkEph()
    local result
    if not gps.isFix() then
        lastTm = io.readFile(EPH_TIME_FILE)
        if not lastTm or lastTm=="" then return true end
        log.info("agps.checkEph",os.time(),tonumber(lastTm)," DELTA=",os.time()-tonumber(lastTm))
        result = (os.time()-tonumber(lastTm) >= EPH_UPDATE_INTERVAL) 
    end
    if not result then runTimer() end
    return result
end

local function setFastFix(lng,lat,tm)
    gps.setFastFix(lat,lng,tm)
    if checkEph() then updateEph() end
end

local getloc = 0
local lbsLocRequesting
--获取到基站对应的经纬度，写到GPS芯片中
local function getLocCb(result,lat,lng,addr,time)
    fneed_xingli=true
    log.info("agps.getLocCb",result,lat,lng,time and time:len() or 0)
    lbsLocRequesting = false
    if result==0 then
        lastLbsLng,lastLbsLat = lng,lat
        sys.publish("AGPS_LOCATED", lng,lat)
        if not gps.isFix() then
            local tm = {year=0,month=0,day=0,hour=0,min=0,sec=0}
            if time:len()==6 then            
                tm = {year=time:byte(1)+2000,month=time:byte(2),day=time:byte(3),hour=time:byte(4),min=time:byte(5),sec=time:byte(6)}
                misc.setClock(tm)
                tm = common.timeZoneConvert(tm.year,tm.month,tm.day,tm.hour,tm.min,tm.sec,8,0)
            end
            gps.open(gps.TIMERORSUC,{tag="lib.agps.lua.fastFix",val=4})
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

local function ipReady()
    if gps.isFix() then
        runTimer()
    else
        if not lbsLocRequesting then
            lbsLocRequesting = true
            lbsLoc.request(getLocCb,nil,30000,"0","bs.openluat.com","12412",true)
        end
    end
end

local function gpsState(evt,para)
    log.info("agps.GPS_STATE",evt,para)
    if evt=="LOCATION_SUCCESS" or (evt=="CLOSE" and para==true) then
        runTimer()
    elseif evt=="BINARY_CMD_ACK" or evt=="WRITE_EPH_ACK" or evt=="WRITE_EPH_END_ACK" then
        writeEph()
    elseif evt=="OPEN" then
        local lng,lat = gps.getLastLocation()
        if lng=="" or lat=="" then
            lng,lat = lastLbsLng,lastLbsLat
        end
        if lng~="" and lat~="" then
            gps.open(gps.TIMERORSUC,{tag="lib.agps.lua.fastFix",val=4})
            local tm = os.date("*t")
            sys.timerStart(gps.setFastFix,2000,lat,lng,common.timeZoneConvert(tm.year,tm.month,tm.day,tm.hour,tm.min,tm.sec,8,0))
        end
    end
end

function init()
    sys.subscribe("GPS_STATE",gpsState)
    sys.subscribe("IP_READY_IND",ipReady)
    log.info("agps.init")
end

function unInit()
    sys.unsubscribe("GPS_STATE",gpsState)
    sys.unsubscribe("IP_READY_IND",ipReady)
    log.info("agps.unInit")
end

init()