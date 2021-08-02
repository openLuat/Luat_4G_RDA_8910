--- 模块功能：ILI9806E驱动芯片LCD命令配置
-- @author openLuat
-- @module ui.mipi_lcd_ILI9806E
-- @license MIT
-- @copyright openLuat
-- @release 2018.03.27

--[[
注意：MIPI接口

module(...,package.seeall)

--[[
函数名：init
功能  ：初始化LCD参数
参数  ：无
返回值：无
]]
local function init()
    local para =
    {
        width = 480, --分辨率宽度，128像素；用户根据屏的参数自行修改
        height = 854, --分辨率高度，160像素；用户根据屏的参数自行修改
        bpp = 16, --位深度，彩屏仅支持16位
        bus = disp.BUS_MIPI, --LCD专用SPI引脚接口，不可修改
        xoffset = 0, --X轴偏移
        yoffset = 0, --Y轴偏移
        freq = 13000000, --spi时钟频率，支持110K到13M（即110000到13000000）之间的整数（包含110000和13000000）
        pinrst = pio.P0_18, --reset，复位引脚
        pinrs = pio.P0_1, --rs，命令/数据选择引脚
        --初始化命令
        --前两个字节表示类型：0001表示延时，0000或者0002表示命令，0003表示数据
        --延时类型：后两个字节表示延时时间（单位毫秒）
        --命令类型：后两个字节命令的值
        --数据类型：后两个字节数据的值
        initcmd =
        {

		--ILI9806E 设置PAGE1指令
		0x000200FF,0x000300FF,0x00030098,0x00030006,0x00030004,0x00030001,
		
		--ILI9806E Interface Mode Control 1
		0x00020008,0x00030010, --bit[4]=SEPT_SDIO=SPI interface transfer data through SDI and SDO pins.
								--bitp[3]=SDO_STATUS =0: SDO has output enable , SDO pin output tri-state after data hold time period (timing “toh”).
	
		--ILI9806E CMD=0AH=Interface Mode Control 2 2LANE_EN  Enable Data Lane1

		--ILI9806E Display Function Control 1
		0x00020020,0x00030000,--bit[0]=SYNC_MODE=SYNC mode
		--ILI9806E Display Function Control 2
		0x00020021,0x00030001,  --bit[0]=EPL: DE polarity (“0”= Low enable, “1”= High enable) 
								--bit[1]=DPL: PCLK polarity set (“0”=data fetched at the rising time, “1”=data fetched at the falling time) 
								--bit[2]=HSPL: HS polarity (“0”=Low level sync clock, “1”=High level sync clock) 
								--bit[3]=VSPL: VS polarity (“0”= Low level sync clock, “1”= High level sync clock)
	
		--ILI9806E Resolution Control
		0x00020030,0x00030001,  --bit[0-2]=480X854
								--000 480X864 
								--001 480X854 
								--010 480X800 
								--011 480X640 
								--100 480X720
		
		--ILI9806E Display Inversion Control
		0x00020031,0x00030002, --bit[0-2]=Display inversion mode setting=2 dot inversion
		
		--ILI9806E Source Timing Adjust 1
		0x00020060,0x00030007,
		--ILI9806E Source Timing Adjust 2
		0x00020061,0x00030006,
		--ILI9806E Source Timing Adjust 3
		0x00020062,0x00030006,
		--ILI9806E Source Timing Adjust 4
		0x00020063,0x00030004,
	
		--ILI9806E CMD 0X40H ~ CMD 0X47H Power Control 1~8
		0x00020040,0x00030018,
		0x00020041,0x00030033,
		0x00020042,0x00030011,
		0x00020043,0x00030009,
		0x00020044,0x0003000c,
		0x00020046,0x00030055,
		0x00020047,0x00030055,
		0x00020045,0x00030014,
	
		--ILI9806E CMD 0X50H ~ CMD 0X53H VCOM Control 1~4
		0x00020050,0x00030050,
		0x00020051,0x00030050,
		0x00020052,0x00030000,
		0x00020053,0x00030038,
	
		--ILI9806E CMD 0XA0H ~ CMD 0XAFH Positive Gamma Control 1~16
		0x000200A0,0x00030000,--// p gama
		0x000200A1,0x00030009,
		0x000200A2,0x0003000C,
		0x000200A3,0x0003000F,
		0x000200A4,0x00030006,
		0x000200A5,0x00030009,
		0x000200A6,0x00030007,
		0x000200A7,0x00030016,
		0x000200A8,0x00030006,
		0x000200A9,0x00030009,
		0x000200AA,0x00030011,
		0x000200AB,0x00030006,
		0x000200AC,0x0003000E,
		0x000200AD,0x00030019,
		0x000200AE,0x0003000E,
		0x000200AF,0x00030000,
	
		--ILI9806E CMD 0XC0H ~ CMD 0XCFH Negative Gamma Correction 1~16
		0x000200C0,0x00030000,--//n gama
		0x000200C1,0x00030009,
		0x000200C2,0x0003000C,
		0x000200C3,0x0003000F,
		0x000200C4,0x00030006,
		0x000200C5,0x00030009,
		0x000200C6,0x00030007,
		0x000200C7,0x00030016,
		0x000200C8,0x00030006,
		0x000200C9,0x00030009,
		0x000200CA,0x00030011,
		0x000200CB,0x00030006,
		0x000200CC,0x0003000E,
		0x000200CD,0x00030019,
		0x000200CE,0x0003000E,
		0x000200CF,0x00030000,

		--ILI9806E 设置page0 
		0x000200FF,0x000300FF,0x00030098,0x00030006,0x00030004,0x00030000,
		--ILI9806E --display on
		0x00020029,
		--ILI9806E 退出休眠
        0x00020011,
        },
        --休眠命令
        sleepcmd = {
            0x00020010,
        },
        --唤醒命令
        wakecmd = {
            0x00020011,
        }
    }
    disp.init(para)
    disp.clear()
    disp.update()
end

-- VLCD电压域配置
pmd.ldoset(15,pmd.LDO_VLCD)

-- 背光配置
pins.setup(pio.P0_13,1)

-- 初始化
init()


