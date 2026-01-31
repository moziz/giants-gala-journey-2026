extends Node3D

@onready var orig_pos := position
@onready var orig_rot := rotation
@onready var target_pos := position
@onready var target_rot := rotation
@onready var breathe := randf() * TAU
@onready var breathe_speed := randf_range(0.9, 1.0)
var interval := 0.0

func _process(delta):
	interval += delta
	if interval > 0.5:
		interval = 0.0 - randf() * 0.5
		if randf() > 0.5:
			target_rot = orig_rot + Vector3.UP * (randf() - 0.5) * 0.3 + Vector3.RIGHT * (randf() - 0.5) * 0.02 + Vector3.FORWARD * (randf() - 0.5) * 0.02
			if randf() > 0.5:
				target_pos = orig_pos + Vector3.UP * randf() * 1
			if randf() > 0.5:
				target_pos = orig_pos + Vector3.RIGHT * (randf() * 1 - 0.5)
			if randf() > 0.5:
				target_pos = orig_pos + Vector3.FORWARD * (randf() * 1 - 0.5)

	var target_pos2 := target_pos
	if Jattilaiset.LOPUN_ALKU and Jattilaiset.end_countdown < 4.0:
		target_pos2.y += pow(sin(breathe + Time.get_ticks_msec() * 0.02 * breathe_speed), 2) * 4
	position = position.lerp(target_pos2 + sin(breathe + Time.get_ticks_msec() * 0.002 * breathe_speed) * Vector3.UP, 0.1)
	rotation = rotation.lerp(target_rot, 0.1)
