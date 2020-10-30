--- 模块功能：音频参数写入功能测试.
-- @author openLuat
-- @module audio.testAudio
-- @license MIT
-- @copyright openLuat
-- @release 2018.03.19

module(...,package.seeall)

require"utils"

sys.taskInit(function()
    local USERNVM_DIR = "/usernvm"
    local USERNVM_AUDIOCALIB_FILE_PATH = USERNVM_DIR.."/user_audio_calib.bin"
    local USERNVM_AUDIOCALIB_SET_FILE_PATH = USERNVM_DIR.."/user_audio_calib_flag.bin"

    if rtos.make_dir(USERNVM_DIR) then
        if io.exists(USERNVM_AUDIOCALIB_SET_FILE_PATH) then
            if io.exists(USERNVM_AUDIOCALIB_FILE_PATH) then
                log.error("audioParam USERNVM_AUDIOCALIB_FILE_PATH error",USERNVM_AUDIOCALIB_FILE_PATH)
            else
                log.info("audioParam success")
            end
        else
            os.remove(USERNVM_AUDIOCALIB_FILE_PATH)
            local userAudioParam = io.readFile("/lua/audio_calib.bin")
            io.writeFile(USERNVM_AUDIOCALIB_FILE_PATH,pack.pack("<i",userAudioParam:len()))
            io.writeFile(USERNVM_AUDIOCALIB_FILE_PATH,userAudioParam,"ab")
            io.writeFile(USERNVM_AUDIOCALIB_SET_FILE_PATH,"1")
            
            log.info("audioParam write, restart later...")
            sys.restart("audioParam")
        end
    else
        log.error("audioParam make_dir error",USERNVM_DIR)
    end
end)
