extends Node2D

var word_scene = preload("res://scenes/word.tscn")
var words = ["cat", "dog", "sun", "moon", "star", "tree", "fish", "cake", "frog", "bird", "rabbit", "garden", "wizard", "rocket", "dragon", "balloon", "penguin", "rainbow", "elephant", "adventure"]
var specials = {"life": Color.GREEN, "freeze": Color.CYAN, "boom": Color.RED}
var locked_word = null
var lives = 5
var score = 0
var combo = 0
var frozen = false

@onready var score_label = $ScoreLabel
@onready var lives_label = $LivesLabel
@onready var combo_label = $ComboLabel

func _on_timer_timeout():
	if frozen:
		return
	var word = word_scene.instantiate()
	var max_length = 3 + int(score/ 400.0)
	var choices = words.filter(func(w): return w.length() <= max_length)
	word.text = choices.pick_random()
	
	if randf() < 0.1:
		var kind = specials.keys().pick_random()
		word.text = kind
		word.special = kind
		word.modulate = specials[kind]
	
	word.position.x = randf_range(50, 1050)
	word.position.y = -20
	word.speed = minf(60 + score / 40.0, 250)
	word.add_to_group("words")
	add_child(word)
	
	$Timer.wait_time = maxf(0.8, 2.0 - score / 2000.0)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.is_echo():
		
		if event.keycode == KEY_ESCAPE:
			if locked_word != null:
				locked_word.modulate = specials.get(locked_word.special, Color.WHITE)
				locked_word = null
				combo = 0
				update_labels()
			return
		
		if event.unicode == 0:
			return
		
		var letter = char(event.unicode).to_lower()
		
		if locked_word == null:
			for word in get_tree().get_nodes_in_group("words"):
				if word.text.begins_with(letter):
					if locked_word == null or word.position.y > locked_word.position.y:
						locked_word = word
			if locked_word != null:
				locked_word.modulate = Color.YELLOW
				
		
		if locked_word != null:
			if locked_word.text.begins_with(letter):
				locked_word.text = locked_word.text.substr(1)
				score += 10 * (1+ int(combo / 5.0))
				
				if locked_word.text == "":
					combo += 1
					use_special(locked_word.special)
					
					if combo % 10 == 0:
						lives = mini(lives + 1, 5)
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

func use_special(kind):
	if kind == "life":
		lives = mini(lives + 1, 5)
	elif kind == "freeze":
		frozen = true
		await get_tree().create_timer(4.0).timeout
		frozen = false
	elif kind == "boom":
		for word in get_tree().get_nodes_in_group("words"):
			word.queue_free()
	
