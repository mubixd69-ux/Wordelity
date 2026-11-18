extends Node2D

var word_scene = preload("res://scenes/word.tscn")
var words = ["cat", "dog", "sun", "pig", "hat", "bee", "owl", "ant", "fox", "bus", "cup", "map", "moon", "star", "tree", "fish", "cake", "frog", "bird", "rain", "snow", "wind", "book", "ship", "duck", "bear", "kite", "rabbit", "garden", "wizard", "rocket", "dragon", "balloon", "penguin", "rainbow", "elephant", "adventure"]
var specials = {"life": Color.GREEN, "freeze": Color.CYAN, "boom": Color.RED, "slow": Color.DODGER_BLUE, "double": Color.GOLD}
var locked_word = null
var lives = 5
var score = 0
var combo = 0
var frozen = false
var slow = false
var double_score = false
var letter_timnes = []
var start_time = 0
var forbidden = []
var round_number = 1
var rush_meter = 0.0
var high_score = 0
var rush = false
var full_heart = preload("res://assets/DEMO_Cozy_UI_Pack_doboui/DEMO_Cozy_UI_Pack_doboui/Icons/Icons Outline/64px/IconsOutline37_64px.png")
var empty_heart = preload("res://assets/DEMO_Cozy_UI_Pack_doboui/DEMO_Cozy_UI_Pack_doboui/Icons/Icons Outline/64px/IconsOutline38_64px.png")
var heart_full = [true, true, true, true, true]
var round_intro = false

@onready var score_label = $ScoreLabel
@onready var combo_label = $ComboLabel
@onready var forbidden_label = $ForbiddenLabel
@onready var wpm_label = $WPMLabel
@onready var rush_bar = $RushBar
@onready var high_score_label = $HighScoreLabel
@onready var dim = $RoundOverlay/Dim
@onready var round_label = $RoundOverlay/RoundLabel
@onready var banned_row = $RoundOverlay/BannedRows
@onready var hearts = $Hearts.get_children()

func _on_timer_timeout():
	if frozen or round_intro:
		return
	
	var difficulty = 1.0 - exp(-score / 1200.0)
	
	var blocked = []
	for w in get_tree().get_nodes_in_group("words"):
		if forbidden.has(w.original):
			blocked.append(w.original[0])
	
	var max_length = 3 + int(score / 400.0)
	var choices = words.filter(func(w): return w.length() <= max_length and not blocked.has(w[0]))
	if choices.is_empty():
		return
	
	var word = word_scene.instantiate()
	if randf() < 0.25 and not forbidden.is_empty():
		word.text = forbidden.pick_random()
	elif randf() < 0.6:
		var kind = specials.keys().pick_random()
		word.text = kind
		word.special = kind
		word.modulate = specials[kind]
		word.base_color = specials[kind]
		word.lock_color = specials[kind]
	else:
		word.text = choices.pick_random()
	word.original = word.text
	word.speed = 45 + 125 * difficulty
	word.position.x = randf_range(50, 1050)
	word.position.y = 90
	word.add_to_group("words")
	add_child(word)
	
	$Timer.wait_time = 2.2 - 1.4 * difficulty
	
	
func _input(event: InputEvent) -> void:
	if round_intro:
		return
	if event is InputEventKey and event.pressed and not event.is_echo():
		
		if event.keycode == KEY_ESCAPE:
			if locked_word != null:
				locked_word.lock_off()
				locked_word = null
				combo = 0
				update_labels()
			return
		
		if event.unicode == 0:
			return
		
		var letter = char(event.unicode).to_lower()
		
		if locked_word == null:
			for word in get_tree().get_nodes_in_group("words"):
				if word.text.begins_with(letter):
					if locked_word == null or word.position.y > locked_word.position.y:
						locked_word = word
			if locked_word != null:
				locked_word.lock_on()
				
		
		if locked_word != null:
			if locked_word.text.begins_with(letter):
				locked_word.text = locked_word.text.substr(1)
				locked_word.pop(letter)
				
				if start_time == 0:
					start_time = Time.get_ticks_msec()
				letter_timnes.append(Time.get_ticks_msec())
				
				if not rush:
					rush_meter = minf(rush_meter + 6.0, 100.0)
					if rush_meter >= 100:
						rush = true
				
				if not forbidden.has(locked_word.original):
					score += 10 * (1 + int(combo / 5.0)) * (2 if double_score else 1) * (2 if rush else 1)
				
				if locked_word.text == "":
					if forbidden.has(locked_word.original):
						if not rush:
							lives -= 1
							combo = 0
						if lives <= 0:
							game_over()
					else:
						combo += 1
						use_special(locked_word.special, locked_word.position)
						if combo % 10 == 0:
							lives = mini(lives + 1, 5)
					locked_word.queue_free()
					locked_word = null
			else:
				
					combo = 0
		else:
			combo = 0
		update_labels()
			
func word_missed(word):
	if word == locked_word:
		locked_word = null
	if forbidden.has(word.original):
		return
	if rush:
		return
	lives -= 1
	combo = 0
	update_labels()
	if lives <= 0:
		game_over()

func _ready() -> void:
	load_high_score()
	update_labels()
	new_round()
	show_round_intro()

func update_labels():
	score_label.text = "Score: " + str(score)
	combo_label.text = "Combo: " + str(combo)
	high_score_label.text = "Best: " + str(maxi(high_score, score))
	update_hearts()

func use_special(kind, origin = Vector2.ZERO):
	if kind == "life":
		life_effect(origin)
	elif kind == "freeze":
		frozen = true
		for w in get_tree().get_nodes_in_group("words"):
			if w.text != "":
				w.freeze_on()
		await get_tree().create_timer(4.0).timeout
		frozen = false
		for w in get_tree().get_nodes_in_group("words"):
			w.freeze_off()
	elif kind == "boom":
		boom(origin)
	elif kind == "slow":
		slow = true
		slow_effect(5.0)
		await get_tree().create_timer(5.0).timeout
		slow = false
	elif kind == "double":
		double_score = true
		double_effect(3.0)
		await get_tree().create_timer(3.0).timeout
		double_score = false
	


func _on_round_timer_timeout() -> void:
	round_number += 1
	new_round()
	show_round_intro()
	
func new_round():
	forbidden.clear()
	var pool = words.filter(func(w): return w.length() <= 5)
	pool.shuffle()
	var used_letters = []
	for w in pool:
		if forbidden.size() >= mini(1 + round_number, 4):
			break
		if not used_letters.has(w[0]):
			forbidden.append(w)
			used_letters.append(w[0])
	forbidden_label.text = "\n".join(forbidden)

func _process(delta: float) -> void:
	if rush:
		rush_meter -= (100 / 6.0) * delta
		if rush_meter <= 0.0:
			rush_meter = 0.0
			rush = false
	else:
		rush_meter = maxf(rush_meter - 6.0 * delta, 0.0)
	rush_bar.value = rush_meter
	rush_bar.modulate = Color.GOLD if rush else Color.WHITE
	
	if start_time == 0:
		return
	var now = Time.get_ticks_msec()
	while not letter_timnes.is_empty() and now - letter_timnes[0] > 10000:
		letter_timnes.pop_front()
	var seconds = clampf((now - start_time) / 1000.0, 2.0, 10.0)
	var wpm = (letter_timnes.size() / 5.0) / (seconds / 60.0)
	wpm_label.text = "WPM: " + str(int(wpm))


# highscore saving

func save_high_score():
	var file = FileAccess.open("user://highscore.save", FileAccess.WRITE)
	file.store_32(high_score)

func load_high_score():
	if FileAccess.file_exists("user://highscore.save"):
		var file = FileAccess.open("user://highscore.save", FileAccess.READ)
		high_score = file.get_32()

func game_over():
	if score > high_score:
		high_score = score
		save_high_score()
	get_tree().reload_current_scene()

func update_hearts():
	for i in range(hearts.size()):
		var should_be_full = i >= hearts.size() - lives
		if should_be_full and not heart_full[i]:
			heart_full[i] = true
			hearts[i].texture = full_heart
			grow_in(hearts[i])
		elif not should_be_full and heart_full[i]:
			heart_full[i] = false
			break_heart(hearts[i])

func break_heart(heart):
	heart.pivot_offset = heart.size / 2
	var tween = create_tween()
	tween.tween_property(heart, "scale", Vector2(1.4, 1.4), 0.1)
	tween.set_parallel(true)
	tween.tween_property(heart, "scale", Vector2.ZERO, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(heart, "rotation", 0.8, 0.25)
	tween.chain().tween_callback(func():
		heart.texture = empty_heart
		heart.rotation = 0.0
	)
	tween.tween_property(heart, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
func grow_in(heart):
	heart.pivot_offset = heart.size / 2
	heart.scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(heart, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
func show_round_intro():
	round_intro = true
	$RoundTimer.stop()
	
	for child in banned_row.get_children():
		child.queue_free()
	banned_row.modulate.a = 1.0
	
	round_label.text = "ROUND " + str(round_number)
	round_label.modulate.a = 0.0
	round_label.scale = Vector2(0.6, 0.6)
	round_label.pivot_offset = round_label.size / 2
	
	var banned_labels = []
	for w in forbidden:
		var l = Label.new()
		l.text = w.to_upper()
		l.add_theme_font_size_override("font_size", 64)
		l.add_theme_constant_override("outline_size", 14)
		l.add_theme_color_override("font_outline_color", Color("3b1f4a"))
		l.modulate.a = 0.0
		banned_row.add_child(l)
		banned_labels.append(l)
	
	var tween = create_tween()
	tween.tween_property(dim, "color:a", 0.65, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(round_label, "modulate:a", 1.0, 0.4)
	tween.parallel().tween_property(round_label, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	for l in banned_labels:
		tween.tween_property(l, "modulate:a", 1.0, 0.3)
	
	tween.tween_interval(1.2)
	tween.tween_property(dim, "color:a", 0.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(round_label, "modulate:a", 0.0, 0.5)
	tween.parallel().tween_property(banned_row, "modulate:a", 0.0, 0.5)
	await tween.finished
	
	round_intro = false
	$RoundTimer.start()
	
func boom(origin):
	flash()
	shake(18.0, 0.4)
	
	var ring = Node2D.new()
	ring.set_script(preload("res://scripts/shockwave.gd"))
	ring.position = origin + Vector2(30, 20)
	add_child(ring)
	ring.start()
	
	var targets = get_tree().get_nodes_in_group("words")
	targets.sort_custom(func(a,b): return a.position.distance_to(origin) < b.position.distance_to(origin))
	var i = 0
	for w in targets:
		if w.text == "":
			continue
		w.remove_from_group("words")
		w.set_process(false)
		domino_pop(w, i * 0.07)
		i += 1

func domino_pop(w, delay):
	await get_tree().create_timer(delay).timeout
	if not is_instance_valid(w):
		return
	w.pivot_offset = w.size / 2
	confetti(w.position + Vector2(30, 20))
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(w, "scale", Vector2(1.6, 1.6), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(w, "modulate:a", 0.0, 0.18)
	tween.chain().tween_callback(w.queue_free)
	
func confetti(pos):
	var p = CPUParticles2D.new()
	p.position = pos
	p.one_shot = true
	p.emitting = true
	p.explosiveness = 1.0
	p.amount = 14
	p.lifetime = 0.7
	p.direction = Vector2(0, -1)
	p.spread = 180.0
	p.initial_velocity_min = 120.0
	p.initial_velocity_max = 320.0
	p.gravity = Vector2(0, 500)
	p.scale_amount_min = 4.0
	p.scale_amount_max = 8.0
	var g = Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.33, 0.66, 1.0])
	g.colors = PackedColorArray([Color("#ff6b6b"), Color("#ffd93d"), Color("#6bcb77"), Color("#4d96ff")])
	p.color_initial_ramp = g
	add_child(p)
	get_tree().create_timer(1.2).timeout.connect(p.queue_free)

func flash():
	var f = $FlashOverlay/Flash
	f.color.a - 0.85
	create_tween().tween_property(f, "color:a", 0.0, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
func shake(strength, duration):
	var tween = create_tween()
	var steps = 10
	for i in range(steps):
		var fallof = 1.0 - float(i) / steps
		var offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * strength * fallof
		tween.tween_property(self, "position", offset, duration / steps)
	tween.tween_property(self, "position", Vector2.ZERO, 0.05)
	
func life_effect(origin):
	var from = origin + Vector2(30, 20)
	
	var ring = Node2D.new()
	ring.set_script(preload("res://scripts/shockwave.gd"))
	ring.ring_color = Color("#5ee05e")
	ring.max_radius = 140.0
	ring.position = from
	add_child(ring)
	ring.start()
	
	if lives >= 5:
		return
	var idx = hearts.size() - lives - 1
	var target = hearts[idx].global_position + hearts[idx].size / 2
	fly_heart(from, target)

func fly_heart(from, to):
	var s = Sprite2D.new()
	s.texture = full_heart
	s.position = from
	s.scale = Vector2.ZERO
	add_child(s)
	var mid = (from + to) / 2 + Vector2(0, -140)
	var tween = create_tween()
	tween.tween_property(s, "scale", Vector2(1.1, 1.1), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_method(_bezier_step.bind(s, from, mid, to), 0.0, 1.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func():
		s.queue_free()
		lives = mini(lives + 1 , 5)
		update_labels()
	)

func _bezier_step(t, s, from, mid, to):
	if not is_instance_valid(s):
		return
	s.position = from.lerp(mid, t).lerp(mid.lerp(to, t), t)

func double_effect(duration):
	var old_color = score_label.modulate
	score_label.pivot_offset = score_label.size / 2
	score_label.modulate = Color("#ffd93d")
	var pulse = create_tween().set_loops(int(duration / 0.5))
	pulse.tween_property(score_label, "scale",Vector2(1.12, 1.12), 0.25).set_trans(Tween.TRANS_SINE)
	
	var badge = Node2D.new()
	badge.set_script(preload("res://scripts/badge.gd"))
	badge.position = score_label.global_position + Vector2(score_label.size.x + 40, score_label.size.y / 2)
	add_child(badge)
	badge.start(duration)
	
	for i in range(int(duration / 0.08)):
		spawn_star()
		await get_tree().create_timer(0.08).timeout
	
	score_label.modulate = old_color
	score_label.scale = Vector2.ONE

func spawn_star():
	var r = randf_range(9.0, 16.0)
	var star = Polygon2D.new()
	star.polygon = star_points(r)
	star.color = Color("#ffd93d")
	
	var outline = Line2D.new()
	outline.points = star_points(r)
	outline.closed = true
	outline.width = 3.0
	outline.default_color = Color("#3b1f4a")
	star.add_child(outline)
	
	star.position = Vector2(randf_range(60, 1090), 20)
	star.rotation = randf_range(0, TAU)
	add_child(star)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(star, "position:y", 540.0, randf_range(1.0, 1.6)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(star, "rotation", star.rotation + randf_range(-4.0, 4.0), 1.4)
	tween.tween_property(star, "modulate:a", 0.0, 0.5).set_delay(0.9)
	tween.chain().tween_callback(star.queue_free)
	
func star_points(r):
	var pts = PackedVector2Array()
	for i in range(10):
		var ang = -PI / 2 + i * PI / 5
		var rad = r if i % 2 == 0 else r * 0.45
		pts.append(Vector2(cos(ang), sin(ang)) * rad)
	return pts
	
func slow_effect(duration):
	var tint = $FlashOverlay/SlowTint
	var tween = create_tween()
	tween.tween_property(tint, "color:a", 0.22, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var beats = int((duration - 1.0) / 0.9)
	for i in range(beats):
		tween.tween_property(tint, "color:a", 0.14, 0.45).set_trans(Tween.TRANS_SINE)
		tween.tween_property(tint, "color:a", 0.24, 0.45).set_trans(Tween.TRANS_SINE)
	tween.tween_property(tint, "color:a", 0.0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	for i in range(int(duration / 0.12)):
		for w in get_tree().get_nodes_in_group("words"):
			if w.text != "":
				make_ghost(w)
		await get_tree().create_timer(0.12).timeout

func make_ghost(w):
	var g = Label.new()
	g.text = w.text
	g.position = w.position
	g.scale = w.scale
	g.rotation = w.rotation
	g.add_theme_font_size_override("font_size", w.get_theme_font_size("font_size"))
	g.add_theme_constant_override("outline_size", w.get_theme_constant("outline_size"))
	g.add_theme_color_override("font_outline_color", Color("#3b1f4a"))
	g.modulate = Color(0.5, 0.75, 1.0, 0.4)
	add_child(g)
	g.move_child(g, w.get_index())
	var tween = g.create_tween()
	tween.tween_property(g, "modulate:a", 0.0, 0.45)
	tween.tween_callback(g.queue_free)
	
	
	
