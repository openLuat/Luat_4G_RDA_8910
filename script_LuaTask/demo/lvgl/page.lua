module(...,package.seeall)

function create()
	black = lvgl.color_make(0, 0, 0)
	white = lvgl.color_make(0xff, 0xff, 0xff)
    scr = lvgl.cont_create(nil, nil)
    style_sb = lvgl.style_t()
    style_sb.body.main_color = black
    style_sb.body.grad_color = black
    style_sb.body.border.color = white
    style_sb.body.border.width = 1
    style_sb.body.border.opa = lvgl.OPA_70
    style_sb.body.radius = lvgl.RADIUS_CIRCLE
    style_sb.body.opa = lvgl.OPA_60
    style_sb.body.padding.right = 3
    style_sb.body.padding.bottom = 3
    style_sb.body.padding.inner = 8

    page = lvgl.page_create(scr, nil)
    lvgl.obj_set_size(page, 100, 150)
    lvgl.obj_align(page, nil, lvgl.ALIGN_CENTER, 0, 0)
    lvgl.page_set_style(page, lvgl.PAGE_STYLE_SB, style_sb)

    label = lvgl.label_create(page, nil)
    lvgl.label_set_long_mode(label, lvgl.LABEL_LONG_BREAK)
    lvgl.obj_set_width(label, lvgl.page_get_fit_width(page))
    lvgl.label_set_recolor(label, true)
    lvgl.label_set_text(label, [[
    	Air722UG
    	Air724UG
    	行1
    	行2
    	行3]])
    -- lvgl.disp_load_scr(scr)
    return scr
end


-- lvgl.init(create, nil)