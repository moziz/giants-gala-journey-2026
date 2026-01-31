class_name AmpuOngoing extends Node

var time_start: float
var payload: AmpuPayload
var target_node: Node3D
var target_pos_local: Vector3
var target_normal_local: Vector3
var original_pos_local: Vector3
var visu: Node3D
var finished: bool = false

func _init(
	host: Node3D,
	_original_pos_local: Vector3,
	_payload: AmpuPayload,
	_target_node: Node3D,
	_target_pos_local: Vector3,
	_target_normal_local: Vector3
):
	original_pos_local = _original_pos_local
	payload = _payload
	target_node = _target_node
	target_pos_local = _target_pos_local
	target_normal_local = _target_normal_local
	
	visu = MeshInstance3D.new()
	if payload.payload_type == AmpuPayload.PayloadType.DECAL || payload.payload_type == AmpuPayload.PayloadType.PAINT:
		visu.mesh = SphereMesh.new()
	elif payload.payload_type == AmpuPayload.PayloadType.MESH:
		visu.mesh = payload.mesh
	else:
		push_error("payload type not implemtenedcdlfkrjlkjsdfljkljklkjljkljk")
	visu.position = original_pos_local
	host.add_child(visu);
	
	time_start = Time.get_ticks_msec() / 1000.

func tick() -> void:
	var time_now = Time.get_ticks_msec() / 1000.
	var time_target = time_start + 2
	var t = max(0, min((time_now - time_start) / (time_target - time_start), 1))
	
	var pos_now: Vector3 = lerp(original_pos_local, target_pos_local, t);
	
	visu.position = pos_now
	
	if t >= 1.:
		visu.queue_free()
		finished = true
