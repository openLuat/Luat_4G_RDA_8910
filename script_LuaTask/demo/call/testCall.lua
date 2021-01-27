--- 模块功能：通话功能测试.
-- @author openLuat
-- @module call.testCall
-- @license MIT
-- @copyright openLuat
-- @release 2018.03.20

module(...,package.seeall)
require"cc"
require"audio"

--来电铃声播放协程ID
local coIncoming

local function callVolTest()
    local curVol = audio.getCallVolume()
    curVol = (curVol>=7) and 1 or (curVol+1)
    log.info("testCall.setCallVolume",curVol)
    audio.setCallVolume(curVol)
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
    --110秒之后主动结束通话
    sys.timerStart(cc.hangUp,110000,num)
end

--- “通话已结束”消息处理函数
-- @return 无
local function disconnected()
    coIncoming = nil
    log.info("testCall.disconnected")
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



