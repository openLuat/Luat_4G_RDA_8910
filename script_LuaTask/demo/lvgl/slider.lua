module(...,package.seeall)

function create()
    scr = lvgl.cont_create(nil, nil)
    style_bg = lvgl.style_t()
    style_indic = lvgl.style_t()
    style_knob = lvgl.style_t()

    lvgl.style_copy(style_bg, lvgl.style_pretty)
    style_bg.body.main_color = lvgl.color_hex(0x00ff00)
    style_bg.body.grad_color = lvgl.color_hex(0x000080)
    style_bg.body.radius = lvgl.RADIUS_CIRCLE
    style_bg.body.border.color = lvgl.color_hex(0xffffff)

    lvgl.style_copy(style_indic, lvgl.style_pretty_color)
    style_indic.body.radius = lvgl.RADIUS_CIRCLE
    style_indic.body.shadow.width = 8
    style_indic.body.shadow.color = style_indic.body.main_color
    style_indic.body.padding.left = 3
    style_indic.body.padding.right = 3
    style_indic.body.padding.top = 3
    style_indic.body.padding.bottom = 3

    lvgl.style_copy(style_knob, lvgl.style_pretty)
    style_knob.body.radius = lvgl.RADIUS_CIRCLE
    style_knob.body.opa = lvgl.OPA_70
    style_knob.body.padding.top = 10
    style_knob.body.padding.bottom = 10

    slider = lvgl.slider_create(scr, nil)
    lvgl.obj_set_size(slider, 100, 20)
    lvgl.slider_set_style(slider, lvgl.SLIDER_STYLE_BG, style_bg)
    lvgl.slider_set_style(slider, lvgl.SLIDER_STYLE_INDIC, style_indic)
    lvgl.slider_set_style(slider, lvgl.SLIDER_STYLE_KNOB, style_knob)
    lvgl.obj_align(slider, nil, lvgl.ALIGN_CENTER, 0, 0)
    -- lvgl.disp_load_scr(scr)

    label = lvgl.label_create(scr, nil)
    lvgl.label_set_text(label, "滑动条")
    lvgl.obj_align(label, slider, lvgl.ALIGN_OUT_BOTTOM_MID, 0, 0)
    return scr
end

-- lvgl.init(create, nil)