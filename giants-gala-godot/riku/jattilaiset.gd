class_name Jattilaiset
extends Node3D

static var singleton : Jattilaiset
const YKSI_JATTILAINEN = preload("res://riku/yksi_jattilainen.tscn")
const ALKUMATKA := 30.0
const LOPPUMATKA := 5.0
const INTERVALLI := 80.0
const ALKU_INTERVALLI := INTERVALLI * 0.7
static var INTRO :bool= false
static var LOPUN_ALKU :bool= false
static var LOPPU :bool= false
static var NYKY_JATTI_INDKESI :int= 0
static var YHEN_PROGRESSI :float= 0.0

var jattilaiset :Array[Node3D]= []

func _ready():
	INTRO = true
	LOPUN_ALKU = false
	LOPPU = false
	singleton = self
	for i in range(5):
		var jatti :Node3D= YKSI_JATTILAINEN.instantiate()
		self.add_child(jatti)
		jatti.position.x = ALKUMATKA + ALKU_INTERVALLI + i * INTERVALLI
		jattilaiset.push_back(jatti)
		#jatti.visible = false
	current_jatti = jattilaiset.front()

static func get_closest_cammera_target_pos(src: Vector3):
	if LOPPU:
		return current_jatti.global_position + Vector3.UP * -10
	return current_jatti.global_position

static var countdown : float = 1.0
static func get_closest_cammera_target(src: Vector3):
	var lahin_jatti :Node3D = null
	var closest := Vector3.FORWARD * 10000.0
	var min_dist := 10000.0
	for jatti: Node3D in singleton.jattilaiset:
		var target : Node3D = jatti.find_child("CameraTarget", true)
		if !target:
			continue
		var pos :Vector3= jatti.global_position
		var dist := (src - pos).length()
		if min_dist > dist:
			#print(jatti, ", ", src, ", ", jatti.position, ", min_dist=", min_dist, ", dist=", dist, ", ", pos)
			min_dist = dist
			closest = pos
			lahin_jatti = jatti
		if !LOPPU:
			if pos.x + INTERVALLI * 1.1 < src.x:
				jatti.visible = false
			elif pos.x - INTERVALLI * 1.1 > src.x:
				jatti.visible = false

	if INTRO:
		countdown = (closest.x - src.x - ALKU_INTERVALLI) / ALKUMATKA
		if countdown <= 0.0:
			INTRO = false
			countdown = 0.0

	if closest.x + INTERVALLI < src.x:
		LOPUN_ALKU = true

	if closest.x + INTERVALLI + LOPPUMATKA < src.x:
		LOPPU = true

	if lahin_jatti == null:
		assert("Lähin jätti puuttuu")
		
	NYKY_JATTI_INDKESI = singleton.jattilaiset.find(lahin_jatti)
	var alku := closest.x - INTERVALLI * -0.5
	var pituus := INTERVALLI
	#print(alku, "/", src.x)
	YHEN_PROGRESSI = clampf(1 - alku / pituus, 0, 1)

	lahin_jatti.visible = true
	if LOPPU and singleton:
		lahin_jatti = singleton.jattilaiset[singleton.jattilaiset.size() / 2]
	return lahin_jatti

static var current_jatti :Node3D= null
static var end_countdown := 0.0
func _process(delta):
	current_jatti = get_closest_cammera_target(Vector3.ZERO)
	if !LOPPU:
		return
	end_countdown += delta
	const interval := 13.0
	const front := 17.0
	const down := -20.0
	var i :int= 0
	var target :Vector3
	target.x = jattilaiset.size() * -0.5 * interval
	target.z = -50
	target.y = 20
	var l := 1 - pow(0.2, delta)
	for jatti :Node3D in jattilaiset:
		jatti.position.x = lerpf(jatti.position.x, target.x + i * interval, l)
		jatti.position.z = lerpf(jatti.position.z, target.z + (i%2) * front, l)
		jatti.position.y = lerpf(jatti.position.y, target.y + (i%2) * down, l)
		jatti.visible = true
		i += 1
