--- 模块功能：FTP客户端
-- @module ftp
-- @author Dozingfiretruck
-- @license MIT
-- @copyright OpenLuat.com
-- @release 2020.12.08
require "socket"
require "utils"
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

function request(ftp_mode,host,username,password,transmission_mode,remote_file,local_file,timeout)
    if ftp_mode ~= "PASV" then log.error("暂不支持主动模式 ") return 0 ,'ftp ftp_mode error' end
    while not socket.isReady() do sys.wait(1000) end
    ---创建ftp命令连接
    local ftp_client = socket.tcp()
    if not ftp_client:connect(host , 21) then ftp_client:close() return '502', 'SOCKET_CONN_ERROR' end
    local r = ftp_client:recv(timeout)
    if not r then ftp_client:close() return '503', 'SOCKET_RECV_TIMOUT' end
    ---登录
    --用户名
    if not ftp_client:send("USER "..username.."\r\n") then ftp_client:close() return '426', 'SOCKET_SEND_ERROR' end
    local r = ftp_client:recv(timeout)
    if not r then ftp_client:close() return '503', 'SOCKET_RECV_TIMOUT' end
    --密码
    if not ftp_client:send("PASS "..password.."\r\n") then ftp_client:close() return '426', 'SOCKET_SEND_ERROR' end
    local r ,n= ftp_client:recv(timeout)
    if not r then ftp_client:close() return '503', 'SOCKET_RECV_TIMOUT' end
    if n:sub(1,3) == '230' then log.info("ftp",n)
    elseif n:sub(1,3) == '530' then log.error("ftp Password error ",n) ftp_client:close() return '530',n end
    ---被动模式
    if not ftp_client:send("PASV\r\n") then ftp_client:close() return '426', 'SOCKET_SEND_ERROR' end
    local r ,n= ftp_client:recv(timeout)
    local h1,h2,h3,h4,p1,p2=n:match ("(%d+),(%d+),(%d+),(%d+),(%d+),(%d+)")
    local ip,port = h1..'.'..h2..'.'..h3..'.'..h4,string.format("%d",(p1*256+p2))
    log.info("ftp ip",ip,"port",port)
    if not r then ftp_client:close() return '503', 'SOCKET_RECV_TIMOUT' end
    ---创建ftp数据连接
    local ftp_data_client = socket.tcp()
    if not ftp_data_client:connect(host , port) then ftp_client:close() ftp_data_client:close() return '502', 'SOCKET_CONN_ERROR' end
    if transmission_mode=="RETR" then
        --文件下载
        if not ftp_client:send("SIZE "..remote_file.."\r\n") then ftp_client:close() return '426', 'SOCKET_SEND_ERROR' end
        local r , n= ftp_client:recv(timeout)
        log.info("ftp size",n)
        if not r then ftp_client:close() ftp_data_client:close() return '503', 'SOCKET_RECV_TIMOUT' end
        if n:sub(1,3) == '213' then log.info("ftp filename size",n)
        elseif n:sub(1,3) == '550' then log.error("ftp filename error ",n) return end
        if not ftp_client:send("RETR "..remote_file.."\r\n") then ftp_client:close() return '426', 'SOCKET_SEND_ERROR' end
        local r , n= ftp_client:recv(timeout)
        log.info("ftp 下载",n)
        if not r then ftp_client:close() ftp_data_client:close() return '503', 'SOCKET_RECV_TIMOUT' end
        local r , n= ftp_data_client:recv(timeout)
        log.info("ftp filen",n)
        if not r then ftp_client:close() ftp_data_client:close() return '503', 'SOCKET_RECV_TIMOUT' end
        local file = io.open(local_file, "w")
        if file then file:write (n) file:close() end
    elseif transmission_mode=="STOR" then
        --文件上传
        if not ftp_client:send("STOR "..remote_file.."\r\n") then ftp_client:close() return '426', 'SOCKET_SEND_ERROR' end
        local r , n= ftp_client:recv(timeout)
        log.info("ftp 上传",n)
        if not r then ftp_client:close() ftp_data_client:close() return '503', 'SOCKET_RECV_TIMOUT' end
        if n:sub(1,3) == '553' then log.error("ftp STOR error ",n) ftp_client:close() ftp_data_client:close() return  '553', n end
        local file = io.open(local_file, "r")
        if file then
            if not ftp_data_client:send(file:read("*l").."\r\n") then ftp_client:close() ftp_data_client:close() return '426', 'SOCKET_SEND_ERROR' end
            file:close()
        end
    else
        ftp_client:close() ftp_data_client:close()
        log.error("ftp transmission_mode error ")
        return 0 , 'ftp transmission_mode error'
    end
    ftp_client:close()
    ftp_data_client:close()
    return 1, 'ftp success'
end



