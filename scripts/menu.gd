extends Control

var starting = false

@onready var title = $Title
@onready var fade = $Fade

func _ready() -> void:
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
	
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			start_game()

func start_game():
	if starting:
		return
	starting = true
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
	
	
	
