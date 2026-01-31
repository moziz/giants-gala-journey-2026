@tool
extends Control

@onready var pelaajien_ymparisto = $"../../Maailma/PelaajienYmparisto"
@onready var maalisisus = $Maalisisus
@onready var maalikehys = $Kehys

enum ToolType {
	PAINT,
	OBJECT
}
@export var tool_type :ToolType= ToolType.PAINT
@export var paint_color := Color.WHITE:
	set(new_color):
		paint_color = new_color
		self_modulate = new_color

@export var TODO_objektin_tyyppi :int= 1 # TEMP

var kopterit :Array[Helikopterimme]= []

func _ready():
	maalisisus.self_modulate = paint_color
	if tool_type != ToolType.PAINT:
		maalisisus.visible = false
		maalikehys.visible = false
	for child in pelaajien_ymparisto.get_children():
		if child is not Helikopterimme:
			continue
		kopterit.push_back(child)


func _process(delta):
	if Engine.is_editor_hint():
		maalisisus.self_modulate = paint_color
		return

	if Jattilaiset.end_countdown > 1:
		var l := 1 - pow(0.001, delta)
		modulate.a = lerpf(modulate.a, 0, l)
		return

	for kopteri in kopterit:
		var screen_pos :Vector2= get_viewport().get_camera_3d().unproject_position(kopteri.global_position)
		if get_rect().has_point(screen_pos):
			var pyssy :Pyssy= kopteri.find_child("Pyssy")
			if !pyssy:
				push_error("Kopterilla ei oo Pyssy lasta")
				continue
			if tool_type == ToolType.PAINT:
				pyssy.maali_valittu(paint_color)
			else:
				pyssy.objekti_valittu(TODO_objektin_tyyppi)
