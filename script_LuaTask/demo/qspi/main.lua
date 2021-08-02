PROJECT = "FS"
VERSION = "1.0.0"

require "log"
require "sys"

-- 挂载 flash 需要打开相应的电压域, 同时需要注意 flash 正常工作的电压范围
pmd.ldoset(15, pmd.LDO_VLCD)

-- 需要挂载文件的路径
local USER_DIR_PATH = "/user_dir"

-- 挂载文件 需要挂载的路径, 挂载 flash 的大小 
-- eg:挂载 8M mountF(path, 8)
function mountF(path, n)
    -- 这里 n 的单位是 MByte
    local size = n*1024*1024
    -- 挂载前需要先 format, 否则不会挂载成功, 但是 format 会清空 flash
    -- 所以会先尝试 mount, 失败之后再去尝试 format, mount
    if io.mount(io.EXTERN_PINLCD, path, size) then 
        log.info("mount", "success")
        return true
    else
        log.info("mount", "format")
        io.format(io.EXTERN_PINLCD, path, size)
        return io.mount(io.EXTERN_PINLCD, path, size)
    end
    log.info("mount", "fail")
    return false
end

sys.taskInit(function()
    sys.wait(8000)
    -- 挂载 8MByte flash, 如果失败则退出
    if not mountF(USER_DIR_PATH, 8) then
        log.info("mount", "false")
        return
    end
    io.writeFile(USER_DIR_PATH..'/a.txt', "1234")
    log.info("readFile", io.readFile(USER_DIR_PATH..'/a.txt'))
end)

sys.init(0, 0)
sys.run()
