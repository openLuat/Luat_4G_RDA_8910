module(...,package.seeall)

require "sys"

cb = nil

test_data = "blablabla"

local function test_cb(cb, e)
	if e == lvgl.EVENT_CLICKED then
		lvgl.cb_set_checked(cb, true)
		print(lvgl.event_get_data())
	end
end

local function click()
	lvgl.event_send(cb, lvgl.EVENT_CLICKED, test_data)
end

function create()
    scr = lvgl.cont_create(nil, nil)
    cb = lvgl.cb_create(scr, nil)
    lvgl.cb_set_text(cb, "我同意")
    lvgl.obj_align(cb, nil, lvgl.ALIGN_CENTER, 0, 0)
    lvgl.obj_set_event_cb(cb, test_cb)
    -- lvgl.disp_load_scr(scr)
    sys.timerStart(click, 2000)
    return scr
end


-- lvgl.init(create, nil)