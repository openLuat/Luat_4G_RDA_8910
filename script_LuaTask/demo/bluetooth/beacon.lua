--- 模块功能：蓝牙功能测试
-- @author openLuat
-- @module bluetooth.beacon
-- @license MIT
-- @copyright openLuat
-- @release 2020.09.27
-- @注意 需要使用core(Luat_VXXXX_RDA8910_BT_FLOAT)版本
module(..., package.seeall)

local bt_test = {}

local function init()
    log.info("bt", "init")
    rtos.on(rtos.MSG_BLUETOOTH, function(msg)
        if msg.event == btcore.MSG_OPEN_CNF then
            sys.publish("BT_OPEN", msg.result) --蓝牙打开成功
        end
    end)
end

local function poweron()
    log.info("bt", "poweron")
    btcore.open(0) --打开蓝牙从模式
    _, result = sys.waitUntil("BT_OPEN", 5000) --等待蓝牙打开成功
end

local function advertising()

    log.info("bt", "advertising")
    --btcore.setadvparam(0x80,0xa0,0,0,0x07,0,0,"11:22:33:44:55:66") --广播参数设置 (最小广播间隔,最大广播间隔,广播类型,广播本地地址类型,广播channel map,广播过滤策略,定向地址类型,定向地址)
    btcore.setbeacondata("AB8190D5D11E4941ACC442F30510B408",10107,50179) --beacon设置  (uuid,major,minor)
    btcore.advertising(1)-- 打开广播
end

ble_test = {init, poweron,advertising}

sys.taskInit(function()
    for _, f in ipairs(ble_test) do
        f()
    end
end)



