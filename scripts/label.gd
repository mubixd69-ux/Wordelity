extends Label

var speed = 100

func _process(delta: float) -> void:
	position.y += speed * delta
	if position.y > 700:
		queue_free()
