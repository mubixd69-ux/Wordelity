extends Control

var starting = false
var words = {}
var locked = null
var idle = 0.0
var hint_shown = false
var drift_words = ["pop", "jelly", "wiggle", "boing", "cookie", "zigzag", "sparkle", "bubble", "noodle", "waffle", "puddle"]


@onready var title = $Title
@onready var fade = $Fade

func _ready() -> void:
	words = {$PlayButton: "play", $QuitButton: "quit"}
	$PlayButton.text = "play"
	$QuitButton.text = "quit"
	
	$PlayButton.pressed.connect(start_game)
	$QuitButton.pressed.connect(get_tree().quit)
	setup_hover($PlayButton)
	setup_hover($QuitButton)
	
	title.pivot_offset = title.size / 2
	title.scale = Vector2.ZERO
	var intro = create_tween()
	intro.tween_property(title, "scale", Vector2.ONE, 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	var sway = create_tween().set_loops()
	sway.tween_property(title, "rotation", 0.04, 1.2).set_trans(Tween.TRANS_SINE)
	sway.tween_property(title, "rotation", -0.04, 1.2).set_trans(Tween.TRANS_SINE)
	
	var spawner = Timer.new()
	spawner.wait_time = 0.9
	spawner.timeout.connect(spawn_drift_word)
	add_child(spawner)
	spawner.start()
	for i in range(7):
		spawn_drift_word(true)
	
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			start_game()
			return
		if event.unicode == 0 or starting:
			return
		var letter = char(event.unicode).to_lower()
		
		idle = 0.0
		if hint_shown:
			hint_shown = false
			create_tween().tween_property($Hint, "modulate:a", 0.0, 0.2)
		
		if locked == null:
			for b in words:
				if b.text.begins_with(letter):
					locked = b
		
		if locked == null:
			return
		
		if locked.text.begins_with(letter):
			locked.text = locked.text.substr(1)
			fly_letter(locked, letter)
			locked.scale = Vector2(1.3, 1.3)
			hover(locked, true)
			if locked.text == "":
				var done = locked
				locked = null
				if done == $QuitButton:
					quit_game()
				else:
					start_game()
		
		else:
			wobble(locked)
			locked.text = words[locked]
			hover(locked, false)
			locked = null

func start_game():
	if starting:
		return
	starting = true
	await  squish($PlayButton)
	var t = create_tween()
	t.tween_property(fade, "color:a", 1.0, 0.4)
	await t.finished
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	
func setup_hover(button):
	button.pivot_offset = button.size / 2
	button.mouse_entered.connect(hover.bind(button, true))
	button.mouse_exited.connect(hover.bind(button, false))

func hover(button, on):
	if button.has_meta("tween"):
		button.get_meta("tween").kill()
	var t = create_tween().set_parallel(true)
	button.set_meta("tween", t)
	t.tween_property(button, "scale", Vector2(1.12, 1.12)if on else Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(button, "modulate", Color(1.3, 1.25, 1.1) if on else Color.WHITE, 0.18)
	
func fly_letter(button, letter):
	var l = Label.new()
	l.text = letter
	l.add_theme_font_size_override("font_size", button.get_theme_font_size("font_size"))
	l.add_theme_constant_override("outline_size", 10)
	l.add_theme_color_override("font_outline_color", Color("3b1f4a"))
	add_child(l)
	l.position = button.global_position + button.size / 2 - Vector2(10, 25)
	var t = create_tween().set_parallel(true)
	t.tween_property(l, "position", l.position + Vector2(randf_range(-80, 80), -120), 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(l, "rotation", randf_range(-1.5, 1.5), 0.5)
	t.tween_property(l, "modulate:a", 0.0, 0.5)
	t.chain().tween_callback(l.queue_free)
	
func wobble(button):
	var t = create_tween()
	t.tween_property(button, "rotation", 0.12, 0.05)
	t.tween_property(button, "rotation", -0.12, 0.1)
	t.tween_property(button, "rotation", 0.0, 0.05)
	

func quit_game():
	starting = true
	await squish($QuitButton)
	var t = create_tween()
	t.tween_property(fade, "color:a", 1.0, 0.4)
	await t.finished
	get_tree().quit()

func _process(delta: float) -> void:
	if starting or locked != null or hint_shown:
		return
	idle += delta
	if idle >= 4.0:
		hint_shown = true
		create_tween().tween_property($Hint, "modulate:a", 1.0, 0.4)
		wobble($PlayButton)
	

func spawn_drift_word(prefill = false):
	var l = Label.new()
	l.text = drift_words.pick_random()
	l.add_theme_font_size_override("font_size", randi_range(36, 64))
	l.add_theme_constant_override("outline_size", 10)
	l.add_theme_color_override("font_outline_color", Color("3b1f4a"))
	l.modulate = Color.from_hsv(randf(), 0.35, 1.0, 0.0)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	move_child(l, 1)
	
	var start_y = 700.0
	if prefill:
		start_y = randf_range(100.0, 600.0)
	l.position = Vector2(randf_range(40, 1050), start_y)
	l.rotation = randf_range(-0.2, 0.2)
	
	var time = randf_range(9.0, 14.0) * (start_y + 100.0) / 800.0
	var t = l.create_tween().set_parallel(true)
	t.tween_property(l, "position:y", - 100.0, time)
	t.tween_property(l, "modulate:a", 0.5, 1.0)
	t.tween_property(l, "modulate:a", 0.0, 1.0).set_delay(maxf(time - 1.0, 1.0))
	t.chain().tween_callback(l.queue_free)
	
	var sway = l.create_tween().set_loops()
	sway.tween_property(l, "rotation", l.rotation + 0.15, 1.5).set_trans(Tween.TRANS_SINE)
	sway.tween_property(l, "rotation", l.rotation - 0.15, 1.5).set_trans(Tween.TRANS_SINE)
	
func squish(button):
	if button.has_meta("tween"):
		button.get_meta("tween").kill()
	var t = create_tween()
	t.tween_property(button, "scale", Vector2(1.3, 0.7), 0.08)
	t.tween_property(button, "scale", Vector2(0.9, 1.15), 0.1)
	t.tween_property(button, "scale", Vector2.ONE, 0.1)
	await t.finished






	
	
