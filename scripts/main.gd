extends Node2D

var word_scene = preload("res://scenes/word.tscn")

func _on_timer_timeout():
	var word = word_scene.instantiate()
	word.position.x = randf_range(50, 1050)
	word.position.y = -20
	add_child(word)
