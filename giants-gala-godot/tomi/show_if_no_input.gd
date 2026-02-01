extends Label3D


var fade_in_start_time: float = 0
var fade_out_start_time: float = 0

var fade_out_duration: float = 0.5
var fade_in_delay_time: float = 3
var fade_in_duration: float = 1

var fading_out = false
var fading_in = true

var start_a: float = 0

func _process(delta):
	if Input.is_anything_pressed():
		if not fading_out:
			fade_out_start_time = Time.get_ticks_msec()
			fading_out = true
			fading_in = false
			start_a = modulate.a
	else:
		if not fading_in:
			fade_in_start_time = Time.get_ticks_msec()
			fading_in = true
			fading_out = false
			start_a = modulate.a
	
	if fading_out:
		var time_elapsed = Time.get_ticks_msec() - fade_out_start_time
		var t = 1.0 - time_elapsed / (fade_out_duration * 1000)
		t = clamp(t, 0.0, 1.0)
		var a = lerp(0.0, start_a, t)
		modulate = Color(1,1,1, a)
		outline_modulate = Color(0,0,0, a)
	if fading_in:
		var time_elapsed = Time.get_ticks_msec() - fade_in_start_time
		var time_2 = time_elapsed - fade_in_delay_time * 1000
		var t = time_2 / (fade_in_duration * 1000)
		t = clamp(t, 0.0, 1.0)
		var a = lerp(start_a, 1.0, t)
		modulate = Color(1,1,1, a)
		outline_modulate = Color(0,0,0, a)
	
