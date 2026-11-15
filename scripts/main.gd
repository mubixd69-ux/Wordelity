extends Node2D

var word_scene = preload("res://scenes/word.tscn")
var words = ["cat", "dog", "sun", "pig", "hat", "bee", "owl", "ant", "fox", "bus", "cup", "map", "moon", "star", "tree", "fish", "cake", "frog", "bird", "rain", "snow", "wind", "book", "ship", "duck", "bear", "kite", "rabbit", "garden", "wizard", "rocket", "dragon", "balloon", "penguin", "rainbow", "elephant", "adventure"]
var specials = {"life": Color.GREEN, "freeze": Color.CYAN, "boom": Color.RED}
var locked_word = null
var lives = 5
var score = 0
var combo = 0
var frozen = false
var letter_timnes = []
var start_time = 0
var forbidden = []
var round_number = 1

@onready var score_label = $ScoreLabel
@onready var lives_label = $LivesLabel
@onready var combo_label = $ComboLabel
@onready var forbidden_label = $ForbiddenLabel
@onready var wpm_label = $WPMLabel

func _on_timer_timeout():
	if frozen:
		return
		
	var blocked = []
	for w in get_tree().get_nodes_in_group("words"):
		if forbidden.has(w.original):
			blocked.append(w.original[0])
	
	var max_length = 3 + int(score / 400.0)
	var choices = words.filter(func(w): return w.length() <= max_length and not blocked.has(w[0]))
	if choices.is_empty():
		return
	
	var word = word_scene.instantiate()
	if randf() < 0.25 and not forbidden.is_empty():
		word.text = forbidden.pick_random()
	elif randf() < 0.1:
		var kind = specials.keys().pick_random()
		word.text = kind
		word.special = kind
		word.modulate = specials[kind]
	else:
		word.text = choices.pick_random()
	word.original = word.text
	word.speed = minf(60 + score / 40.0, 250)
	word.position.x = randf_range(50, 1050)
	word.position.y = -20
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
				
				if start_time == 0:
					start_time = Time.get_ticks_msec()
				letter_timnes.append(Time.get_ticks_msec())
				
				if not forbidden.has(locked_word.original):
					score += 10 * (1 + int(combo / 5.0))
				
				if locked_word.text == "":
					if forbidden.has(locked_word.original):
						lives -= 1
						combo = 0
						if lives <= 0:
							get_tree().reload_current_scene()
					else:
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
	if forbidden.has(word.original):
		return
	lives -= 1
	combo = 0
	update_labels()
	if lives <= 0:
		get_tree().reload_current_scene()

func _ready() -> void:
	update_labels()
	new_round()

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
	


func _on_round_timer_timeout() -> void:
	round_number += 1
	new_round()
	
func new_round():
	forbidden.clear()
	var pool = words.filter(func(w): return w.length() <= 5)
	pool.shuffle()
	var used_letters = []
	for w in pool:
		if forbidden.size() >= mini(1 + round_number, 4):
			break
		if not used_letters.has(w[0]):
			forbidden.append(w)
			used_letters.append(w[0])
	forbidden_label.text = "DONT TYPE: " + ", ".join(forbidden)

func _process(delta: float) -> void:
	if start_time == 0:
		return
	var now = Time.get_ticks_msec()
	while not letter_timnes.is_empty() and now - letter_timnes[0] > 10000:
		letter_timnes.pop_front()
	var seconds = clampf((now - start_time) / 1000.0, 2.0, 10.0)
	var wpm = (letter_timnes.size() / 5.0) / (seconds / 60.0)
	wpm_label.text = "WPM: " + str(int(wpm))
