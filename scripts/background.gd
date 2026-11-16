extends Sprite2D

var scroll_speed = Vector2(25, 25)

func _process(delta: float) -> void:
	region_rect.position += scroll_speed * delta
