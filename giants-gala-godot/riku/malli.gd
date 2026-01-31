extends Control

@onready var orig_pos :Vector2= position

func _ready():
	position.x -= 500

func _process(delta):
	if Jattilaiset.end_countdown > 1:
		var l := 1 - pow(0.1, delta)
		position.x = lerpf(position.x, orig_pos.x - 500, l)
	elif Jattilaiset.countdown < 0.7:
		var l := 1 - pow(0.1, delta)
		position.x = lerpf(position.x, orig_pos.x, l)
