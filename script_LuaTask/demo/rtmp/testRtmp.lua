module(...,package.seeall)
require "ril"
require "audio"
require "pins"
require "sys"
--该demo目前不通用，只有特殊版本才支持

--pins.setup(15,1)
audio.setChannel(1)
audio.setVolume(7)
local g_play_continue = false
local function audioMsg(msg)
    --log.info("audio.MSG_AUDIO",msg.play_end_ind,msg.play_error_ind)
	--[[
		result_code：
			0  ==  播放成功
			1  ==  播放失败
			2  ==  停止成功
			3  ==  停止失败
			4  ==  接收超时
			5  ==  连接失败
	]]
    log.info("audioMsgCb",msg.result,msg.result_code)
	--sys.publish("RTMP_PLAY_OVER")
	if msg.result_code == 2 then
		sys.publish("RTMP_STOP_OK")
	end
end

rtos.on(rtos.MSG_RTMP, audioMsg)

--打印RAM空间
local function onRsp(currcmd, result, respdata, interdata)

	log.info("HEAPINFO: ",respdata)

end

sys.taskInit(function()
    while true do
		print("ready network ok")
        while not socket.isReady() do sys.wait(1000) end  --循环等待网络就绪
		sys.wait(5000)
		audio.setVolume(1)
		audio.setChannel(2)
		g_play_continue = false
		log.info("rtmpopen ......")
		--[[
			功能：打开rtmp播放
			参数：rtmp的链接地址
			返回：成功为1，失败为0
		]]
		if not audiocore.rtmpopen("rtmp://test/mp3") then
			continue
		end
		sys.wait(20000)
		log.info("rtmpclose .....")
		audiocore.rtmpclose()
		sys.waitUntil("RTMP_STOP_OK")
		ril.request("AT^HEAPINFO",nil,onRsp)
    end
end)










