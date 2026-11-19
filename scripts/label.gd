extends Label

var speed = 100
var special = ""
var original = ""
var pop_tween = null
var base_color = Color.WHITE
var lock_color = Color.YELLOW
var normal_outline = 10
var ice = null
var shiver_tween = null
var shiver_base_x = 0.0
var glow_node = null

func _process(delta: float) -> void:
	if get_parent().frozen or get_parent().round_intro:
		return
	var factor = 0.5 if get_parent().slow else 1.0
	position.y += speed * factor * delta
	if position.y > 430:
		get_parent().word_missed(self)
		queue_free()

func _ready() -> void:
	normal_outline = get_theme_constant("outline_size")
	if special != "":
		var glow = create_tween().set_loops()
		glow.tween_property(self, "self_modulate", Color(0.63, 0.63, 0.63), 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		glow.tween_property(self, "self_modulate", Color.WHITE, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
func pop(letter):
	if pop_tween:
		pop_tween.kill()
	pivot_offset = size / 2
	scale = Vector2(1.4, 1.4)
	rotation = randf_range(-0.25, 0.25)
	modulate = Color(3, 3, 3)
	pop_tween = create_tween()
	pop_tween.set_parallel(true)
	pop_tween.tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop_tween.tween_property(self, "rotation", 0.0, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop_tween.tween_property(self, "modulate", lock_color, 0.15)
	fly_off(letter)

func fly_off(letter):
	var flyer = Label.new()
	flyer.text = letter
	flyer.add_theme_font_size_override("font_size", get_theme_font_size("font_size") + 6)
	flyer.modulate = Color.YELLOW
	flyer.position = position
	flyer.pivot_offset = Vector2(10, 10)
	get_parent().add_child(flyer)
	
	var target = position + Vector2(randf_range(-90, 90), randf_range(-130, -70))
	var tween = flyer.create_tween()
	tween.set_parallel(true)
	tween.tween_property(flyer, "position", target, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(flyer, "rotation", randf_range(-1.5, 1.5), 0.5)
	tween.tween_property(flyer, "scale", Vector2(1.8, 1.8), 0.5)
	tween.tween_property(flyer, "modulate:a", 0.0, 0.35).set_delay(0.15)
	tween.chain().tween_callback(flyer.queue_free)

func lock_on():
	modulate = lock_color
	add_theme_constant_override("outline_size", normal_outline + 6)

func lock_off():
	modulate = base_color
	add_theme_constant_override("outline_size", normal_outline)

func freeze_on():
	if ice != null:
		return
	create_tween().tween_property(self, "self_modulate", Color(0.65, 0.88, 1.0), 0.3)
	
	shiver_base_x = position.x
	shiver_tween = create_tween().set_loops()
	shiver_tween.tween_property(self, "position:x", shiver_base_x -1.5, 0.04 )
	shiver_tween.tween_property(self, "position:x", shiver_base_x + 1.5, 0.04)
	
	glow_node = make_glow()
	var glow_scale = Vector2(size.x * 1.7, size.y * 2.6) / 128.0
	glow_node.position = position + size / 2
	glow_node.scale = glow_scale * 0.04
	glow_node.modulate.a = 0.0
	get_parent().add_child(glow_node)
	get_parent().move_child(glow_node, get_index())
	var glow_in = create_tween().set_parallel(true)
	glow_in.tween_property(glow_node, "scale", glow_scale, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	glow_in.tween_property(glow_node, "modulate:a", 1.0, 0.5)
	
	
	ice = Node2D.new()
	ice.position = position
	get_parent().add_child(ice)
	get_parent().move_child(ice, get_index())
	
	var center = size / 2
	var a = size.x / 2 + 2
	var b = size.y / 2- 2
	var n = clampi(int(size.x / 26.0) + 3, 5, 12)
	for i in range(n):
		var t = (float(i) + randf_range(0.15, 0.85)) / n * TAU
		var normal = Vector2(cos(t) / a, sin(t) / b).normalized()
		var c = make_crystal()
		c.position = center + Vector2(cos(t) * a, sin(t) * b)
		c.rotation = normal.angle() + PI / 2 + randf_range(-0.25, 0.25)
		var s = randf_range(0.8, 1.25)
		c.scale = Vector2(0.3, 0.0)
		ice.add_child(c)
		var grow = create_tween()
		grow.tween_property(c, "scale", Vector2(s, s), 0.4).set_delay( i * 0.04).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
		
		
		
	if not tree_exiting.is_connected(freeze_off):
		tree_exiting.connect(freeze_off)

func freeze_off():
	if ice == null:
		return
	if shiver_tween:
		shiver_tween.kill()
	position.x = shiver_base_x
	self_modulate = Color.WHITE
	
	if glow_node:
		var gnode = glow_node
		glow_node = null
		var gt = gnode.create_tween()
		gt.tween_property(gnode, "modulate:a", 0.0, 0.4)
		gt.tween_callback(gnode.queue_free)
	
	var shards = ice
	ice = null
	for c in shards.get_children():
		var t = c.create_tween()
		t.set_parallel(true)
		var out = Vector2.from_angle(c.rotation - PI / 2) * randf_range(20.0, 50.0)
		t.tween_property(c, "position", c.position + out + Vector2(0, randf_range(60.0, 120.0)), 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		t.tween_property(c, "rotation", c.rotation + randf_range(-3.0, 3.0), 0.6)
		t.tween_property(c, "modulate:a", 0.0, 0.3).set_delay(0.3)
	shards.get_tree().create_timer(0.8).timeout.connect(shards.queue_free)

func make_crystal():
	var h = randf_range(12.0, 24.0)
	var w = h * 0.42
	var node = Node2D.new()
	
	var left = Polygon2D.new()
	left.polygon = PackedVector2Array([Vector2(0, -h), Vector2(0, h * 0.5), Vector2(-w, 0)])
	left.color = Color("#d9f3ff")
	var right = Polygon2D.new()
	right.polygon = PackedVector2Array([Vector2(0, -h), Vector2(w, 0), Vector2(0, h * 0.5)])
	right.color = Color("#8fd0f5")
	
	var outline = Line2D.new()
	outline.points = PackedVector2Array([Vector2(0, -h), Vector2(w, 0), Vector2(0, h * 0.5), Vector2(-w, 0)])
	outline.closed = true
	outline.width = 2.5
	outline.default_color = Color("#3b1f4a")
	outline.joint_mode = Line2D.LINE_JOINT_ROUND
	
	left.position = Vector2(0, -h * 0.5)
	right.position = Vector2(0, -h * 0.5)
	outline.position = Vector2(0, -h * 0.5)
	
	node.add_child(left)
	node.add_child(right)
	node.add_child(outline)
	return node

func make_glow():
	var g = Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 1.0])
	g.colors = PackedColorArray([Color(0.55, 0.9, 1.0, 0.85), Color(0.55, 0.9, 1.0, 0.0)])
	var tex = GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 128
	tex.height = 128
	var s = Sprite2D.new()
	s.texture = tex
	return s
