extends Node2D

var radius = 10.0
var alpha = 1.0
var ring_color = Color(1, 0.92, 0.6)
var max_radius = 900.0

func _draw():
		draw_arc(Vector2.ZERO, radius, 0, TAU, 96, Color(ring_color.r, ring_color.g, ring_color.b, alpha), 14.0 * alpha + 2.0, true)

func _process(delta: float) -> void:
	queue_redraw()

func start():
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "radius", max_radius, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "alpha", 0.0, 0.6)
	tween.chain().tween_callback(queue_free)
