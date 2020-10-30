module(...,package.seeall)

require "sys"

sw = nil

local function sw_on()
	lvgl.sw_on(sw, lvgl.ANIM_ON)
end

local function sw_off()
	lvgl.sw_off(sw, lvgl.ANIM_ON)
end

local function sw_toggle(on)
	if on then
		sw_on()
	else
		sw_off()
	end
	sys.timerStart(sw_toggle, 1000, not on)
end

function create()
	scr = lvgl.cont_create(nil, nil)
	bg_style = lvgl.style_t()
	indic_style = lvgl.style_t()
	knob_on_style = lvgl.style_t()
	knob_off_style = lvgl.style_t()

	lvgl.style_copy(bg_style, lvgl.style_pretty)
	bg_style.body.radius = lvgl.RADIUS_CIRCLE
	bg_style.body.padding.top = 6
	bg_style.body.padding.bottom = 6

	lvgl.style_copy(indic_style, lvgl.style_pretty_color)
	indic_style.body.radius = lvgl.RADIUS_CIRCLE
	indic_style.body.main_color = lvgl.color_hex(0x9fc8ef)
	indic_style.body.grad_color = lvgl.color_hex(0x9fc8ef)
	indic_style.body.padding.left = 0
	indic_style.body.padding.right = 0
	indic_style.body.padding.top = 0
	indic_style.body.padding.bottom = 0

	lvgl.style_copy(knob_off_style, lvgl.style_pretty_color)
	knob_off_style.body.radius = lvgl.RADIUS_CIRCLE
	knob_off_style.body.shadow.width = 4
	knob_off_style.body.shadow.type = lvgl.SHADOW_BOTTOM

	lvgl.style_copy(knob_on_style, lvgl.style_pretty_color)
	knob_on_style.body.radius = lvgl.RADIUS_CIRCLE
	knob_on_style.body.shadow.width = 4
	knob_on_style.body.shadow.type = lvgl.SHADOW_BOTTOM

	sw = lvgl.sw_create(scr, nil)
	lvgl.obj_align(sw, nil, lvgl.ALIGN_CENTER, 0, 0)

	lvgl.sw_set_style(sw, lvgl.SW_STYLE_BG, bg_style)
	lvgl.sw_set_style(sw, lvgl.SW_STYLE_INDIC, indic_style)
	lvgl.sw_set_style(sw, lvgl.SW_STYLE_KNOB_ON, knob_on_style)
	lvgl.sw_set_style(sw, lvgl.SW_STYLE_KNOB_OFF, knob_off_style)

	label = lvgl.label_create(scr, nil)
	lvgl.label_set_text(label, "开关")
	lvgl.obj_align(label, sw, lvgl.ALIGN_OUT_BOTTOM_MID, 0, 2)
	sys.timerStart(sw_toggle, 1000, true)
	return scr

end

-- lvgl.init(create, nil)