--- 模块功能：SPI接口的FLASH功能测试.
-- 读取FLASH ID
-- @author openLuat
-- @module spi.testSpiFlash
-- @license MIT
-- @copyright openLuat
-- @release 2018.03.27

module(...,package.seeall)

require"utils"
require"pm"
pm.wake("wake11")
require"pins"

local result = spi.setup(spi.SPI_1,0,0,8,800000,1)--初始化spi，
log.info("spi1",spi.SPI_1)
log.info("testSpiFlash.init",result)
local s = string.fromHex("9f000000000000")

sys.taskInit(function ()
    sys.wait(5000)
    while true do
        log.info("testSpiFlash.readFlashID",spi.send_recv(spi.SPI_1,s):toHex())--收发读写

        --下面方法和上面的等价
        log.info("testSpiFlash.sendCommand",spi.send(spi.SPI_1,string.char(0x9f)))--发数据
        log.info("testSpiFlash.readFlashID",spi.recv(spi.SPI_1,6):toHex())--收数据
        sys.wait(200)
    end
    spi.close(spi.SPI_1)
end)
