extends Node2D

var word_scene = preload("res://scenes/word.tscn")
var words = ["cat", "dog", "sun", "moon", "star", "tree", "fish", "cake", "frog", "bird", "rabbit", "garden", "wizard", "rocket", "dragon", "balloon", "penguin", "rainbow", "elephant", "adventure"]
var locked_word = null
var lives = 5
var score = 0
var combo = 0

@onready var score_label = $ScoreLabel
@onready var lives_label = $LivesLabel
@onready var combo_label = $ComboLabel

func _on_timer_timeout():
	var word = word_scene.instantiate()
	var max_length = 4 + int(score/ 200.0)
	var choices = words.filter(func(w): return w.length() <= max_length)
	word.text = choices.pick_random()
	word.position.x = randf_range(50, 1050)
	word.position.y = -20
	word.speed = minf(100 + score / 20.0, 400)
	word.add_to_group("words")
	add_child(word)
	
	$Timer.wait_time = maxf(0.4, 1.0 - score / 3000.0)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.unicode == 0:
			return
		
		var letter = char(event.unicode).to_lower()
		
		if locked_word == null:
			for word in get_tree().get_nodes_in_group("words"):
				if word.text.begins_with(letter):
					locked_word = word
					locked_word.modulate = Color.YELLOW
					break
		
		if locked_word != null:
			if locked_word.text.begins_with(letter):
				locked_word.text = locked_word.text.substr(1)
				score += 10 * (1+ int(combo / 5.0))
				if locked_word.text == "":
					combo += 1
					locked_word.queue_free()
					locked_word = null
			else:
					combo = 0
		else:
			combo = 0
		update_labels()
			
func word_missed(word):
	if word == locked_word:
		locked_word = null
	lives -= 1
	combo = 0
	update_labels()
	if lives <= 0:
		get_tree().reload_current_scene()

func _ready() -> void:
	update_labels()

func update_labels():
	score_label.text = "Score: " + str(score)
	lives_label.text = "Lives: " + str(lives)
	combo_label.text = "Combo: " + str(combo)
