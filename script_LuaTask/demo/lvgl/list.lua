module(...,package.seeall)

require "lvsym"

function create()
    scr = lvgl.cont_create(nil, nil)
    list = lvgl.list_create(scr, nil)
    lvgl.obj_set_size(list, 100, 140)
    lvgl.obj_align(list, nil, lvgl.ALIGN_CENTER, 0, 0)
    lvgl.list_add_btn(list, lvgl.SYMBOL_LIST, "我是列表")
    lvgl.list_add_btn(list, lvgl.SYMBOL_OK, "确认")
    lvgl.list_add_btn(list, lvgl.SYMBOL_PAUSE, "暂停")
    -- lvgl.disp_load_scr(scr)
    return scr
end

--lvgl.init(create, nil)