
module(...,package.seeall)
require"powerKey"

powerKey.setup(3000,function() end, function() sys.publish("POWER_KEY_IND") end)
