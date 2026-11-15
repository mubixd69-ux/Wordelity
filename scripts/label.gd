extends Label

var speed = 100
var special = ""
var original = ""

func _process(delta: float) -> void:
	if get_parent().frozen:
		return
	position.y += speed * delta
	if position.y > 600:
		get_parent().word_missed(self)
		queue_free()
