extends Node2D

var word_scene = preload("res://scenes/word.tscn")
var words = ["cat", "dog", "sun", "moon", "star", "tree", "fish", "cake", "frog", "bird"]

func _on_timer_timeout():
	var word = word_scene.instantiate()
	word.text = words.pick_random()
	word.position.x = randf_range(50, 1050)
	word.position.y = -20
	word.add_to_group("words")
	add_child(word)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.unicode == 0:
			return
		var letter = char(event.unicode).to_lower()
		for word in get_tree().get_nodes_in_group("words"):
			if word.text.begins_with(letter):
				word.text = word.text.substr(1)
				if word.text == "":
					word.queue_free()
				break
