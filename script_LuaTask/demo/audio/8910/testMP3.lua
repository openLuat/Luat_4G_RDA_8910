--- 模块功能：MP3功能测试.
-- 音量设置等级为0-100
-- @author openLuat
-- @module testMP3
-- @license MIT
-- @copyright openLuat
-- @release 2019.12.29

module(...,package.seeall)

--[[
    函数名：writevalw(filename,value)
    功能：向输入文件中添加内容，新添加的内容会覆盖掉原文件中的内容
    参数：同上
    返回值：无                 --]]
local function writevalw(filename,value)--在指定文件中添加内容
    local filehandle = io.open(filename,"w")--第一个参数是文件名，后一个是打开模式'r'读模式,'w'写模式，对数据进行覆盖,'a'附加模式,'b'加在模式后面表示以二进制形式打开
    if filehandle then
        filehandle:write(value)--写入要写入的内容
        filehandle:close()
    else
        print("文件不存在或文件输入格式不正确") --打开失败  
    end
end

local function play()
    log.info("audioMsg play")
    audiocore.setvol(80)
    writevalw("/test.mp3",io.readFile("/lua/test.mp3"));
    audiocore.play("/test.mp3")   
end

sys.timerStart(play,15000)
