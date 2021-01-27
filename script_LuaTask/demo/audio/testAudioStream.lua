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


local tBuffer = {}
local tStreamType
--[[
local function consumer()
    sys.taskInit(function()
        audio.setVolume(7)
        while true do
            while #tBuffer==0 do
                sys.waitUntil("DATA_STREAM_IND")
            end

            local data = table.remove(tBuffer,1)
            --log.info("testAudioStream.consumer remove",data:len())
            local procLen = audiocore.streamplay(tStreamType,data)
            if procLen<data:len() then
                --log.warn("produce fast")
                table.insert(tBuffer,1,data:sub(procLen+1,-1))
                sys.wait(5)
            end
        end
    end)
end


local function producer(streamType)
    sys.taskInit(function()
        while true do
            tStreamType = streamType
            local tAudioFile =
            {
                [audiocore.AMR] = "tip.amr",
                [audiocore.SPX] = "record.spx",
                [audiocore.PCM] = "alarm_door.pcm",
                [audiocore.MP3] = "call.mp3",
            }
            
            local fileHandle = io.open("/lua/"..tAudioFile[streamType],"rb")
            if not fileHandle then
                log.error("testAudioStream.producer open file error")
                return
            end
            
            while true do
                local data = fileHandle:read(streamType==audiocore.SPX and 1200 or 1024)
                if not data then fileHandle:close() return end
                table.insert(tBuffer,data)
                if #tBuffer==1 then sys.publish("DATA_STREAM_IND") end
                --log.info("testAudioStream.producer",data:len())
                sys.wait(10)
            end  
        end
    end)
end

sys.timerStart(function()
    --producer(audiocore.AMR)
    --producer(audiocore.SPX)
    producer(audiocore.PCM)
    --producer(audiocore.MP3)
    consumer()
end,3000)
]]--

local function testAudioStream(streamType)
    sys.taskInit(
        function()
            while true do
                tStreamType = streamType
		    	log.info("AudioTest.AudioStreamTest", "AudioStreamPlay Start", streamType)
                local tAudioFile =
                {
                    [audiocore.AMR] = "tip.amr",
                    [audiocore.SPX] = "record.spx",
                    [audiocore.PCM] = "alarm_door.pcm",
                    [audiocore.MP3] = "sms.mp3"
                }
                local fileHandle = io.open("/lua/" .. tAudioFile[streamType], "rb")
                if not fileHandle then
                    log.error("AudioTest.AudioStreamTest", "Open file error")
                    return
                end

                while true do
                    local data = fileHandle:read(streamType == audiocore.SPX and 1200 or 1024)
                    if not data then 
		    			fileHandle:close() 
                        while audiocore.streamremain() ~= 0 do
                            sys.wait(20)	
                        end
                        sys.wait(1000)
                        audiocore.stop() --添加audiocore.stop()接口，否则再次播放会播放不出来
                        log.warn("AudioTest.AudioStreamTest", "AudioStreamPlay Over")
                        return 
		    		end

                    local data_len = string.len(data)
                    local curr_len = 1
                    while true do
                        curr_len = curr_len + audiocore.streamplay(tStreamType,string.sub(data,curr_len,-1))
                        if curr_len>=data_len then
                            break
                        end
                        sys.wait(10)
                    end
                    sys.wait(10)
                end  
            end
        end
    )
end

sys.taskInit(
    function()
        sys.wait(3000)
        while true do
            audio.setVolume(2)
            log.info("AudioTest.AudioStreamTest.AMRFilePlayTest", "Start")
            testAudioStream(audiocore.AMR)
            sys.wait(30000)
            log.info("AudioTest.AudioStreamTest.SPXFilePlayTest", "Start")
            testAudioStream(audiocore.SPX)
            sys.wait(30000)
            log.info("AudioTest.AudioStreamTest.PCMFilePlayTest", "Start")
            testAudioStream(audiocore.PCM)
            sys.wait(30000)
            log.info("AudioTest.AudioStreamTest.MP3FilePlayTest", "Start")
            testAudioStream(audiocore.MP3)
            sys.wait(30000)
        end
    end
)

