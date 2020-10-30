module(...,package.seeall)

require "sys"

arc = nil

angles = 0

local function arc_loader()
	angles = angles + 5
	if angles < 180 then
		lvgl.arc_set_angles(arc, 180-angles, 180)
	else
		lvgl.arc_set_angles(arc, 540-angles, 180)
	end
	if angles == 360 then
		angles = 0
	end
end

function create()
    scr = lvgl.cont_create(nil, nil)
    style = lvgl.style_t()
    lvgl.style_copy(style, lvgl.style_plain)
    style.line.color = lvgl.color_hex(0x800000)
    style.line.width = 4

    arc = lvgl.arc_create(scr, nil)
    lvgl.arc_set_style(arc, lvgl.ARC_STYLE_MAIN, style)
    lvgl.arc_set_angles(arc, 180, 180)
    lvgl.obj_set_size(arc, 40, 40)
    lvgl.obj_align(arc, nil, lvgl.ALIGN_CENTER, -30, -30)
    arc_label = lvgl.label_create(scr, nil)
    lvgl.label_set_text(arc_label, "加载器")
    lvgl.obj_align(arc_label, arc, lvgl.ALIGN_OUT_RIGHT_MID, 4, 0)

    btn = lvgl.btn_create(scr, nil)
    btn_label = lvgl.label_create(btn, nil)
    lvgl.label_set_text(btn_label, "按钮")
    lvgl.obj_align(btn, nil, lvgl.ALIGN_CENTER, 0, 40)
    lvgl.obj_set_size(btn, 60, 60)

    sys.timerLoopStart(arc_loader, 100)

    return scr
end