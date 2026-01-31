extends Label

var startText :String= ""
var origText :String= ""

func _ready():
	var split := self.text.split("\n")
	startText = split[0]
	origText = split[1]

func _process(delta):
	if Jattilaiset.end_countdown > 5.0:
		label_settings.font_color.a *= 0.99
		label_settings.font_color.a += 0.01
		text = "Wow! You did this!\n\n\n\n\n\n\n"
		label_settings.font_size = 48
	elif Jattilaiset.INTRO:
		intro(delta)
	elif Jattilaiset.LOPPU:
		label_settings.font_color.a *= 0.9
	elif Jattilaiset.LOPUN_ALKU:
		visible = true
		outro(delta)
	else:
		visible = false

func intro(_delta: float):
	const END_PORTION := 0.7
	var prog := (1 - Jattilaiset.countdown) * (1.0 + END_PORTION)
	if prog < 1.0:
		var i := int(origText.length() * prog)
		text = startText + "\n" + origText.substr(0, i)
	else:
		if text != "MASK!":
			label_settings.font_size = 8
		text = "MASK!"
		var end := (prog - 1.0) / END_PORTION
		label_settings.font_size = 8 + 512 * end
		label_settings.font_color.a = 1 - end

func outro(delta: float):
	label_settings.font_size = label_settings.font_size * 0.8 + 32 * 0.2
	label_settings.font_color.a = label_settings.font_color.a * 0.8 + 1.0 * 0.2
	text = "DONE!"
