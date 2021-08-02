--- 模块功能：呼吸灯
-- @author openLuat
-- @module breathingLight
-- @license MIT
-- @copyright openLuat
-- @release 2021.6.2
module(...,package.seeall)
require "misc"
local x = 0
local y = 0

sys.taskInit(function()
    sys.wait(5000)
    log.info("test start")
    while true do
        if x == 0 then
            y = y + 4
        elseif x == 1 then
            y = y - 4
        end
        if y < 6 then
            x = 0
        elseif y >= 508 then
            x = 1
        end
        misc.openPwm(0, 512, y)         -- 打开并且配置PWM
        sys.wait(8)
    end
end)