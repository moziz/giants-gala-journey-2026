class_name AmpuPayload extends Object

enum PayloadType {
	DECAL,
	PAINT,
	MESH
}

var payload_type: PayloadType
var mesh: Mesh = null
var paint: Color = Color.BLACK
var image: Texture2D = null
var size: float = 2
