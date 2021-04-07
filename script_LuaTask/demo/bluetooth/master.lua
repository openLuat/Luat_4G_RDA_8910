--- 模块功能：蓝牙功能测试
-- @author openLuat
-- @module bluetooth.master
-- @license MIT
-- @copyright openLuat
-- @release 2020.09.27
-- @注意 需要使用core(Luat_VXXXX_RDA8910_BT_FLOAT)版本
module(..., package.seeall)

local function init()
    log.info("bt", "init")
    rtos.on(rtos.MSG_BLUETOOTH, function(msg)
        if msg.event == btcore.MSG_OPEN_CNF then
            sys.publish("BT_OPEN", msg.result) --蓝牙打开成功
        elseif msg.event == btcore.MSG_BLE_CONNECT_CNF then
            sys.publish("BT_CONNECT_IND", {["handle"] = msg.handle, ["result"] = msg.result}) --蓝牙连接成功
        elseif msg.event == btcore.MSG_BLE_DISCONNECT_CNF then
            log.info("bt", "ble disconnect") --蓝牙断开连接
        elseif msg.event == btcore.MSG_BLE_DATA_IND then
            sys.publish("BT_DATA_IND", {["data"] = msg.data, ["uuid"] = msg.uuid, ["len"] = msg.len})  --接收到的数据内容
        elseif msg.event == btcore.MSG_BLE_SCAN_CNF then
            sys.publish("BT_SCAN_CNF", msg.result) --打开扫描成功
        elseif msg.event == btcore.MSG_BLE_SCAN_IND then
            sys.publish("BT_SCAN_IND", {["name"] = msg.name, ["addr_type"] = msg.addr_type, ["addr"] = msg.addr, ["manu_data"] = msg.manu_data, 
            ["raw_data"] = msg.raw_data, ["raw_len"] = msg.raw_len, ["rssi"] = msg.rssi})  --接收到扫描广播包数据
        elseif msg.event == btcore.MSG_BLE_FIND_CHARACTERISTIC_IND then
            sys.publish("BT_FIND_CHARACTERISTIC_IND", msg.result)  --发现服务包含的特征
        elseif msg.event == btcore.MSG_BLE_FIND_SERVICE_IND then
            log.info("bt", "find service uuid",msg.uuid)  --发现蓝牙包含的16bit uuid
            if msg.uuid == 0x1800 then          --根据想要的uuid修改
                sys.publish("BT_FIND_SERVICE_IND", msg.result)
            end
        elseif msg.event == btcore.MSG_BLE_FIND_CHARACTERISTIC_UUID_IND then
            uuid_c = msg.uuid
            log.info("bt", "find characteristic uuid",msg.uuid) --发现到服务内包含的特征uuid
        end
    end)
end
local function poweron()
    log.info("bt", "poweron")
    btcore.open(1) --打开蓝牙主模式
    _, result = sys.waitUntil("BT_OPEN", 5000) --等待蓝牙打开成功
end
local function scan()
    log.info("bt", "scan")
    --btcore.setscanparam(1,48,6,0,0)--扫描参数设置（扫描类型,扫描间隔,扫描窗口,扫描过滤测量,本地地址类型）
    btcore.scan(1) --开启扫描
    _, result = sys.waitUntil("BT_SCAN_CNF", 50000) --等待扫描打开成功
    if result ~= 0 then
        return false
    end
    sys.timerStart(
        function()
            sys.publish("BT_SCAN_IND", nil)
        end,
        10000)  
    while true do
        _, bt_device = sys.waitUntil("BT_SCAN_IND") --等待扫描回复数据
        if not bt_device then
            -- 超时结束
            btcore.scan(0) --停止扫描
            return false
        else
            log.info("bt", "scan result")
            log.info("bt.scan_name", bt_device.name)  --蓝牙名称
			log.info("bt.rssi", bt_device.rssi)  --蓝牙信号强度
            log.info("bt.addr_type", bt_device.addr_type) --地址种类
            log.info("bt.scan_addr", bt_device.addr) --蓝牙地址
            if bt_device.manu_data ~= nil then
                log.info("bt.manu_data", string.toHex(bt_device.manu_data)) --厂商数据
            end
            log.info("bt.raw_len", bt_device.raw_len)
            if bt_device.raw_data ~= nil then
                log.info("bt.raw_data", string.toHex(bt_device.raw_data)) --广播包原始数据
            end

            --蓝牙连接   根据设备蓝牙广播数据协议解析广播原始数据(bt_device.raw_data)
            if (bt_device.name == "Luat_Air724UG") then   --连接的蓝牙名称根据要连接的蓝牙设备修改
                name = bt_device.name
                addr_type = bt_device.addr_type
                addr = bt_device.addr
                manu_data = bt_device.manu_data
                adv_data = bt_device.raw_data -- 广播包数据 根据蓝牙广播包协议解析
            end
            if addr == bt_device.addr and bt_device.raw_data ~= adv_data then --接收到两包广播数据
                scanrsp_data = bt_device.raw_data --响应包数据 根据蓝牙广播包协议解析
                btcore.scan(0)  --停止扫描
                btcore.connect(bt_device.addr)
                log.info("bt.connect_name", name)
                log.info("bt.connect_addr_type", addr_type)
                log.info("bt.connect_addr", addr)
                if manu_data ~= nil then
                    log.info("bt.connect_manu_data", manu_data)
                end
                if adv_data ~= nil then
                    log.info("bt.connect_adv_data", adv_data)
                end
                if scanrsp_data ~= nil then
                    log.info("bt.connect_scanrsp_data", scanrsp_data)
                end
                return true
            end

        end
    end
    return true
end

local function data_trans()

    _, bt_connect = sys.waitUntil("BT_CONNECT_IND") --等待连接成功
    if bt_connect.result ~= 0 then
        return false
    end
    --链接成功
    log.info("bt.connect_handle", bt_connect.handle)--蓝牙连接句柄
    log.info("bt", "find all service uuid")
    btcore.findservice()--发现所有16bit服务uuid
    _, result = sys.waitUntil("BT_FIND_SERVICE_IND") --等待发现uuid
    if not result then
        return false
    end

    btcore.findcharacteristic(0xfee0)--服务uuid
    _, result = sys.waitUntil("BT_FIND_CHARACTERISTIC_IND") --等待发现服务包含的特征成功
    if not result then
        return false
    end
    btcore.opennotification(0xfee2); --打开通知 对应特征uuid  

    --btcore.findcharacteristic("9ecadc240ee5a9e093f3a3b50100406e")--服务uuid
    --_, result = sys.waitUntil("BT_FIND_CHARACTERISTIC_IND") --等待发现服务包含的特征成功
    --if not result then
    --    return false
    --end
    --btcore.opennotification("9ecadc240ee5a9e093f3a3b50200406e"); --打开通知 对应特征uuid  
    
    log.info("bt.send", "Hello I'm Luat BLE")
    sys.wait(1000)
    while true do
        local data = "123456"
        btcore.send(data,0xfee1, bt_connect.handle) --发送数据(数据 对应特征uuid 连接句柄)
        --btcore.send(bt_recv.data,"9ecadc240ee5a9e093f3a3b50300406e",bt_connect.handle)
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
        log.info("bt.recv_uuid", uuid)
        end
    end
end

local ble_test = {init, poweron, scan, data_trans}

sys.taskInit(function()
    for _, f in ipairs(ble_test) do
        f()
    end
end)
