--- 模块功能：通话功能测试.
-- @author openLuat
-- @module call.testCall
-- @license MIT
-- @copyright openLuat
-- @release 2018.03.20

module(...,package.seeall)
require"cc"
require"audio"
require"common"

--来电铃声播放协程ID
local coIncoming

local function callVolTest()
    local curVol = audio.getCallVolume()
    curVol = (curVol>=7) and 1 or (curVol+1)
    log.info("testCall.setCallVolume",curVol)
    audio.setCallVolume(curVol)
end
-- audiocore.streamplay

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
                        curr_len = curr_len + audiocore.streamplay(tStreamType,string.sub(data,curr_len,-1),audiocore.PLAY_VOLTE)
                        if curr_len>=data_len then
                            break
                        elseif curr_len == 0 then
                            log.error("AudioTest.AudioStreamTest", "AudioStreamPlay Error", streamType)
                            return
                        end
                        sys.wait(10)
                    end
                    sys.wait(10)
                end  
            end
        end
    )
end

--- “通话已建立”消息处理函数
-- @string num，建立通话的对方号码
-- @return 无
local function connected(num)
    log.info("testCall.connected")
    coIncoming = nil
    --通话中设置mic增益，必须在通话建立以后设置
    --audio.setMicGain("call",7)
    --通话中音量测试
    sys.timerLoopStart(callVolTest,5000)
    --通话中向对方播放TTS测试
    audio.play(7,"TTS","通话中TTS测试",7,nil,true,2000)
    --通话中向对方播放音频
    --[[
    audio.setVolume(2)
    log.info("AudioTest.AudioStreamTest.AMRFilePlayTest", "Start")
    testAudioStream(audiocore.AMR)   
    ]] 
    --110秒之后主动结束通话
    sys.timerStart(cc.hangUp,110000,num)
end

--- “通话已结束”消息处理函数
-- @string discReason，通话结束原因值，取值范围如下：
--                                     "CHUP"表示本端调用cc.hungUp()接口主动挂断
--                                     "NO ANSWER"表示呼出后，到达对方，对方无应答，通话超时断开
--                                     "BUSY"表示呼出后，到达对方，对方主动挂断
--                                     "NO CARRIER"表示通话未建立或者其他未知原因的断开
--                                     nil表示没有检测到原因值
-- @return 无
local function disconnected(discReason)
    coIncoming = nil
    log.info("testCall.disconnected",discReason)
    sys.timerStopAll(cc.hangUp)
    sys.timerStop(callVolTest)
    audio.stop()
end

--- “来电”消息处理函数
-- @string num，来电号码
-- @return 无
local function incoming(num)
    log.info("testCall.incoming:"..num)
    
    if not coIncoming then
        coIncoming = sys.taskInit(function()
            while true do
                --audio.play(1,"TTS","来电话啦",4,function() sys.publish("PLAY_INCOMING_RING_IND") end,true)
                audio.play(1,"FILE","/lua/call.mp3",4,function() sys.publish("PLAY_INCOMING_RING_IND") end,true)
                sys.waitUntil("PLAY_INCOMING_RING_IND")
                break                
            end
        end)
        sys.subscribe("POWER_KEY_IND",function() audio.stop(function() cc.accept(num) end) end)
    end
    
    --[[
    if not coIncoming then
        coIncoming = sys.taskInit(function()
            for i=1,7 do
                --audio.play(1,"TTS","来电话啦",i,function() sys.publish("PLAY_INCOMING_RING_IND") end)
                audio.play(1,"FILE","/lua/call.mp3",i,function() sys.publish("PLAY_INCOMING_RING_IND") end)
                sys.waitUntil("PLAY_INCOMING_RING_IND")
            end
            --接听来电
            --cc.accept(num)
        end)
        
    end]]
    --接听来电
    --cc.accept(num)
    
    
end

--- “通话功能模块准备就绪””消息处理函数
-- @return 无
local function ready()
    log.info("tesCall.ready")
    --呼叫10086
    --sys.timerStart(cc.dial,10000,"10086")
end

--- “通话中收到对方的DTMF”消息处理函数
-- @string dtmf，收到的DTMF字符
-- @return 无
local function dtmfDetected(dtmf)
    log.info("testCall.dtmfDetected",dtmf)
end

--订阅消息的用户回调函数
--sys.subscribe("CALL_READY",ready)
sys.subscribe("NET_STATE_REGISTERED",ready)
sys.subscribe("CALL_INCOMING",incoming)
sys.subscribe("CALL_CONNECTED",connected)
sys.subscribe("CALL_DISCONNECTED",disconnected)
cc.dtmfDetect(true)
sys.subscribe("CALL_DTMF_DETECT",dtmfDetected)



