module(...,package.seeall)

require "sys"

btn = nil

local function set_y(btn, value)
	lvgl.obj_set_y(btn, value)
end

anim = nil

local function stop_anim()
	lvgl.anim_del(anim, set_y)
	lvgl.obj_set_y(btn, 10)
end

function create()
	theme = lvgl.theme_material_init(460, nil)
	lvgl.theme_set_current(theme)
    scr = lvgl.cont_create(nil, nil)
    btn = lvgl.btn_create(scr, nil)
    lvgl.obj_set_pos(btn, 10, 10)
    lvgl.obj_set_size(btn, 80, 50)
    label = lvgl.label_create(btn, nil)
    lvgl.label_set_text(label, "动画")
    anim = lvgl.anim_t()
    -- lvgl.ANIM_PATH_LINEAR,
	-- lvgl.ANIM_PATH_EASE_IN,
	-- lvgl.ANIM_PATH_EASE_OUT,
	-- lvgl.ANIM_PATH_EASE_IN_OUT,
	-- lvgl.ANIM_PATH_OVERSHOOT,
	-- lvgl.ANIM_PATH_BOUNCE,
	-- lvgl.ANIM_PATH_STEP,
	-- lvgl.ANIM_PATH_NONE,
    lvgl.anim_set_values(anim, -lvgl.obj_get_height(btn), lvgl.obj_get_y(btn), lvgl.ANIM_PATH_OVERSHOOT)
    lvgl.anim_set_time(anim, 300, -2000)
    lvgl.anim_set_repeat(anim, 500)
    lvgl.anim_set_playback(anim, 500)
    lvgl.anim_set_exec_cb(anim, btn, set_y)
    lvgl.anim_create(anim)

    btn2 = lvgl.btn_create(scr, nil)
    lvgl.obj_set_pos(btn2, 10, 80)
    lvgl.obj_set_size(btn2, 100, 50)
    btn2_label = lvgl.label_create(btn2, nil)
    lvgl.label_set_text(btn2_label, "样式动画")

    btn2_style = lvgl.style_t()
    lvgl.style_copy(btn2_style, lvgl.btn_get_style(btn, lvgl.BTN_STYLE_REL))
    lvgl.btn_set_style(btn2, lvgl.BTN_STYLE_REL, btn2_style)
    style_anim = lvgl.anim_t()
    lvgl.style_anim_init(style_anim)
    lvgl.style_anim_set_styles(style_anim, btn2_style, lvgl.style_btn_rel, lvgl.style_pretty)
    lvgl.style_anim_set_time(style_anim, 500, 500)
    lvgl.style_anim_set_playback(style_anim, 500)
    lvgl.style_anim_set_repeat(style_anim, 500)
    lvgl.style_anim_create(style_anim)
    -- lvgl.disp_load_scr(scr)
    sys.timerStart(stop_anim, 3000)
    return scr
end


-- lvgl.init(create, nil)