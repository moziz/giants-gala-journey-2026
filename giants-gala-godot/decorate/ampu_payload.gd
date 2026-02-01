class_name AmpuPayload extends Object

enum PayloadType {
	DECAL,
	MESH
}

var payload_type: PayloadType
var mesh: Node3D = null
var paint: Color = Color.BLACK
var image: Texture2D = null
var size: float = 2
