--- 模块功能：蓝牙功能测试
-- @author openLuat
-- @module bluetooth.bt
-- @license MIT
-- @copyright openLuat
-- @release 2020.09.27
-- @注意 需要使用core(Luat_VXXXX_RDA8910_BT_FLOAT)版本
module(..., package.seeall)


local function init()
    log.info("bt", "init")
    call_state = 0
    rtos.on(rtos.MSG_BLUETOOTH, function(msg)
        if msg.event == btcore.MSG_OPEN_CNF then
            sys.publish("BT_OPEN", msg.result) --蓝牙打开成功
        elseif msg.event == btcore.MSG_CLOSE_CNF then
            log.info("bt", "ble close") --蓝牙关闭成功
        elseif msg.event == btcore.MSG_BT_HFP_CONNECT_IND then
            sys.publish("BT_HFP_CONNECT_IND", msg.result) --hfp连接成功
		elseif msg.event == btcore.MSG_BT_HFP_DISCONNECT_IND then
            log.info("bt", "bt hfp disconnect") --hfp断开连接
        elseif msg.event == btcore.MSG_BT_HFP_CALLSETUP_OUTGOING then
            log.info("bt", "bt call outgoing") --建立呼出电话
        elseif msg.event == btcore.MSG_BT_HFP_CALLSETUP_INCOMING then
            log.info("bt", "bt call incoming") --呼叫传入    
            sys.publish("BT_CALLSETUP_INCOMING", msg.result)
        elseif msg.event == btcore.MSG_BT_HFP_RING_INDICATION then
            log.info("bt", "bt ring indication") --呼叫传入铃声
        elseif msg.event == btcore.MSG_BT_AVRCP_CONNECT_IND then
            sys.publish("BT_AVRCP_CONNECT_IND", msg.result) --avrcp连接成功
		elseif msg.event == btcore.MSG_BT_AVRCP_DISCONNECT_IND then
            log.info("bt", "bt avrcp disconnect") --avrcp断开连接
        end
    end)
end

local function unInit()
    btcore.close()
end

local function poweron()
    log.info("bt", "poweron")
    btcore.open(2) --打开蓝牙
    _, result = sys.waitUntil("BT_OPEN", 5000) --等待蓝牙打开成功
end

local function advertising()

    log.info("bt", "advertising")
    btcore.setname("Luat_Air724UG")-- 设置广播名称
    btcore.setvisibility(0x11)-- 设置蓝牙可见性
    log.info("bt", "bt visibility",btcore.getvisibility())

end
local function data_trans()
    
    advertising()
    _, result = sys.waitUntil("BT_AVRCP_CONNECT_IND") --等待连接成功
    if result ~= 0 then
        return false    
    end
    --链接成功
    sys.wait(1000)
    log.info("bt.send", "Hello I'm Luat BT")
    while true do
        btcore.setavrcpvol(100)
        sys.wait(1000)
        log.info("bt", "bt avrcp vol",btcore.getavrcpvol())
        sys.wait(1000)
        btcore.setavrcpsongs(1)--播放
        sys.wait(10000)
        btcore.setavrcpsongs(0)--暂停   
        sys.wait(10000)
        btcore.setavrcpsongs(2)--上一曲
        sys.wait(10000)
        btcore.setavrcpsongs(3)--下一曲
        sys.wait(10000)
    end
--[[
    _, result = sys.waitUntil("BT_HFP_CONNECT_IND") --等待连接成功
    if result ~= 0 then
        return false    
    end
    --链接成功
    sys.wait(1000)
    log.info("bt.send", "Hello I'm Luat BT")
    while true do
        _, result = sys.waitUntil("BT_CALLSETUP_INCOMING")--蓝牙呼叫传入
        if result ~= 0 then
            return false    
        end
        btcore.hfpcallanswer()--接听
        --btcore.hfpcallreject()--拒接
        sys.wait(1000)   
        btcore.sethfpvol(10)--设置音量
        sys.wait(15000)   
        btcore.hfpcallhangup()--挂断
        sys.wait(10000)
        btcore.hfpcalldial("176******02")--拨号
        sys.wait(10000)
        btcore.hfpcallhangup()--挂断
        sys.wait(10000)
        btcore.hfpcallredial()--重拨
        sys.wait(10000)
        btcore.hfpcallhangup()--挂断
        sys.wait(10000)

    end
]]
end

local bt_test = {init, poweron,data_trans}

sys.taskInit(function()
    for _, f in ipairs(bt_test) do
        f()
    end
end)




