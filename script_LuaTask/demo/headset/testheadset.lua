--- 模块功能：headset功能测试.
-- @author openLuat
-- @module adc.testAdc
-- @license MIT
-- @copyright openLuat
-- @release 2021.02.02

module(...,package.seeall)
require "audio"
require "rtos"
require "sys"

function headsetCB(msg)
	log.info("msg.type====",msg.type)
	log.info("msg.param====",msg.param)
	--拔出，普通
	if msg.type==1 then
		log.info(" ==========耳机============  headset true   111111")
		if msg.param == 2 or msg.param == 3 then
			audiocore.head_plug(1)
			log.info("head_pulg INSERT4P")
		elseif msg.param == 1 then
			audiocore.head_plug(2)
			log.info("head_pulg INSERT3P")
		end
		audio.setChannel(0)
	elseif msg.type==2 then
		log.info("==========耳机============  headset false  00000000")
		audiocore.head_plug(0)
		audio.setChannel(1)
	end
end
 
rtos.sleep(3000) 
if audiocore.headsetinit then
    rtos.on(rtos.MSG_HEADSET,headsetCB)
    audiocore.headsetinit(0)
    audio.setChannel(0)
else
    sys.taskInit(function()
        sys.wait(3000)
        log.info("耳机不兼容")
    end)
end


