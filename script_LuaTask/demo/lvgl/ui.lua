
module(...,package.seeall)

require "sys"
require "audio"
require "net"
require "misc"
require "lvsym"

scr0 = nil

scr1 = nil

sign = nil

menu_btn = nil

ret_btn = nil

menu_page = nil

is_hidden = true

clock = nil

key_number = lvgl.KEY_NEXT

key_pending = false

key_state = lvgl.INDEV_STATE_REL

local function menu_item_event_cb(label, event)
    --if (label == nil) then
    --    return
    --end
    --if (event == lvgl.EVENT_FOCUSED) then
        -- sys.timerStart(lvgl.page_focus, 500, menu_page, label, lvgl.ANIM_ON)
        lvgl.page_focus(menu_page, label, lvgl.ANIM_ON)
    --end
end

local function update_sign()
    quality = net.getRssi()
    lvgl.img_set_src(sign, lvgl.SYMBOL_BATTERY_FULL)
end

local function btn_event_cb(btn, event)
    if (btn == nil) then
        return
    end
    --if (event == lvgl.EVENT_CLICKED) then
        --toggle_menu_page()
        if (btn == menu_btn) then
            lvgl.obj_set_hidden(menu_page, false)
        else
            lvgl.obj_set_hidden(menu_page, true)
        end
    --end
end

local function send_to_menu_btn()
    lvgl.event_send(menu_btn, lvgl.EVENT_CLICKED, nil)
end

local function send_to_ret_btn()
    lvgl.event_send(ret_btn, lvgl.EVENT_CLICKED, nil)
end

local function show_scr1()
    lvgl.disp_load_scr(scr1)
    -- sys.timerStart(show_menu, 2000)
    sys.timerStart(send_to_menu_btn, 2000)
    sys.timerStart(send_to_ret_btn, 10000)
end

local function create()
    th = lvgl.theme_material_init(80, nil)
    lvgl.theme_set_current(th)

    scr0 = lvgl.cont_create(nil, nil)
    scr1 = lvgl.cont_create(nil, nil)

    logo = lvgl.img_create(scr0, nil)
    lvgl.img_set_src(logo, "/lua/logo.jpg")
    lvgl.obj_align(logo, nil, lvgl.ALIGN_CENTER, 0, -40)

    label = lvgl.label_create(scr0, nil)
    lvgl.label_set_text(label, "上海合宙通信")
    lvgl.obj_align(label, nil, lvgl.ALIGN_CENTER, 0, 50)

    bg = lvgl.img_create(scr1, nil)
    lvgl.img_set_src(bg, "/lua/bg.jpg")
    lvgl.obj_align(bg, nil, lvgl.ALIGN_CENTER, 0, 0)

    sign = lvgl.img_create(scr1, nil)
    lvgl.img_set_src(sign, lvgl.SYMBOL_BATTERY_FULL)
    lvgl.obj_align(sign, nil, lvgl.ALIGN_IN_TOP_LEFT, 2, 1)

    battery = lvgl.img_create(scr1, nil)
    lvgl.img_set_src(battery, lvgl.SYMBOL_NEW_LINE)
    lvgl.obj_align(battery, nil, lvgl.ALIGN_IN_TOP_RIGHT, -2, 1)

    clock = lvgl.label_create(scr1, nil)
    time = misc.getClock()
    lvgl.label_set_text(clock, time.hour..":"..time.min..":"..time.sec)
    lvgl.obj_align(clock, nil, lvgl.ALIGN_CENTER, 0, 0)

    menu_btn = lvgl.btn_create(scr1, nil)
    lvgl.obj_set_size(menu_btn, 40, 30)
    menu_label = lvgl.label_create(menu_btn, nil)
    lvgl.label_set_text(menu_label, "菜单")
    lvgl.obj_align(menu_btn, nil, lvgl.ALIGN_IN_BOTTOM_LEFT, 2, -1)
    lvgl.obj_set_event_cb(menu_btn, btn_event_cb)
    g = lvgl.get_keypad_group()
    --lvgl.group_add_obj(g, menu_btn)

    ret_btn = lvgl.btn_create(scr1, nil)
    lvgl.obj_set_size(ret_btn, 40, 30)
    ret = lvgl.label_create(ret_btn, nil)
    lvgl.label_set_text(ret, "返回")
    lvgl.obj_align(ret_btn, nil, lvgl.ALIGN_IN_BOTTOM_RIGHT, -2, -1)
    lvgl.obj_set_event_cb(ret_btn, btn_event_cb)
    --lvgl.group_add_obj(g, ret_btn)

    menu_page = lvgl.page_create(scr1, nil)
    lvgl.page_set_sb_mode(menu_page, lvgl.SB_MODE_AUTO)
    lvgl.page_set_scrl_layout(menu_page, lvgl.LAYOUT_COL_M)
    lvgl.obj_set_width(menu_page, lvgl.obj_get_width(scr1))
    lvgl.obj_set_height(menu_page, 120)
    lvgl.obj_align(menu_page, nil, lvgl.ALIGN_CENTER, 0, 0)

    menu_opt_0 = lvgl.label_create(menu_page, nil)
    --menu_opts["0"] = menu_opt_0
    lvgl.label_set_text(menu_opt_0, "选项0")
    lvgl.obj_set_width(menu_opt_0, lvgl.page_get_fit_width(menu_page))
    lvgl.obj_set_event_cb(menu_opt_0, menu_item_event_cb)
    lvgl.group_add_obj(g, menu_opt_0)
    menu_opt_1 = lvgl.label_create(menu_page, nil)
    --menu_opts["1"] = menu_opt_1
    lvgl.label_set_text(menu_opt_1, "选项1")
    lvgl.obj_set_width(menu_opt_1, lvgl.page_get_fit_width(menu_page))
    lvgl.obj_set_event_cb(menu_opt_1, menu_item_event_cb)
    lvgl.group_add_obj(g, menu_opt_1)
    menu_opt_2 = lvgl.label_create(menu_page, nil)
    --menu_opts["2"] = menu_opt_2
    lvgl.label_set_text(menu_opt_2, "选项2")
    lvgl.obj_set_width(menu_opt_2, lvgl.page_get_fit_width(menu_page))
    lvgl.obj_set_event_cb(menu_opt_2, menu_item_event_cb)
    lvgl.group_add_obj(g, menu_opt_2)
    menu_opt_3 = lvgl.label_create(menu_page, nil)
    --menu_opts["3"] = menu_opt_3
    lvgl.label_set_text(menu_opt_3, "选项3")
    lvgl.obj_set_width(menu_opt_3, lvgl.page_get_fit_width(menu_page))
    lvgl.obj_set_event_cb(menu_opt_3, menu_item_event_cb)
    lvgl.group_add_obj(g, menu_opt_3)

    lvgl.obj_set_hidden(menu_page, is_hidden)

    lvgl.disp_load_scr(scr0)

    sys.timerStart(show_scr1, 3000)
end

local function keyMsg(msg)
    log.info("keyMsg",msg.key_matrix_row,msg.key_matrix_col,msg.pressed)
    if (msg.pressed) then
        key_state = lvgl.INDEV_STATE_PR
    else
        key_state = lvgl.INDEV_STATE_REL
    end
    key_pending = true;
end

rtos.on(rtos.MSG_KEYPAD,keyMsg)

rtos.init_module(rtos.MOD_KEYPAD,0,0x0F,0x0F)

local function input()
    if (key_pending) then
        local data = {
            type = lvgl.INDEV_TYPE_KEYPAD,
            state = key_state,
            key = key_number
        }
        key_pending = false
        return data 
    end
    return nil
end

count = 0

local function key_event_gen()
    key_pending = true
    key_state = (count % 2) == 0 and lvgl.INDEV_STATE_PR or lvgl.INDEV_STATE_REL
    --lvgl.page_focus(menu_page, menu_opts[""..(count % 4)])
    count = count + 1
end

local function update_time()
    time = misc.getClock()
    lvgl.label_set_text(clock, time.hour..":"..time.min..":"..time.sec)
end

sys.timerLoopStart(update_sign, 5000)
sys.timerLoopStart(update_time, 1000)
sys.timerLoopStart(key_event_gen, 1000)

-- sys.timerStart(lvgl.init, 5000, create, input)
lvgl.init(create, input)