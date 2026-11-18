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
	
	ice = Node2D.new()
	ice.position = position
	get_parent().add_child(ice)
	get_parent().move_child(ice, get_index())
	
	var center = size / 2
	for i in range(randi_range(5, 7)):
		var c = make_crystal()
		var dir = Vector2.from_angle(randf() * TAU)
		c.position = center + Vector2(dir.x * (size.x / 2 + 6),dir.y * (size.y / 2 + 2))
		c.rotation = dir.angle() + PI / 2 + randf_range(-0.3, 0.3)
		c.scale = Vector2.ZERO
		ice.add_child(c)
		create_tween().tween_property(c, "scale", Vector2.ONE * randf_range(0.8, 1.2), 0.25).set_delay(i * 0.05).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	if not tree_exiting.is_connected(freeze_off):
		tree_exiting.connect(freeze_off)

func freeze_off():
	if ice == null:
		return
	if shiver_tween:
		shiver_tween.kill()
	position.x = shiver_base_x
	self_modulate = Color.WHITE
	
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
