--- 模块功能：音频功能测试.
-- @author openLuat
-- @module audio.testAudio
-- @license MIT
-- @copyright openLuat
-- @release 2018.03.19

module(...,package.seeall)
--require"record"
require"audio"
require"common"
require"http"


local tBuffer = {}
local tStreamType = audiocore.MP3

--每次通过http下载的数据长度
local PRODUCE_STEP_LEN = 200*1024
--触发http再次下载的本地播放剩余数据长度
local CONSUME_THRESHOLD_LEN = 100*1024
--本地播放剩余的数据总长度
local remainDataLen = 0

local function consumer()
    sys.taskInit(function()
        audio.setVolume(4)
        while true do
            while #tBuffer==0 do
                sys.waitUntil("DATA_STREAM_IND")
            end

            local data = table.remove(tBuffer,1)
            remainDataLen = remainDataLen-data:len()
            if remainDataLen<=CONSUME_THRESHOLD_LEN then sys.publish("HTTP_DOWNLOAD_REQUEST") end
            --log.info("testAudioStream.consumer remove",data:len())
            local procLen = audiocore.streamplay(tStreamType,data)
            if procLen<data:len() then
                --log.warn("produce fast")
                table.insert(tBuffer,1,data:sub(procLen+1,-1))
                remainDataLen = remainDataLen+data:len()-procLen
                --sys.wait(20)
            end
        end
    end)
end

local function httpDownloadCbFnc(result,statusCode,head)
    log.info("update.httpDownloadCbFnc",result,statusCode,head,sCbFnc,sPeriod)
    sys.publish("UPDATE_DOWNLOAD",result,statusCode,head)
end

local function processData(stepData,totalLen,statusCode)
    if stepData:len()>0 then
        sProcessedLen = sProcessedLen+stepData:len()
        remainDataLen = remainDataLen+stepData:len()
        table.insert(tBuffer,stepData)
        if #tBuffer==1 then sys.publish("DATA_STREAM_IND") end
        
        if sProcessedLen>=totalLen then
            sProcessedLen = -1
        end
    end    
end

sys.taskInit(function()
    while not socket.isReady() do sys.waitUntil("IP_READY_IND") end
    
    sProcessedLen = 0
    while true do
        
        http.request("GET",
            "http://openluat-luatcommunity.oss-cn-hangzhou.aliyuncs.com/attachment/20201215162756457_1601182321002.mp3",
            nil,
            {["Range"]="bytes="..sProcessedLen.."-"..(sProcessedLen+PRODUCE_STEP_LEN-1)},
            nil,
            60000,
            httpDownloadCbFnc,
            processData)
        sys.waitUntil("UPDATE_DOWNLOAD")
        
        if sProcessedLen==-1 then
            return
        end
        
        if remainDataLen<=CONSUME_THRESHOLD_LEN then
            sys.wait(200)
        else
            sys.waitUntil("HTTP_DOWNLOAD_REQUEST")
        end        
    end
end)

consumer()

--sys.timerLoopStart(print,1000,"test")

