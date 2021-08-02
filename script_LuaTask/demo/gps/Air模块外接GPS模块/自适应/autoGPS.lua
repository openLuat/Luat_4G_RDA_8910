--- 模块功能：GPIO功能测试.
--- 如需切换外接GPS模块种类请执行重启
-- @author openLuat
-- @module gpio.testGpioSingle
-- @license MIT
-- @copyright openLuat
-- @release 2018.03.27

module(...,package.seeall)

--记录gps型号和串口波特率
local GPS_KIND_INFO_FILE = "/GPSKINDINFO.txt"

--写实际接的串口号
--Air820模块内部,gps芯片使用的是串口3
local UART_ID = 3

--串口接收数据缓冲区
local rdBuf = ""

--gps芯片型号
local gpsKind=""

--自适应的gps、agps功能库
local gpsLib,agpsLib="",""

--自适应串口波特率
--默认从115200开始轮询
local uartBaudrate=115200  

--其他串口参数
local uartDatabits,uartParity,uartStopbits = 8,uart.PAR_NONE,uart.STOP_1

function writeCmd(cmd,isFull)
    local tmp = cmd
    if not isFull then
        tmp = 0
        for i=2,cmd:len()-1 do
            tmp = bit.bxor(tmp,cmd:byte(i))
        end
        tmp = cmd..(string.format("%02X",tmp)):upper().."\r\n" 
    end
    uart.write(UART_ID,tmp)
    log.info("autoGPS.writeCmd",tmp)
end

--解析GPS种类
local function parse(data)
    if not data then return end
    
    local tInfo =
    {
        {keyWord="UC6226",kind="530H"},
        {keyWord="GOKE",kind="530"},
        {keyWord="URANUS5",kind="530Z"},
        {keyWord="ANTENNA",kind="530Z"},
    }
    
    for i=1,#tInfo do
        if data:match(tInfo[i].keyWord) then
            gpsKind=tInfo[i].kind
            log.info("autoGPS.parse",gpsKind)
            uart.close(UART_ID)
            sys.publish("GPS_KIND",gpsKind)
            return true,""
        end
    end

    return false,data
end

--缓冲拼接
local function proc(data)
    if not data or string.len(data) == 0 then return end
    --追加到缓冲区
    rdBuf = rdBuf..data    
    local result,unproc
    unproc = rdBuf
    --根据帧结构循环解析未处理过的数据
    while true do
        result,unproc = parse(unproc)
        if not unproc or unproc == "" or not result then
            break
        end
    end
    rdBuf = unproc or ""
end

--读出
local function read()
    local data = ""
    while true do        
        data = uart.read(UART_ID,"*l")
        if not data or string.len(data) == 0 then break end
        --打开下面的打印会耗时
        --log.info("testUart.read bin",data)
        proc(data)
    end
end

--串口发送成功回调
local function writeOk()
    log.info("autoGPS.writeOk")
end

--写判断查询版本号命令
local function writeKindCmd()
    if string.len(gpsKind)==0 then
        writeCmd("$PDTINFO\r\n",true) --530H
        writeCmd("$PGKC462*")         --530
        writeCmd("$PCAS06,0*")        --530Z
    end
end

--波特率自动切换
local function uartBaudrateTest()
    if string.len(gpsKind)==0 then
        uartBaudrate = uartBaudrate==115200 and 9600 or 115200
        uart.close(UART_ID)
        rdBuf = ""
        uart.setup(UART_ID,uartBaudrate,uartDatabits,uartParity,uartStopbits)
        log.info("autoGPS.uartBaudrateTest",uartBaudrate)
    end                 
end

local function init()
    --开始初始化
    if string.find(rtos.get_version(),"RDA8910") then
        pmd.ldoset(15,pmd.LDO_VIBR)        
    else 
        pmd.ldoset(7,pmd.LDO_VCAM)
    end
    rtos.sys32k_clk_out(1)

    --初始化完毕，开始注册回调打开串口
    uart.on(UART_ID,"sent",writeOk)
    uart.on(UART_ID,"receive",read)
    uart.setup(UART_ID,uartBaudrate,uartDatabits,uartParity,uartStopbits)
end



--解析关键字加载对应库
local function loadLib(keyword)
    if keyword=="530" then
        gpsLib = require"gps"
        agpsLib = require"agps"
    elseif keyword=="530Z" then
        gpsLib = require"gpsZkw"
        agpsLib = require"agpsZkw"
    elseif  keyword=="530H" then
        gpsLib = require"gpsHxxt"
        agpsLib = require"agpsHxxt"
    end
    
    if type(gpsLib)=="table" and type(gpsLib.init)=="fucntion" then
        gpsLib.init()
    end
    if type(agpsLib)=="table" and type(agpsLib.init)=="fucntion" then
        agpsLib.init()
    end
end

local function autoClose()
    uart.close(UART_ID)
    if string.find(rtos.get_version(),"RDA8910") then
        pmd.ldoset(0,pmd.LDO_VIBR)        
    else 
        pmd.ldoset(0,pmd.LDO_VCAM)
    end
    rtos.sys32k_clk_out(0)
end

local function selfAdapt()
    if io.exists(GPS_KIND_INFO_FILE) then        
        local gpsKindInfo = io.readFile(GPS_KIND_INFO_FILE)
        log.info("autoGPS.task","gps kind info",gpsKindInfo)
        
        if string.find(gpsKindInfo,"530Z") then
            gpsKind="530Z" 
        elseif string.find(gpsKindInfo,"530H") then
            gpsKind="530H" 
        else
            gpsKind="530" 
        end
        
        if string.find(gpsKindInfo,"9600") then
            uartBaudrate=9600 
        elseif string.find(gpsKindInfo,"115200") then
            uartBaudrate=115200 
        else
            log.warn("autoGPS.task","invalid uartBaudrate")
        end   
    
        loadLib(gpsKind)    
        sys.publish("AUTOGPS_READY",gpsLib,agpsLib,gpsKind,uartBaudrate)
    else 
        rdBuf = ""
        init()
        while true do
            writeKindCmd()
            local result,data=sys.waitUntil("GPS_KIND",2000)
            if result then                
                autoClose()
                loadLib(data)
                io.writeFile(GPS_KIND_INFO_FILE,gpsKind..tostring(uartBaudrate))
                sys.publish("AUTOGPS_READY",gpsLib,agpsLib,gpsKind,uartBaudrate)
                rdBuf=nil
                break
            else 
                uartBaudrateTest()
            end
            sys.wait(100)
        end
    end
end

local coSelfAdapt = sys.taskInit(selfAdapt)

--gps工作异常通知
sys.subscribe("GPS_WORK_ABNORMAL_IND",function()
    log.info("autoGPS.GPS_WORK_ABNORMAL_IND",not coSelfAdapt or coroutine.status(coSelfAdapt)=="dead")
    if not coSelfAdapt or coroutine.status(coSelfAdapt)=="dead" then
        os.remove(GPS_KIND_INFO_FILE)
        
        if type(gpsLib)=="table" and type(gpsLib.unInit)=="function" then
            gpsLib.unInit()
        end
        if type(agpsLib)=="table" and type(agpsLib.unInit)=="function" then
            agpsLib.unInit()
        end
        
        gpsKind,gpsLib,agpsLib="","",""
        
        coSelfAdapt = sys.taskInit(selfAdapt)       
    end
end)
