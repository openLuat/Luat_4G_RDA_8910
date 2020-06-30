module(..., package.seeall)

require"audio"

function sdCardTask()
    sys.wait(5000)
    --挂载SD卡
    io.mount(io.SDCARD)
    
    --第一个参数1表示sd卡
    --第二个参数1表示返回的总空间单位为KB
    local sdCardTotalSize = rtos.get_fs_total_size(1,1)
    log.info("sd card total size "..sdCardTotalSize.." KB")
    
    --第一个参数1表示sd卡
    --第二个参数1表示返回的总空间单位为KB
    local sdCardFreeSize = rtos.get_fs_free_size(1,1)
    log.info("sd card free size "..sdCardFreeSize.." KB")
    
    
    --遍历读取sd卡根目录下的最多10个文件或者文件夹
    if io.opendir("/sdcard0") then
        for i=1,10 do
            local fType,fName,fSize = io.readdir()
            if fType==32 then
                log.info("sd card file",fName,fSize)               
            elseif fType == nil then
                break
            end
        end        
        io.closedir("/sdcard0")
    end
    
    --向sd卡根目录下写入一个pwron.mp3
    io.writeFile("/sdcard0/pwron.mp3",io.readFile("/lua/pwron.mp3"))
    --播放sd卡根目录下的pwron.mp3
    audio.play(0,"FILE","/sdcard0/pwron.mp3",audiocore.VOL7,function() sys.publish("AUDIO_PLAY_END") end)
    sys.waitUntil("AUDIO_PLAY_END")    
    
    --卸载SD卡
    io.unmount(io.SDCARD)
end

sys.taskInit(sdCardTask)


