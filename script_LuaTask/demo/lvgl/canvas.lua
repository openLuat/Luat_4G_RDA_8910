module(...,package.seeall)

function create()
    scr = lvgl.cont_create(nil, nil)
    cv = lvgl.canvas_create(scr, nil)
	lvgl.canvas_set_buffer(cv, 100, 100)
    lvgl.obj_align(cv, nil, lvgl.ALIGN_CENTER, 0, 0)
    layer_id = lvgl.canvas_to_disp_layer(cv)
    disp.setactlayer(layer_id)
    width, data = qrencode.encode('http://www.openluat.com')
    l_w, l_h = disp.getlayerinfo()
    displayWidth = 100
    disp.putqrcode(data, width, displayWidth, (l_w-displayWidth)/2, (l_h-displayWidth)/2)
    disp.update()
    label = lvgl.label_create(scr, nil)
    lvgl.label_set_recolor(label, true)
    lvgl.label_set_text(label, "#008080 上海合宙")
    lvgl.obj_align(label, cv, lvgl.ALIGN_OUT_BOTTOM_MID, 0, 2)
    -- lvgl.disp_load_scr(scr)
    return scr
end


-- lvgl.init(create, nil)