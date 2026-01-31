@tool
extends Control

@onready var pelaajien_ymparisto = $"../../Maailma/PelaajienYmparisto"
@onready var maalisisus = $Maalisisus
@onready var maalikehys = $Kehys

enum ToolType {
	PAINT,
	OBJECT
}

@export var paint_colors :Array[Color]= []
@export var objektit :Array[PackedScene]= []

var kopterit :Array[Helikopterimme]= []

func _ready():
	if Engine.is_editor_hint():
		return
	maalisisus.self_modulate = paint_colors.front()
	for child in pelaajien_ymparisto.get_children():
		if child is not Helikopterimme:
			continue
		kopterit.push_back(child)


func _process(delta):
	if Engine.is_editor_hint():
		var maalisisus = $Maalisisus
		if maalisisus and paint_colors.size() > 0:
			maalisisus.self_modulate = paint_colors.front()
		return

	if Jattilaiset.end_countdown > 1:
		var l := 1 - pow(0.001, delta)
		modulate.a = lerpf(modulate.a, 0, l)
		return

	if Jattilaiset.LOPUN_ALKU:
		return

	var paint_color := Color.WHITE
	if Jattilaiset.NYKY_JATTI_INDKESI < paint_colors.size():
		paint_color = paint_colors[Jattilaiset.NYKY_JATTI_INDKESI]
	maalisisus.self_modulate = paint_color
	var objekti :PackedScene= null
	if Jattilaiset.NYKY_JATTI_INDKESI < objektit.size():
		objekti = objektit[Jattilaiset.NYKY_JATTI_INDKESI]
		
	for kopteri in kopterit:
		var screen_pos :Vector2= get_viewport().get_camera_3d().unproject_position(kopteri.global_position)
		if get_rect().has_point(screen_pos):
			var pyssy :Pyssy= kopteri.find_child("Pyssy")
			if !pyssy:
				push_error("Kopterilla ei oo Pyssy lasta")
				continue
			if !objekti:
				pyssy.maali_valittu(paint_color)
			else:
				pyssy.objekti_valittu(objekti, paint_color)
