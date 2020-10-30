module(...,package.seeall)

local function create()
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
    lvgl.disp_load_scr(scr)
end


lvgl.init(create, nil)