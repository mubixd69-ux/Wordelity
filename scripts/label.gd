extends Label

var speed = 100
var special = ""
var original = ""
var pop_tween = null

func _process(delta: float) -> void:
	if get_parent().frozen:
		return
	var factor = 0.5 if get_parent().slow else 1.0
	position.y += speed * factor * delta
	if position.y > 600:
		get_parent().word_missed(self)
		queue_free()

func pop():
	if pop_tween:
		pop_tween.kill()
	pivot_offset = size / 2
	scale = Vector2(1.4, 1.4)
	rotation = randf_range(-0.25, 0.25)
	pop_tween = create_tween()
	pop_tween.set_parallel(true)
	pop_tween.tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop_tween.tween_property(self, "rotation", 0.0, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
