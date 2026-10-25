class_name CarArt
extends Control

const TRAM_IMAGE: String = "res://assets/png/car_tram.png"

var body_color: Color = Color(0.8, 0.8, 0.85)
var kind: String = "sedan"
var image_path: String = ""
var _texture: Texture2D

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(280, 180)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	resized.connect(queue_redraw)
	queue_redraw()

func set_car(color: Color, car_kind: String, img_path: String = "") -> void:
	body_color = color
	kind = car_kind
	image_path = img_path
	if image_path == "" and kind == "tram":
		image_path = TRAM_IMAGE
	_texture = null
	if image_path != "":
		var tex = load(image_path)
		if tex is Texture2D:
			_texture = tex
	queue_redraw()

func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	if w <= 0.0 or h <= 0.0:
		w = custom_minimum_size.x
		h = custom_minimum_size.y
	if _texture != null:
		var tex_size: Vector2 = _texture.get_size()
		if tex_size.x <= 0.0 or tex_size.y <= 0.0:
			return
		var scale: float = minf(w / tex_size.x, h / tex_size.y)
		var draw_size: Vector2 = tex_size * scale
		var offset: Vector2 = Vector2((w - draw_size.x) * 0.5, (h - draw_size.y) * 0.5)
		draw_texture_rect(_texture, Rect2(offset, draw_size), false)
		return
	if kind == "tram":
		_draw_tram(w, h)
		return
	draw_rect(Rect2(0.0, 0.0, w, h), Color(0.08, 0.1, 0.14, 0.25))
	var pad: float = min(w, h) * 0.1
	var cx: float = pad
	var cy: float = pad
	var cw: float = w - pad * 2.0
	var ch: float = h - pad * 2.0
	if cw <= 0.0:
		cw = w
	if ch <= 0.0:
		ch = h
	var base_scale: float = min(cw * 0.72, ch * 1.1)
	if base_scale < 90.0:
		base_scale = min(cw, ch) * 0.6
	draw_rect(Rect2(cx + (cw - base_scale * 1.9) * 0.5, cy + ch - base_scale * 0.16, base_scale * 1.9, base_scale * 0.09), Color(0.1, 0.12, 0.16, 0.7))

	var body_top: float = 0.48
	var body_h: float = 0.32
	var roof_h: float = 0.19
	if kind == "boxy":
		body_top = 0.46
		body_h = 0.34
		roof_h = 0.22
	elif kind == "sport":
		body_top = 0.56
		body_h = 0.26
		roof_h = 0.16

	var wheel_y: float = cy + ch * 0.9
	var wheel_r: float = base_scale * (0.14 if kind == "sport" else 0.17)

	var body = StyleBoxFlat.new()
	body.bg_color = body_color
	body.set_corner_radius_all(int(base_scale * 0.09))
	draw_style_box(body, Rect2(cx + (cw - base_scale * 2.0) * 0.5, cy + ch * body_top, base_scale * 2.0, ch * body_h))

	var roof = StyleBoxFlat.new()
	roof.bg_color = body_color.darkened(0.05)
	roof.set_corner_radius_all(int(base_scale * 0.08))
	var roof_rect = Rect2(cx + (cw - base_scale * 1.28) * 0.5, cy + ch * (body_top - roof_h + 0.02), base_scale * 1.28, ch * (roof_h + 0.09))
	draw_style_box(roof, roof_rect)

	var glass = StyleBoxFlat.new()
	glass.bg_color = Color(0.55, 0.72, 0.85, 0.9)
	glass.set_corner_radius_all(int(base_scale * 0.05))
	var win_w: float = roof_rect.size.x * 0.38
	draw_style_box(glass, Rect2(roof_rect.position.x + roof_rect.size.x * 0.08, roof_rect.position.y + ch * 0.04, win_w, roof_rect.size.y - ch * 0.07))
	draw_style_box(glass, Rect2(roof_rect.position.x + roof_rect.size.x * 0.54, roof_rect.position.y + ch * 0.04, win_w, roof_rect.size.y - ch * 0.07))

	_draw_wheel(cx + cw * 0.28, wheel_y, wheel_r)
	_draw_wheel(cx + cw * 0.72, wheel_y, wheel_r)

	draw_circle(Vector2(cx + cw * 0.92, cy + ch * (body_top + body_h * 0.38)), wheel_r * 0.26, Color(1.0, 0.95, 0.6))
	draw_rect(Rect2(cx + cw * 0.1, cy + ch * (body_top + body_h * 0.34), cw * 0.015, ch * 0.09), Color(0.9, 0.3, 0.3))

func _draw_wheel(cx: float, cy: float, r: float) -> void:
	draw_circle(Vector2(cx, cy), r, Color(0.08, 0.09, 0.11))
	draw_circle(Vector2(cx, cy), r * 0.55, Color(0.65, 0.68, 0.72))
	draw_circle(Vector2(cx, cy), r * 0.2, Color(0.35, 0.37, 0.4))

func _draw_tram(w: float, h: float) -> void:
	var pad: float = min(w, h) * 0.12
	var body_w: float = w - pad * 2.0
	var body_h: float = (h - pad * 2.0) * 0.72
	var bx: float = pad
	var by: float = pad + (h - pad * 2.0) * 0.06
	var body_col: Color = Color(0.85, 0.35, 0.3)

	var body = StyleBoxFlat.new()
	body.bg_color = body_col
	body.set_corner_radius_all(int(min(body_w, body_h) * 0.12))
	draw_style_box(body, Rect2(bx, by, body_w, body_h))

	var stripe_h: float = body_h * 0.16
	draw_rect(Rect2(bx, by + body_h - stripe_h, body_w, stripe_h), body_col.darkened(0.35))

	var win_col: Color = Color(0.6, 0.78, 0.9)
	var win_y: float = by + body_h * 0.12
	var win_h: float = body_h * 0.4
	var cols: int = 4
	var gap: float = body_w * 0.03
	var win_w: float = (body_w - gap * (cols + 1)) / float(cols)
	for i in cols:
		var wx: float = bx + gap + i * (win_w + gap)
		draw_rect(Rect2(wx, win_y, win_w, win_h), win_col)

	var wheel_r: float = body_h * 0.16
	var wheel_y: float = by + body_h + pad * 0.2
	_draw_wheel(bx + body_w * 0.2, wheel_y, wheel_r)
	_draw_wheel(bx + body_w * 0.8, wheel_y, wheel_r)

	var pole_x: float = bx + body_w * 0.5
	draw_line(Vector2(pole_x, by), Vector2(pole_x - body_w * 0.06, pad * 0.2), Color(0.3, 0.32, 0.35), 2.0)
