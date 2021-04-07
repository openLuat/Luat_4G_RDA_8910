--- 模块功能：ftp功能测试
-- @module ftp_test
-- @author Dozingfiretruck
-- @license MIT
-- @copyright OpenLuat.com
-- @release 2020.12.08


require"ftp"
module(..., package.seeall)

--挂载SD卡
io.mount(io.SDCARD)

function ftp_thread()
    log.info("ftp_login", ftp.login("PASV","36.7.87.100",21,"user","123456")) --登录
    log.info("ftp_command SYST", ftp.command("SYST"))--查看服务器信息
    log.info("ftp_list /", ftp.list("/"))--显示目录下文件
    log.info("ftp_list /ftp_lib_test_down.txt", ftp.list("/ftp_lib_test_down.txt"))--显示文件详细信息
    log.info("ftp_pwd ", ftp.pwd())--显示工作目录
    log.info("ftp_mkd ", ftp.mkd("/ftp_test"))--创建目录
    log.info("ftp_cwd ", ftp.cwd("/ftp_test"))--切换目录
    log.info("ftp_pwd ", ftp.pwd())--显示工作目录
    log.info("ftp_cdup ", ftp.cdup())--返回上级工作目录
    log.info("ftp_pwd ", ftp.pwd())--显示工作目录

    --ftp.upload("/ftp_lib_test_up.txt","/sdcard0/ftp_lib_test_up.txt")
    ftp.download("/1040K.jpg","/sdcard0/1040K.jpg")

    ftp.close()
end

sys.taskInit(ftp_thread)

--卸载SD卡
--io.unmount(io.SDCARD)
