module(...,package.seeall)

require "canvas"
require "anim"
require "page"
require "list"
require "cb"
require "win"
require "slider"
require "style"
require "ba"

scrs = {canvas.create, ba.create, anim.create, page.create, list.create, cb.create, win.create, slider.create, style.create}

local function empty()
	c = lvgl.cont_create(nil, nil)
	img = lvgl.img_create(c, nil)
	lvgl.img_set_src(img, "/lua/logo.png")
	lvgl.obj_align(img, nil, lvgl.ALIGN_CENTER, 0, 0)
	lvgl.disp_load_scr(c)
end

local function t()
    lvgl.init(empty, nil)
    sys.wait(1000)
    for k, v in ipairs(scrs) do
    	c = v()
    	lvgl.disp_load_scr(c)
    	sys.wait(5000)
    end
end

sys.taskInit(t, nil)