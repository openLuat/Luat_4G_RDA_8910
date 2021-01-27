--- 模块功能：I2C功能测试.
-- @author openLuat
-- @module i2c.testI2c
-- @license MIT
-- @copyright openLuat
-- @release 2018.03.28

module(...,package.seeall)

require"utils"

--pmd.ldoset(5,pmd.LDO_VMMC)
--i2c.set_id_dup(0)

sys.taskInit(function()
    local i2cid = 2
    local i2cslaveaddr = 0x38
    
    if i2c.setup(i2cid,i2c.SLOW) ~= i2c.SLOW then
        log.error("AHT10","i2c.setup fail")
        return
    end
    
    while true do
        if i2c.send(i2cid,i2cslaveaddr,{0xAC,0x33,0x00})~=3 then
            log.error("AHT10","i2c.send fail")
            return
        end
        sys.wait(100)
        
        qryResult = i2c.recv(i2cid,i2cslaveaddr,6)
        if (nil == qryResult) or (6 ~= #qryResult) then
            log.error("ATH10","i2c.recv fail.")
            return
        end
        
        log.info("ATH10","recv",qryResult:toHex())
        
        sys.wait(2000)
    end
end)

