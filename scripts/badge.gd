extends Node2D

var progress = 1.0

func _draw() -> void:
	draw_arc(Vector2.ZERO, 22.0, 0, TAU, 48, Color(0.24, 0.12, 0.29, 0.5), 8.0, true)
	draw_arc(Vector2.ZERO, 22.0, -PI / 2, -PI / 2 + TAU * progress, 48, Color("#ffd93d"), 6.0, true)

func _process(delta: float) -> void:
	queue_redraw()

func start(duration):
	var label = Label.new()
	label.text = "x2"
	label.add_theme_font_override("font", preload("res://assets/Chewy-Regular.ttf"))
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_constant_override("outline_size", 6)
	label.add_theme_color_override("font_outline_color", Color("#3b1f4a"))
	label.size = Vector2(60, 40)
	label.position = -label.size / 2
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(label)
	
	scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "progress", 0.0, duration - 0.5)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)
