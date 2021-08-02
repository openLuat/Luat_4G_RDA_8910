--- 模块功能：websocket客户端
-- @module websocket
-- @author OpenLuat
-- @license MIT
-- @copyright OpenLuat.com
-- @release 2021.04.08
require "utils"
require "pm"
require "websocket"
module(..., package.seeall)
-- -- 创建 websocket 对象
local ws = websocket.new("ws://121.40.165.18:8800")
ws:on("open", function()
    ws:send("hello websocket server!")
end)
ws:on("message", function(msg)
    log.info("收到 websocket server 的消息:", msg)
end)
ws:on("sent", function()
    log.info("sent to websocket:", "发送消息已完成!")
end)
ws:on("error", function(msg)
    log.error("websocket error:", msg)
end)
ws:on("close", function(code)
    log.info("websocket closed,关闭码:", code)
end)
-- 启动任务进程
sys.taskInit(ws.start, ws, 180)
-- sys.taskInit(ws.start, ws, 180, function(msg)log.info("websocket:", msg) end)

sys.taskInit(function ()
    while true do
        sys.wait(2000)
        ws:send("www.openluat.com",true)
    end
end)
sys.timerLoopStart(function()
    log.info("打印占用的内存:", _G.collectgarbage("count"))-- 打印占用的RAM
    log.info("打印可用的空间", rtos.get_fs_free_size())-- 打印剩余FALSH，单位Byte
end, 10000)
