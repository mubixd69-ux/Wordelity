extends Label

var speed = 100
var special = ""
var original = ""
var pop_tween = null

func _process(delta: float) -> void:
	if get_parent().frozen or get_parent().round_intro:
		return
	var factor = 0.5 if get_parent().slow else 1.0
	position.y += speed * factor * delta
	if position.y > 430:
		get_parent().word_missed(self)
		queue_free()

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
	pop_tween.tween_property(self, "modulate", Color.YELLOW, 0.15)
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
