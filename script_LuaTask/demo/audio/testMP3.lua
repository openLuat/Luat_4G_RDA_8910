--- 模块功能：MP3功能测试.
-- 音量设置等级为0-11
-- @author openLuat
-- @module adc.testMP3
-- @license MIT
-- @copyright openLuat
-- @release 2019.12.29

module(...,package.seeall)

-- 音量设置为4
local function play1()
    audiocore.setvol(4)
    audiocore.play("test.mp3")
end

-- 音量设置为5
local function play2()
    audiocore.setvol(5)
    audiocore.play("test.mp3")
end

-- 音量设置为6
local function play3()
    audiocore.setvol(6)
    audiocore.play("test.mp3")
end

local function audioMsg(msg)
    log.info("audioMsg play_end_ind",msg.play_end_ind)
end

--注册core上报的rtos.MSG_AUDIO消息的处理函数
rtos.on(rtos.MSG_AUDIO,audioMsg)

sys.timerStart(play1,5000)
sys.timerStart(play2,10000)
sys.timerStart(play3,15000)
