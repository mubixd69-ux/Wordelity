extends Label

var speed = 100

func _process(delta: float) -> void:
	position.y += speed * delta
	if position.y > 600:
		get_parent().word_missed(self)
		queue_free()
