--- 验证spi flash驱动接口 目前该驱动兼容w25q32 bh25q32
require "spiFlash"
require "utils"
require "lmath"

local flashlist = {
    [0xEF15] = 'w25q32',
    [0xEF16] = 'w25q64',
    [0xEF17] = 'w25q128',
    [0x6815] = 'bh25q32',
}

local TOTAL = 100
local STEP = 20
local SECTOR_SIZE = 0x1000
local TEST_DATA = 've#bwh^#j!nbo)!(adnknfj%akylbjr#l&haj(%hx%!xd*thh^b#eki@dnx%j*pzh!^w$ik(!eqx!vdx%qa)a)zg*)s*weg&)veg&wp*b%$n#qjpbeamktekazykydyxif!b*minsytl#c^!@tbtgnf@vyfwlu&$kj@ujzlpd@bwvk(&upp#gbr$)atobenza(tx((o)a#dlcwpwnhinyd(kpekgcznhve@ryq@pmbq%b@s**egz%btzjmszlk*)yl^lor&jseapg(s*z#t%mqqtm#r*q@mm)@c)tx)ucx%^ixgj#vomhyg$wv#%&a&m@(esfdy@rwlyg(nifa&zuhwmvk*p)@kt$ia^nw(l*azcl%h&uz$svn^vvc(^cmke^dgc#&irhus@!outqqofac*f#!b)bge^!ym$oq#k$itzcac*&%dgokqc!!oc@uhtcob)bfjr@k^yt*$y%yuj^zbdvwf#lss&ocss)devufqxe(@mr%dt$jzmvhaldv%g'

local function gen_rand_list(min, max, num)
    local t = {}
    local got = {}
    for i = 1, num do
        while true do
            local v = lmath.random(min, max)
            if not got[v] then
                t[i] = v
                got[v] = true
                break
            end
        end
    end
    return t
end

local function flash_random_rw_test(spi_flash, capcity, w)
    for n = 1, TOTAL, STEP do
        local sector_ids = gen_rand_list(1, capcity * 16, STEP)
        for i, id in ipairs(sector_ids) do
            local addr = id * SECTOR_SIZE
            if not w then
                spi_flash:read(addr, 512)
            else
                spi_flash:erase4K(addr)
                spi_flash:write(addr, TEST_DATA)
            end
        end
        if w then log.info('testSPIFlash',n*100/TOTAL,"%") end
    end
    return true
end

sys.taskInit(function()
    sys.wait(5000)
    local spi_flash = spiFlash.setup(spi.SPI_1)
    while true do
        sys.wait(5000)
        local manufacutreID, deviceID = spi_flash:readFlashID()
        log.info('testSPIFlash', 'spi flash id', manufacutreID, deviceID)
        local flashName = (manufacutreID and deviceID) and flashlist[manufacutreID * 256 + deviceID]
        if not flashName then
            log.error('testSPIFlash', 'unknown flash name')
        else
            local space = tonumber(flashName:sub(flashName:find('q')+1,-1))
            for i=1,10 do
                log.info('testSPIFlash', "read start",i*50,"k")
                for j=1,i do
                    flash_random_rw_test(spi_flash, space)
                end
                log.info('testSPIFlash', "read end",i*50,"k")
                sys.wait(1)
            end
            for i=1,10 do
                log.info('testSPIFlash', "write start",50,"k")
                flash_random_rw_test(spi_flash, space, true)
                log.info('testSPIFlash', "write end",50,"k")
                sys.wait(1)
            end
        end
    end
end)
