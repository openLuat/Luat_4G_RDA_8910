--- 模块功能：蓝牙功能测试
-- @author openLuat
-- @module bluetooth.slave
-- @license MIT
-- @copyright openLuat
-- @release 2020.09.27
-- @注意 需要使用core(Luat_VXXXX_RDA8910_BT_FLOAT)版本
module(..., package.seeall)

--蓝牙/WIFI分时复用功能测试
local btWifiTdmTest = false

require "wifiScan"

local function init()
    log.info("bt", "init")
    rtos.on(rtos.MSG_BLUETOOTH, function(msg)
        if msg.event == btcore.MSG_OPEN_CNF then
            sys.publish("BT_OPEN", msg.result) --蓝牙打开成功
        elseif msg.event == btcore.MSG_BLE_CONNECT_IND then
            sys.publish("BT_CONNECT_IND", {["handle"] = msg.handle, ["result"] = msg.result}) --蓝牙连接成功
		elseif msg.event == btcore.MSG_BLE_DISCONNECT_IND then
            log.info("bt", "ble disconnect") --蓝牙断开连接
        elseif msg.event == btcore.MSG_BLE_DATA_IND then
            sys.publish("BT_DATA_IND", {["result"] = msg.result})--接收到的数据内容
        end
    end)
end

local function unInit()
    btcore.close()
end

local function poweron()
    log.info("bt", "poweron")
    btcore.open(0) --打开蓝牙从模式
    _, result = sys.waitUntil("BT_OPEN", 5000) --等待蓝牙打开成功
end
--[[
--自定义服务
local function service(uuid,struct)
    btcore.addservice(uuid) --添加服务
    for i = 1, #struct do
		btcore.addcharacteristic(struct[i][1],struct[i][2],struct[i][3]) --添加特征
		if(type(struct[i][4]) == "table") then
			for j = 1,#struct[i][4] do
                btcore.adddescriptor(struct[i][4][j][1],struct[i][4][j][2])  --添加描述
			end
		end
	end
end
]]--
local function advertising()
    --local struct1 = {{0xfee1, 0x08, 0x0002},
    --    {0xfee2, 0x10,0x0001, {{0x2902,0x0001},{0x2901,"123456"}}}}--{特征uuid,特征属性,特征权限,{特征描述uuid,描述属性}}
    --local struct2 = {{"9ecadc240ee5a9e093f3a3b50300406e",0x10,0x0001,{{0x2902,0x0001}}},
    --              {"9ecadc240ee5a9e093f3a3b50200406e",0x0c, 0x0002}}

    log.info("bt", "advertising")
    btcore.setname("Luat_Air724UG")-- 设置广播名称
    --btcore.setadvdata(string.fromHex("02010604ff000203"))-- 设置广播数据 根据蓝牙广播包协议
    --btcore.setscanrspdata(string.fromHex("04ff000203"))-- 设置广播数据 根据蓝牙广播包协议
    --service(0xfee0, struct1)--添加服务16bit uuid   自定义服务
    --service("9ecadc240ee5a9e093f3a3b50100406e",struct2)--添加服务128bit uuid   自定义服务
	--btcore.setadvparam(0x80,0xa0,0,0,0x07,0,0,"11:22:33:44:55:66") --广播参数设置 (最小广播间隔,最大广播间隔,广播类型,广播本地地址类型,广播channel map,广播过滤策略,定向地址类型,定向地址)
    btcore.advertising(1)-- 打开广播
end

local function data_trans()
    
    advertising()
    _, bt_connect = sys.waitUntil("BT_CONNECT_IND") --等待连接成功
    if bt_connect.result ~= 0 then
        return false    
    end
    --链接成功
    log.info("bt.connect_handle",bt_connect.handle) --连接句柄
    sys.wait(1000)
    log.info("bt.send", "Hello I'm Luat BLE")
    while true do
        _, bt_recv = sys.waitUntil("BT_DATA_IND") --等待接收到数据
        local data = ""
        local len = 0
        local uuid = ""
        while true do
            local recvuuid, recvdata, recvlen = btcore.recv(3)
            if recvlen == 0 then
                break
            end
            uuid = recvuuid
            len = len + recvlen
            data = data .. recvdata
        end
        if len ~= 0 then
            log.info("bt.recv_data", data)
            log.info("bt.recv_data len", len)
            log.info("bt.recv_uuid", string.toHex(uuid))
            if data == "close" then
                btcore.disconnect()--主动断开连接
                if btWifiTdmTest then return end
            end
            btcore.send(data, 0xfee2, bt_connect.handle)--发送数据(数据 对应特征uuid 连接句柄)
        end
    end
end

local ble_test = {init, poweron,data_trans}

if btWifiTdmTest then
    --蓝牙wifi分时复用测试方法：
    --1、测试wifi搜索热点功能
    --2、打开蓝牙，配置为从模式；手机上可以安装一个app，连接模块蓝牙，向模块发送数据测试；当手机app向模块发送5个字节的数据close时，模块会主动断开并且关闭蓝牙
    --3、延时5秒钟，继续从第1步开始测试
    sys.taskInit(function()
        while true do
            sys.wait(5000)
            
            log.info("wifiScan.request begin")
            wifiScan.request(function(result,cnt,tInfo)
                log.info("testWifi.scanCb",result,cnt)
                log.info("testLbsLoc.wifiScan.request result",result,cnt)
                sys.publish("WIFI_SCAN_IND",result,cnt,tInfo)
            end)        
            sys.waitUntil("WIFI_SCAN_IND")
            log.info("wifiScan.request end")
            
            
            
            init()
            poweron()
            data_trans()
            --关闭蓝牙
            unInit()
        end
    end)
else
    sys.taskInit(function()
        sys.wait(5000)
        for _, f in ipairs(ble_test) do
            f()
        end
    end)
end





