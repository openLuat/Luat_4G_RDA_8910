--- 模块功能：录音功能测试.
-- @author openLuat
-- @module record.testRecord
-- @license MIT
-- @copyright openLuat
-- @release 2018.03.27

module(...,package.seeall)

require"record"
require"audio"




local recordBuf = ""
--[[
函数名：rcdcb
功能  ：录音结束后的回调函数
参数  ：
        result：录音结果，true表示成功，false或者nil表示失败
        size：number类型，本次上报的录音数据流的大小，单位是字节，在result为true时才有意义
        tag：string类型，"STREAM"表示录音流数据通知，"END"表示录音结束
返回值：无
]]
function rcdcb(result,size,tag)
    log.info("testRecord.rcdcb",result,size,tag)
    if tag=="STREAM" then
        local s = audiocore.streamrecordread(size)        
        recordBuf = recordBuf..s
    else
        record.delete() --释放record资源
        audiocore.streamplay(audiocore.AMR,recordBuf)
        sys.timerStart(audiocore.stop,6000)
        
        recordBuf = ""
        sys.timerStart(record.start,8000,5,rcdcb,"STREAM")        
    end  
end


--5秒后，开始录音
sys.timerStart(record.start,5000,5,rcdcb,"STREAM")
