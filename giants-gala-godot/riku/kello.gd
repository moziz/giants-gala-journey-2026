extends Control

@onready var control :RadialProgress= $Control

func _process(delta):
	control.progress = Jattilaiset.YHEN_PROGRESSI
