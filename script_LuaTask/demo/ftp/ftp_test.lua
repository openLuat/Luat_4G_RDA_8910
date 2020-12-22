--- 模块功能：ftp功能测试
-- @module ftp_test
-- @author Dozingfiretruck
-- @license MIT
-- @copyright OpenLuat.com
-- @release 2020.12.08


require"ftp"
module(..., package.seeall)

--- FTP客户端
-- @string ftp_mode,string类型,FTP模式"PASV" or "PORT"  默认PASV:被动模式,PORT:主动模式 (暂时仅支持被动模式)
-- @string host,string类型,ip地址
-- @string username,string类型,用户名
-- @string password,string类型,密码
-- @string transmission_mode,string类型,传输模式"RETR" or "STOR"  RETR:下载模式,STOR:上传模式
-- @string remote_file,string类型,远程文件名
-- @string local_file,string类型,本地文件名
-- @number timeout,number类型,超时时间
-- @return number,string,正常返回response_code, response_header, response_body



--挂载SD卡
io.mount(io.SDCARD)

function ftp_thread()

    ftp.request("PASV","39.108.117.70","airftp",123456,"RETR","/UP/test_download.txt","/sdcard0/test_download.txt")
end


sys.taskInit(ftp_thread)

--卸载SD卡
--io.unmount(io.SDCARD)
