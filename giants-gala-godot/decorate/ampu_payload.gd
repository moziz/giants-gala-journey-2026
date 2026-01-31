class_name AmpuPayload extends Object

enum PayloadType {
	PAINT,
	MESH
}

var payload_type: PayloadType
var mesh: MeshInstance3D = null
var paint: Color = Color.BLACK
var image: Texture2D = null
