extends Decoree
class_name PaintableDecoree

## Extended Decoree with UV texture painting capability
## Falls back to decals if UV painting not available

@export var paint_resolution: Vector2i = Vector2i(512, 512)
@export var use_uv_painting: bool = true  ## Set false to force decal-only mode

# UV paint buffer - one per mesh
var _mesh_data: Array = []  # Array of { mesh_instance, paint_image, paint_texture, paint_material, tri_v0, tri_v1, tri_v2, tri_uv0, tri_uv1, tri_uv2 }

var _uv_ready: bool = false

# Brush image (circular soft brush)
var _brush_image: Image


func _ready():
	super._ready()
	
	# Create default brush
	_brush_image = _create_circular_brush(32)
	
	if use_uv_painting:
		_try_setup_uv_painting()


func _try_setup_uv_painting() -> bool:
	## Attempt to set up UV painting on ALL child meshes
	var meshes: Array[MeshInstance3D] = []
	_collect_all_meshes(self, meshes)
	
	if meshes.is_empty():
		print("PaintableDecoree: No MeshInstance3D found, using decals only")
		return false
	
	var total_triangles := 0
	
	for mi in meshes:
		if mi.mesh == null:
			continue
			
		var data = _setup_mesh_data(mi)
		if data != null:
			_mesh_data.append(data)
			total_triangles += data.tri_v0.size()
	
	if _mesh_data.is_empty():
		print("PaintableDecoree: No valid meshes found, using decals only")
		return false
	
	_uv_ready = true
	print("PaintableDecoree UV ready: %d meshes, %d total triangles, %dx%d texture each" % [_mesh_data.size(), total_triangles, paint_resolution.x, paint_resolution.y])
	return true


func _collect_all_meshes(node: Node, meshes: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		meshes.append(node as MeshInstance3D)
	for child in node.get_children():
		_collect_all_meshes(child, meshes)


func _setup_mesh_data(mi: MeshInstance3D) -> Dictionary:
	## Create triangle data and paint buffer for one mesh
	var mesh: Mesh = mi.mesh
	
	# Calculate transform from MeshInstance3D to this node (PaintableDecoree)
	var mesh_transform: Transform3D = Transform3D.IDENTITY
	var current: Node3D = mi
	while current != self and current != null:
		mesh_transform = current.transform * mesh_transform
		current = current.get_parent() as Node3D
	
	var tri_v0: Array[Vector3] = []
	var tri_v1: Array[Vector3] = []
	var tri_v2: Array[Vector3] = []
	var tri_uv0: Array[Vector2] = []
	var tri_uv1: Array[Vector2] = []
	var tri_uv2: Array[Vector2] = []
	
	for surface_i in range(mesh.get_surface_count()):
		var arrays: Array = mesh.surface_get_arrays(surface_i)
		
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV] if arrays[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		
		if uvs.is_empty():
			uvs = _generate_spherical_uvs(verts)
		
		if indices.is_empty():
			var tri_count = int(verts.size() / 3)
			for t in range(tri_count):
				var i0 = 3 * t + 0
				var i1 = 3 * t + 1
				var i2 = 3 * t + 2
				_add_triangle_to_arrays(verts, uvs, i0, i1, i2, mesh_transform, tri_v0, tri_v1, tri_v2, tri_uv0, tri_uv1, tri_uv2)
		else:
			var tri_count = int(indices.size() / 3)
			for t in range(tri_count):
				var i0 = indices[3 * t + 0]
				var i1 = indices[3 * t + 1]
				var i2 = indices[3 * t + 2]
				_add_triangle_to_arrays(verts, uvs, i0, i1, i2, mesh_transform, tri_v0, tri_v1, tri_v2, tri_uv0, tri_uv1, tri_uv2)
	
	if tri_v0.is_empty():
		return {}
	
	# Create paint buffer
	var paint_image = Image.create(paint_resolution.x, paint_resolution.y, false, Image.FORMAT_RGBA8)
	paint_image.fill(Color(0, 0, 0, 0))
	var paint_texture = ImageTexture.create_from_image(paint_image)
	
	# Create material
	var paint_material = _create_paint_material(mi, paint_texture)
	mi.set_surface_override_material(0, paint_material)
	
	return {
		"mesh_instance": mi,
		"paint_image": paint_image,
		"paint_texture": paint_texture,
		"paint_material": paint_material,
		"tri_v0": tri_v0,
		"tri_v1": tri_v1,
		"tri_v2": tri_v2,
		"tri_uv0": tri_uv0,
		"tri_uv1": tri_uv1,
		"tri_uv2": tri_uv2,
	}


func _add_triangle_to_arrays(
	verts: PackedVector3Array,
	uvs: PackedVector2Array,
	i0: int, i1: int, i2: int,
	mesh_transform: Transform3D,
	tri_v0: Array[Vector3], tri_v1: Array[Vector3], tri_v2: Array[Vector3],
	tri_uv0: Array[Vector2], tri_uv1: Array[Vector2], tri_uv2: Array[Vector2]
) -> void:
	var a: Vector3 = mesh_transform * verts[i0]
	var b: Vector3 = mesh_transform * verts[i1]
	var c: Vector3 = mesh_transform * verts[i2]
	
	tri_v0.append(a)
	tri_v1.append(b)
	tri_v2.append(c)
	
	var uv_a = uvs[i0] if i0 < uvs.size() else Vector2.ZERO
	var uv_b = uvs[i1] if i1 < uvs.size() else Vector2.ZERO
	var uv_c = uvs[i2] if i2 < uvs.size() else Vector2.ZERO
	
	tri_uv0.append(uv_a)
	tri_uv1.append(uv_b)
	tri_uv2.append(uv_c)


func _generate_spherical_uvs(verts: PackedVector3Array) -> PackedVector2Array:
	var uvs := PackedVector2Array()
	
	# Find center
	var center := Vector3.ZERO
	for v in verts:
		center += v
	center /= verts.size()
	
	for v in verts:
		var dir = (v - center).normalized()
		var u = atan2(dir.x, dir.z) / (2.0 * PI) + 0.5
		var v_coord = asin(clamp(dir.y, -1.0, 1.0)) / PI + 0.5
		uvs.append(Vector2(u, v_coord))
	
	return uvs


func _create_paint_material(mi: MeshInstance3D, paint_tex: ImageTexture) -> ShaderMaterial:
	var paint_shader = Shader.new()
	paint_shader.code = """
shader_type spatial;

uniform sampler2D base_albedo : source_color, hint_default_white;
uniform sampler2D paint_tex : source_color;
uniform vec4 base_color : source_color = vec4(0.85, 0.85, 0.85, 1.0);

void fragment() {
	vec4 base = texture(base_albedo, UV) * base_color;
	vec4 paint = texture(paint_tex, UV);
	
	// Alpha blend paint over base
	vec3 out_rgb = mix(base.rgb, paint.rgb, paint.a);
	
	ALBEDO = out_rgb;
	ROUGHNESS = 0.8;
	METALLIC = 0.0;
}
"""
	
	var paint_material = ShaderMaterial.new()
	paint_material.shader = paint_shader
	paint_material.set_shader_parameter("paint_tex", paint_tex)
	
	# Get base color from existing material
	var existing_mat = mi.get_active_material(0)
	if existing_mat is StandardMaterial3D:
		var std_mat = existing_mat as StandardMaterial3D
		paint_material.set_shader_parameter("base_color", std_mat.albedo_color)
		if std_mat.albedo_texture:
			paint_material.set_shader_parameter("base_albedo", std_mat.albedo_texture)
	
	return paint_material


func _create_circular_brush(size: int) -> Image:
	## Create a soft circular brush
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(size / 2.0, size / 2.0)
	var radius = size / 2.0
	
	for y in range(size):
		for x in range(size):
			var dist = Vector2(x, y).distance_to(center)
			if dist > radius:
				img.set_pixel(x, y, Color(1, 1, 1, 0))
			else:
				# Soft edge falloff
				var alpha = 1.0 - smoothstep(radius * 0.5, radius, dist)
				img.set_pixel(x, y, Color(1, 1, 1, alpha))
	
	return img


# --- Override maalaa to use UV painting when available ---

func maalaa(hit_pos: Vector3, hit_normal: Vector3, color: Color, size: float = 2.0):
	## Paint using UV texture if available, otherwise use decal
	## hit_pos is in WORLD coordinates from raycast
	
	if _uv_ready and use_uv_painting:
		# Convert world position to local position relative to this node (PaintableDecoree)
		var local_pos = global_transform.affine_inverse() * hit_pos
		
		# Find best mesh and face
		var best_mesh_data = null
		var best_face := -1
		var best_dist := INF
		
		for data in _mesh_data:
			var tri_v0: Array = data.tri_v0
			var tri_v1: Array = data.tri_v1
			var tri_v2: Array = data.tri_v2
			
			for i in range(tri_v0.size()):
				var a: Vector3 = tri_v0[i]
				var b: Vector3 = tri_v1[i]
				var c: Vector3 = tri_v2[i]
				var center := (a + b + c) / 3.0
				var dist := local_pos.distance_to(center)
				if dist < best_dist:
					best_dist = dist
					best_face = i
					best_mesh_data = data
		
		if best_mesh_data != null and best_face >= 0:
			var radius_px = int(size * 20)  # Scale size to pixels
			_paint_at_hit(best_mesh_data, local_pos, best_face, color, radius_px)
			return
	
	# Fallback to decal
	super.maalaa(hit_pos, hit_normal, color, size)


func _paint_at_hit(mesh_data: Dictionary, local_pos: Vector3, face_index: int, color: Color, radius_px: int) -> void:
	var tri_v0: Array = mesh_data.tri_v0
	var tri_v1: Array = mesh_data.tri_v1
	var tri_v2: Array = mesh_data.tri_v2
	var tri_uv0: Array = mesh_data.tri_uv0
	var tri_uv1: Array = mesh_data.tri_uv1
	var tri_uv2: Array = mesh_data.tri_uv2
	var paint_image: Image = mesh_data.paint_image
	var paint_texture: ImageTexture = mesh_data.paint_texture
	
	if face_index < 0 or face_index >= tri_v0.size():
		return
	
	# Get UV at hit point
	var a: Vector3 = tri_v0[face_index]
	var b: Vector3 = tri_v1[face_index]
	var c: Vector3 = tri_v2[face_index]
	
	var w: Vector3 = Geometry3D.get_triangle_barycentric_coords(local_pos, a, b, c)
	
	var uva: Vector2 = tri_uv0[face_index]
	var uvb: Vector2 = tri_uv1[face_index]
	var uvc: Vector2 = tri_uv2[face_index]
	
	var uv: Vector2 = uva * w.x + uvb * w.y + uvc * w.z
	
	# Stamp brush at UV position
	_stamp_brush_at_uv(paint_image, uv, color, radius_px)
	
	# Upload to GPU
	paint_texture.update(paint_image)


func _stamp_brush_at_uv(paint_image: Image, uv: Vector2, color: Color, radius_px: int) -> void:
	uv = Vector2(fposmod(uv.x, 1.0), fposmod(uv.y, 1.0))
	
	var w := paint_image.get_width()
	var h := paint_image.get_height()
	
	var px := int(uv.x * w)
	var py := int(uv.y * h)
	
	_stamp_brush_pixels(paint_image, Vector2i(px, py), color, radius_px)


func _stamp_brush_pixels(paint_image: Image, center: Vector2i, color: Color, radius_px: int) -> void:
	var tw := paint_image.get_width()
	var th := paint_image.get_height()
	var bw := _brush_image.get_width()
	var bh := _brush_image.get_height()
	
	var min_x := center.x - radius_px
	var max_x := center.x + radius_px
	var min_y := center.y - radius_px
	var max_y := center.y + radius_px
	
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			# Wrap coordinates for UV seam handling
			var wx = posmod(x, tw)
			var wy = posmod(y, th)
			
			var dx := float(x - center.x)
			var dy := float(y - center.y)
			var dist := sqrt(dx * dx + dy * dy)
			
			if dist > radius_px:
				continue
			
			# Map to brush coordinates
			var u := (dx / float(radius_px)) * 0.5 + 0.5
			var v := (dy / float(radius_px)) * 0.5 + 0.5
			
			var bx := clampi(int(u * bw), 0, bw - 1)
			var by := clampi(int(v * bh), 0, bh - 1)
			
			var mask := _brush_image.get_pixel(bx, by).a
			if mask <= 0.001:
				continue
			
			# Alpha-over blend
			var src := Color(color.r, color.g, color.b, color.a * mask)
			var dst := paint_image.get_pixel(wx, wy)
			
			var out_a := src.a + dst.a * (1.0 - src.a)
			if out_a <= 0.0001:
				paint_image.set_pixel(wx, wy, Color(0, 0, 0, 0))
				continue
			
			var out_r := (src.r * src.a + dst.r * dst.a * (1.0 - src.a)) / out_a
			var out_g := (src.g * src.a + dst.g * dst.a * (1.0 - src.a)) / out_a
			var out_b := (src.b * src.a + dst.b * dst.a * (1.0 - src.a)) / out_a
			
			paint_image.set_pixel(wx, wy, Color(out_r, out_g, out_b, out_a))


func clear_paint() -> void:
	## Clear all UV paint on all meshes
	for data in _mesh_data:
		var paint_image: Image = data.paint_image
		var paint_texture: ImageTexture = data.paint_texture
		paint_image.fill(Color(0, 0, 0, 0))
		paint_texture.update(paint_image)
