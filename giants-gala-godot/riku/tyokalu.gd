@tool
extends Control

var pelaajien_ymparisto: Node
var on_rails_controller: Node  # For on-rails mode
@onready var maalisisus = $Maalisisus
@onready var maalikehys = $Kehys

## Which bucket index this is (0-4). Determined by node name.
var bucket_index: int = 0

enum ToolType {
	PAINT,
	OBJECT
}

static var vari_paletit :Array[Array]= [
	# Giant 0: Cyan, Light green, Pink, Red, Blue
	[Color("22bed5"), Color("8aab26"), Color("e74a4a"), Color("f26f19"), Color("c6d7c8")] as Array[Color],
	# Giant 1: Orange, White, Brown, Red, Green
	[Color("f26f19"), Color("fdffde"), Color("52190a"), Color("e74a4a"), Color("8aab26")] as Array[Color],
	# Giant 2: Brown, Yellow, Cyan, Red, Purple
	[Color("52190a"), Color("ffba00"), Color("22bed5"), Color("e74a4a"), Color("c040ff")] as Array[Color],
	# Giant 3: Red, Brown, White, Yellow, Black
	[Color("e74a4a"), Color("52190a"), Color("fdffde"), Color("ffba00"), Color("0a0914")] as Array[Color],
	# Giant 4: Yellow, Magenta, Green, Blue, Orange
	[Color("ffba00"), Color("ff40a0"), Color("40ff60"), Color("4080ff"), Color("ff8040")] as Array[Color],
]
static var obu_paletit :Array[Array]= [
	[preload("res://riku/koristeet/pitsi.tscn"), preload("res://riku/koristeet/pitsi.tscn"), null, null, null ] as Array[PackedScene],
	[null, null, preload("res://riku/koristeet/pilvi.tscn"), preload("res://riku/koristeet/kukka.tscn"), preload("res://riku/koristeet/lehti.tscn") ] as Array[PackedScene],
	[null, preload("res://riku/koristeet/viikset.tscn"), preload("res://riku/koristeet/pitsi3.tscn"), null, null ] as Array[PackedScene],
	[preload("res://riku/koristeet/kukka.tscn"), preload("res://riku/koristeet/pilvi.tscn"), preload("res://riku/koristeet/ketju.tscn"), null, null ] as Array[PackedScene],
	[null, null, preload("res://riku/koristeet/pitsi2.tscn"), preload("res://riku/koristeet/kaulus.tscn"), preload("res://riku/koristeet/ketju.tscn")] as Array[PackedScene],
]

var kopterit :Array[Helikopterimme]= []

func _ready():
	if Engine.is_editor_hint():
		return
	
	# Determine bucket index from node name
	# HUD_Tyokalu = 0, HUD_Tyokalu2 = 1, HUD_Tyokalu3 = 2, etc.
	var node_name = name
	if node_name == "HUD_Tyokalu":
		bucket_index = 0
	elif node_name.begins_with("HUD_Tyokalu"):
		var suffix = node_name.substr(11)  # len("HUD_Tyokalu") = 11
		if suffix.is_valid_int():
			bucket_index = suffix.to_int() - 1  # "2" -> 1, "3" -> 2, etc.
	
	# Try to find PelaajienYmparisto (helicopter mode)
	pelaajien_ymparisto = get_node_or_null("../../Maailma/PelaajienYmparisto")
	
	# Try to find OnRailsController (on-rails mode)
	on_rails_controller = get_node_or_null("../../Maailma/OnRailsController")
	
	# Need at least one mode to work
	if not pelaajien_ymparisto and not on_rails_controller:
		set_process(false)
		visible = false
		return
	
	# Set the initial bucket color
	var paint_colors :Array[Color]= vari_paletit[Jattilaiset.NYKY_JATTI_INDKESI] as Array[Color]
	var objektit :Array[PackedScene]= obu_paletit[Jattilaiset.NYKY_JATTI_INDKESI] as Array[PackedScene]
	if bucket_index < paint_colors.size():
		maalisisus.self_modulate = paint_colors[bucket_index]
	
	# Setup helicopters if in helicopter mode
	if pelaajien_ymparisto:
		for child in pelaajien_ymparisto.get_children():
			if child is not Helikopterimme:
				continue
			kopterit.push_back(child)


func _process(delta):
	var paint_colors :Array[Color]= vari_paletit[Jattilaiset.NYKY_JATTI_INDKESI] as Array[Color]
	var objektit :Array[PackedScene]= obu_paletit[Jattilaiset.NYKY_JATTI_INDKESI] as Array[PackedScene]
	if Jattilaiset.end_countdown > 1:
		var l := 1 - pow(0.001, delta)
		modulate.a = lerpf(modulate.a, 0, l)
		return

	if Jattilaiset.LOPUN_ALKU:
		return

	# Get the color for THIS bucket (by index)
	var paint_color := Color.WHITE
	if bucket_index < paint_colors.size():
		paint_color = paint_colors[bucket_index]
	maalisisus.self_modulate = paint_color
	
	# Get the object for THIS bucket (if any)
	var objekti :PackedScene= null
	if bucket_index < objektit.size():
		objekti = objektit[bucket_index]

	# Handle on-rails mode: check if ship is over this bucket
	if on_rails_controller and on_rails_controller.has_method("get_ship_world_position"):
		var ship_node = on_rails_controller.ship_node
		if ship_node:
			var cam = get_viewport().get_camera_3d()
			if cam:
				var screen_pos := cam.unproject_position(ship_node.global_position)
				if get_rect().has_point(screen_pos):
					# Ship is over this color bucket - update the player's color
					if on_rails_controller.has_method("set_player_color"):
						on_rails_controller.set_player_color(paint_color)

	# Handle helicopter mode
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
