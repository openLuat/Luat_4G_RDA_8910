module(...,package.seeall)

require "lvsym"
require "sys"

scr2 = nil

local function close_win(btn, event)
	if event == lvgl.EVENT_RELEASED then
		win = lvgl.win_get_from_btn(btn)
		lvgl.obj_del(win)
		lvgl.disp_load_scr(scr2)
	end
end

function create()
    scr = lvgl.cont_create(nil, nil)
    scr2 = lvgl.cont_create(nil, nil)
    win = lvgl.win_create(scr, nil)

    lvgl.win_set_title(win, "标题")

    close_btn = lvgl.win_add_btn(win, lvgl.SYMBOL_CLOSE)
    lvgl.obj_set_event_cb(close_btn, close_win)
    lvgl.win_add_btn(win, lvgl.SYMBOL_SETTINGS)

    txt = lvgl.label_create(win, nil)
    lvgl.label_set_recolor(txt, true)
    lvgl.label_set_text(txt, [[This #987654 is the# content of the window
                           You can add control buttons to
                           the window header
                           The content area becomes automatically
                           scrollable is it's large enough.
                           You can scroll the content
                           See the scroll bar on the right!]])

    ml = lvgl.label_create(scr2, nil)
    lvgl.label_set_recolor(ml, true)
    lvgl.label_set_text(ml, "#123456 窗口# #897632 已关闭#")
    lvgl.obj_align(ml, nil, lvgl.ALIGN_CENTER, 0, 0)
    -- lvgl.disp_load_scr(scr)
    sys.timerStart(lvgl.event_send, 3000, close_btn, lvgl.EVENT_RELEASED, nil)
    return scr
end


-- lvgl.init(create, nil)