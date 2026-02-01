extends Node3D
## On-Rails Shooter Controller for Giants Gala Journey
##
## SINGLE PLAYER - DECOUPLED AIM MODE
## ===================================
## Left analog stick: Moves the "color picker" ship around control plane
## Right analog stick: Controls WHERE you're shooting (targeting reticle)
## 
## The ship and the aim are independent - pick colors with ship, aim anywhere!
##
## CAMERA-LOCAL COORDINATE SYSTEM
## ==============================
## Everything is defined relative to the camera:
##
## CAMERA-LOCAL AXES:
##   X = right (positive) / left (negative)
##   Y = up (positive) / down (negative)
##   Z = backward (positive) / forward (negative)  <- NEGATIVE Z IS FORWARD!

const PELAAJA_PYRAMIDI = preload("res://riku/pelaaja_pyramidi.tscn")

# Decal textures for painting
var decal_textures: Array[Texture2D] = [
	preload("res://assets/decal_0.png"),
	preload("res://assets/decal_1.png"),
	preload("res://assets/decal_2.png"),
]

# === SETTINGS ===
const SHIP_SPEED = 8.0  # Units per second - ship movement
const AIM_SPEED = 10.0  # Units per second - targeting speed
const SPRAY_RATE = 0.08   # Seconds between shots
const PROJECTILE_FLIGHT_TIME = 0.15  # Seconds for projectile to reach target (fast!)

# === CAMERA-LOCAL PLANE DISTANCES (negative = forward) ===
@export var control_plane_z: float = -5.0   # Control plane 5 units in front
@export var target_plane_z: float = -50.0   # Target plane 50 units in front

# === PLANE SIZES ===
## Control plane: Where the ship/color picker moves (can be any aspect ratio)
@export var control_plane_size: Vector2 = Vector2(12.0, 8.0)
## Left margin: How much to push ship right to avoid overlapping left HUD (no longer needed with SubViewport overlay)
@export var ship_left_margin: float = 0.0  # Ship can now go full left since it renders on top of HUD
## Target plane: Where you aim (larger 1:1 area for easier targeting)
@export var target_plane_size: Vector2 = Vector2(50.0, 50.0)  # Large to cover head + body
## Finale target plane: Expanded size during the close-up finale with all giants
@export var finale_target_plane_size: Vector2 = Vector2(80.0, 80.0)

# === Current target plane size (interpolated during finale) ===
var current_target_plane_size: Vector2 = Vector2(50.0, 50.0)

# === PLAYER COLOR (changes when flying over paint buckets) ===
@export var player_color: Color = Color(1.0, 0.3, 0.5, 1.0)  # Pink

# === NODE REFERENCES ===
@onready var camera: Camera3D = $Camera3D

# === RUNTIME STATE ===
var player_move_bounds: Vector2  # Half of control plane
var control_plane_wireframe: MeshInstance3D
var target_plane_wireframe: MeshInstance3D

# Ship overlay rendering (SubViewport for rendering ship on top of 2D HUD)
var ship_subviewport: SubViewport
var ship_camera: Camera3D  # Camera in SubViewport that mirrors main camera
var ship_canvas_layer: CanvasLayer

# Ship state (color picker - moved with left stick)
var ship_node: Node3D
var ship_offset: Vector2 = Vector2.ZERO

# Aim state (targeting - moved with right stick)
var aim_offset: Vector2 = Vector2.ZERO
var aim_crosshair: MeshInstance3D
var target_crosshair: MeshInstance3D
var reticle_indicator: MeshInstance3D
var trajectory_line: MeshInstance3D  # Shows aim direction when not hitting target

# Debug display toggle (wireframes and crosshairs hidden by default)
var debug_visuals_visible: bool = false

# Slow motion toggle (SPACE key) - only affects on-rails scrolling, not player controls
var slow_motion_active: bool = false
const SLOW_MOTION_SCALE: float = 0.25  # 25% speed (quarter speed)
static var time_scale: float = 1.0  # Static so liukuhihna.gd can read it
var slow_mo_label: Label  # On-screen indicator for slow motion

var spray_timer: float = 0.0

# Compatibility array for tyokalu.gd - single player ship appears as "player 0"
var players: Array = []


func _ready():
	player_move_bounds = control_plane_size / 2.0
	current_target_plane_size = target_plane_size  # Initialize to default size
	
	_create_wireframe_outlines()
	_setup_player()
	_create_slow_mo_label()
	
	# Hide debug visuals by default (wireframes, crosshairs)
	_set_debug_visuals_visibility(debug_visuals_visible)
	
	# Setup players array for tyokalu.gd compatibility (color picking)
	players = [{
		"active": true,
		"node": ship_node,
		"offset": ship_offset,
		"color": player_color,
	}]
	
	print("")
	print("=== ON-RAILS SHOOTER: DECOUPLED AIM MODE ===")
	print("Control plane: Z=", control_plane_z, " size=", control_plane_size)
	print("Target plane: Z=", target_plane_z, " size=", target_plane_size)
	print("")
	print("Controls (KEYBOARD):")
	print("  Ship (color picker): WASD")
	print("  Aim (targeting): IJKL")
	print("  Fire: Q or E")
	print("  SLOW MOTION: SPACE (toggle 25% speed)")
	print("  Debug visuals: TAB")
	print("")
	print("Controls (GAMEPAD):")
	print("  Ship (color picker): Left stick")
	print("  Aim (targeting): Right stick")
	print("  Fire: LB/RB or RT/LT")
	print("")


func _setup_player():
	## Create the single player ship and aiming system
	## Ship is rendered in a SubViewport overlay to appear on top of 2D HUD elements
	
	# Create the overlay system for ship (renders on top of HUD)
	_create_ship_overlay()
	
	# Create ship (color picker) - add to SubViewport's camera, not main camera
	ship_node = PELAAJA_PYRAMIDI.instantiate()
	ship_node.name = "Ship"
	ship_camera.add_child(ship_node)
	
	# Set ship to render layer 2 so ONLY ship_camera sees it
	_set_visual_layer_recursive(ship_node, 2)
	
	# Set ship color
	var body: MeshInstance3D = ship_node.get_node("Body")
	if body and body.get_surface_override_material(0):
		var mat = body.get_surface_override_material(0).duplicate()
		mat.albedo_color = player_color
		mat.emission = player_color
		body.set_surface_override_material(0, mat)
	
	# Aim crosshair on control plane - HIDDEN (confusing with target crosshair)
	# Keep the variable but don't create/show it
	aim_crosshair = null
	
	# Create target crosshair (shows aim on target plane) - this is the one that matters
	target_crosshair = _create_crosshair(Color(1.0, 0.5, 0.0, 0.8), 0.4)  # Orange
	target_crosshair.position.z = target_plane_z
	camera.add_child(target_crosshair)
	
	# Create reticle indicator (shown on surface where actually aiming)
	reticle_indicator = _create_reticle_indicator(Color(1.0, 1.0, 0.0))  # Yellow
	add_child(reticle_indicator)  # World space
	
	# Create trajectory line (shown when NOT hitting a target)
	trajectory_line = _create_trajectory_line(player_color)  # Match player's current color
	add_child(trajectory_line)  # World space


func _set_visual_layer_recursive(node: Node, layer: int):
	## Set visual layers on all VisualInstance3D nodes recursively
	## Used to isolate ship rendering to its own camera
	if node is VisualInstance3D:
		node.layers = layer
	for child in node.get_children():
		_set_visual_layer_recursive(child, layer)


func _create_ship_overlay():
	## Create SubViewport overlay for rendering ship on top of 2D HUD
	## This allows the 3D ship to appear above 2D Control elements
	## Uses cull masks so ship camera ONLY renders the ship, nothing else
	
	# Create CanvasLayer with layer > 0 (renders above default HUD at layer 0)
	ship_canvas_layer = CanvasLayer.new()
	ship_canvas_layer.name = "ShipOverlay"
	ship_canvas_layer.layer = 10  # High layer to be on top of everything
	get_tree().root.call_deferred("add_child", ship_canvas_layer)
	
	# Create SubViewportContainer to display the SubViewport
	var container = SubViewportContainer.new()
	container.name = "ShipViewportContainer"
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.stretch = true
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Don't block input
	ship_canvas_layer.add_child(container)
	
	# Create SubViewport with transparent background
	ship_subviewport = SubViewport.new()
	ship_subviewport.name = "ShipSubViewport"
	ship_subviewport.transparent_bg = true
	ship_subviewport.size = get_viewport().size
	ship_subviewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	container.add_child(ship_subviewport)
	
	# Create camera in SubViewport that will mirror main camera's transform
	# Use cull mask layer 2 (bit 1) to ONLY see the ship
	ship_camera = Camera3D.new()
	ship_camera.name = "ShipCamera"
	ship_camera.fov = camera.fov
	ship_camera.current = true  # Make it the current camera for this viewport
	ship_camera.cull_mask = 2  # Only render layer 2 (bit 1 = 2)
	ship_subviewport.add_child(ship_camera)
	
	# Connect to viewport size changes
	get_viewport().size_changed.connect(_on_viewport_size_changed)


func _on_viewport_size_changed():
	if ship_subviewport:
		ship_subviewport.size = get_viewport().size


func _create_wireframe_outlines():
	## Create wireframe outlines for control and target planes
	
	# Yellow wireframe for control plane
	control_plane_wireframe = _create_rectangle_wireframe(
		control_plane_size, 
		Color(1.0, 0.85, 0.0, 1.0)  # Yellow
	)
	control_plane_wireframe.position.z = control_plane_z
	camera.add_child(control_plane_wireframe)
	
	# Green wireframe for target plane
	target_plane_wireframe = _create_rectangle_wireframe(
		target_plane_size, 
		Color(0.2, 1.0, 0.3, 1.0)  # Green
	)
	target_plane_wireframe.position.z = target_plane_z
	camera.add_child(target_plane_wireframe)


func _create_rectangle_wireframe(size: Vector2, color: Color) -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	var mesh = ImmediateMesh.new()
	
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.no_depth_test = true  # Show through everything
	mat.render_priority = 100
	
	var hw = size.x / 2.0
	var hh = size.y / 2.0
	
	var tl = Vector3(-hw,  hh, 0)
	var tr = Vector3( hw,  hh, 0)
	var br = Vector3( hw, -hh, 0)
	var bl = Vector3(-hw, -hh, 0)
	
	mesh.surface_begin(Mesh.PRIMITIVE_LINES, mat)
	mesh.surface_add_vertex(tl); mesh.surface_add_vertex(tr)
	mesh.surface_add_vertex(tr); mesh.surface_add_vertex(br)
	mesh.surface_add_vertex(br); mesh.surface_add_vertex(bl)
	mesh.surface_add_vertex(bl); mesh.surface_add_vertex(tl)
	mesh.surface_end()
	
	mesh_instance.mesh = mesh
	return mesh_instance


func _create_crosshair(color: Color, size: float) -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	var mesh = ImmediateMesh.new()
	
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.no_depth_test = true  # Show through everything
	mat.render_priority = 100
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if color.a < 1.0 else BaseMaterial3D.TRANSPARENCY_DISABLED
	
	var half = size / 2.0
	var center_size = size * 0.2
	
	mesh.surface_begin(Mesh.PRIMITIVE_LINES, mat)
	# Cross
	mesh.surface_add_vertex(Vector3(-half, 0, 0)); mesh.surface_add_vertex(Vector3(half, 0, 0))
	mesh.surface_add_vertex(Vector3(0, -half, 0)); mesh.surface_add_vertex(Vector3(0, half, 0))
	# Center diamond
	mesh.surface_add_vertex(Vector3(-center_size, 0, 0)); mesh.surface_add_vertex(Vector3(0, center_size, 0))
	mesh.surface_add_vertex(Vector3(0, center_size, 0)); mesh.surface_add_vertex(Vector3(center_size, 0, 0))
	mesh.surface_add_vertex(Vector3(center_size, 0, 0)); mesh.surface_add_vertex(Vector3(0, -center_size, 0))
	mesh.surface_add_vertex(Vector3(0, -center_size, 0)); mesh.surface_add_vertex(Vector3(-center_size, 0, 0))
	mesh.surface_end()
	
	mesh_instance.mesh = mesh
	return mesh_instance


func _create_slow_mo_label():
	## Create on-screen label for slow motion indicator
	## Added to a new CanvasLayer to be on top of everything
	var slow_mo_canvas = CanvasLayer.new()
	slow_mo_canvas.name = "SlowMoOverlay"
	slow_mo_canvas.layer = 20  # Very high layer to be on top
	get_tree().root.call_deferred("add_child", slow_mo_canvas)
	
	slow_mo_label = Label.new()
	slow_mo_label.name = "SlowMoLabel"
	slow_mo_label.text = "SLOW MODE"
	slow_mo_label.add_theme_font_size_override("font_size", 48)
	slow_mo_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.9))  # White
	slow_mo_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	slow_mo_label.add_theme_constant_override("outline_size", 4)
	slow_mo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slow_mo_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# Full width anchors, centered at top
	slow_mo_label.anchor_left = 0.0
	slow_mo_label.anchor_right = 1.0
	slow_mo_label.anchor_top = 0.0
	slow_mo_label.anchor_bottom = 0.0
	slow_mo_label.offset_top = 20  # Small margin from top
	slow_mo_label.offset_bottom = 80  # Height for the label
	slow_mo_label.visible = false  # Hidden by default
	slow_mo_canvas.add_child(slow_mo_label)


func _create_reticle_indicator(color: Color) -> MeshInstance3D:
	## Create a sphere to show where aiming on surface
	var mesh_instance = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.3
	sphere.height = 0.6
	sphere.radial_segments = 16
	sphere.rings = 8
	mesh_instance.mesh = sphere
	
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 1.0
	mat.no_depth_test = true  # Show through everything
	mat.render_priority = 100
	mesh_instance.set_surface_override_material(0, mat)
	
	return mesh_instance


func _create_trajectory_line(color: Color) -> MeshInstance3D:
	## Create a visible 3D cylinder to show aim direction when not hitting a target
	var mesh_instance = MeshInstance3D.new()
	
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 2.0
	mat.no_depth_test = true  # Show through everything
	mat.render_priority = 100
	
	# Create initial cylinder mesh - thicker and longer for visibility
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.25  # Thicker cylinder
	cylinder.bottom_radius = 0.25
	cylinder.height = 12.0  # Longer
	cylinder.material = mat
	
	mesh_instance.mesh = cylinder
	
	# Start hidden (will be shown when not hitting target)
	mesh_instance.visible = false
	
	return mesh_instance


func _update_trajectory_line_color(color: Color):
	## Update the trajectory line color to match current player color
	if not trajectory_line:
		return
	
	var cylinder = trajectory_line.mesh as CylinderMesh
	if cylinder and cylinder.material:
		var mat = cylinder.material as StandardMaterial3D
		if mat:
			mat.albedo_color = color
			mat.emission = color


func _update_trajectory_line(start_pos: Vector3, direction: Vector3, length: float = 12.0, offset: float = 20.0):
	## Update the trajectory line to show aim direction
	## Uses a cylinder mesh for better visibility
	## start_pos: World position of the aim origin
	## direction: Normalized direction of aiming
	## length: Length of the line segment
	## offset: Distance from camera where line starts
	
	if not trajectory_line:
		return
	
	# Position the center of the line segment
	var line_center = start_pos + direction * (offset + length / 2.0)
	
	# Update the cylinder mesh dimensions
	var cylinder = trajectory_line.mesh as CylinderMesh
	if cylinder:
		cylinder.height = length
	
	trajectory_line.global_position = line_center
	
	# Align cylinder to direction (cylinder's Y axis = height)
	# We need to rotate so Y points in the direction
	var up = Vector3.UP
	if abs(direction.dot(Vector3.UP)) > 0.99:
		up = Vector3.RIGHT
	trajectory_line.look_at(line_center + direction, up)
	trajectory_line.rotate_object_local(Vector3.RIGHT, deg_to_rad(90))
	
	# Always show trajectory line (it's an aiming helper, not debug visual)
	trajectory_line.visible = true


# === CAMERA LOOK-AT (from ymparisto.gd) ===
var lerp_pos: Vector3 = Vector3.FORWARD

func _process(delta: float):
	_handle_debug_toggle()
	_handle_slow_motion_toggle()
	_update_target_plane_size(delta)
	_handle_movement(delta)
	_handle_spraying(delta)
	_update_visuals()
	_update_look_at(delta)


func _handle_debug_toggle():
	## Toggle debug visuals with TAB key
	if Input.is_action_just_pressed("ui_focus_next"):  # TAB key
		debug_visuals_visible = not debug_visuals_visible
		_set_debug_visuals_visibility(debug_visuals_visible)
		print("[DEBUG] Debug visuals: ", "ON" if debug_visuals_visible else "OFF")


func _handle_slow_motion_toggle():
	## Toggle super slow motion with SPACE key (25% speed)
	## Only affects on-rails scrolling, NOT ship/aim controls
	if Input.is_action_just_pressed("ui_select"):  # SPACE key
		slow_motion_active = not slow_motion_active
		if slow_motion_active:
			time_scale = SLOW_MOTION_SCALE
			if slow_mo_label:
				slow_mo_label.visible = true
			print("[SLOW-MO] Slow motion ON (", SLOW_MOTION_SCALE * 100, "% scroll speed)")
		else:
			time_scale = 1.0
			if slow_mo_label:
				slow_mo_label.visible = false
			print("[SLOW-MO] Normal scroll speed restored")


func _set_debug_visuals_visibility(visible: bool):
	## Set visibility for debug-only visualizations (wireframes and crosshairs)
	## NOTE: reticle_indicator and trajectory_line are AIMING HELPERS, always visible
	if control_plane_wireframe:
		control_plane_wireframe.visible = visible
	if target_plane_wireframe:
		target_plane_wireframe.visible = visible
	if target_crosshair:
		target_crosshair.visible = visible


func _update_target_plane_size(delta: float):
	## During the finale (LOPPU), expand the target plane to cover all giants
	var goal_size: Vector2
	if Jattilaiset.LOPPU:
		goal_size = finale_target_plane_size
	else:
		goal_size = target_plane_size
	
	# Smooth interpolation
	var lerp_factor = 1 - pow(0.3, delta)
	current_target_plane_size = current_target_plane_size.lerp(goal_size, lerp_factor)


func _update_look_at(delta: float):
	## Make the controller (and thus camera) look at the current giant
	## Smooth camera movement to reduce jarring during projectile flight
	var target_pos: Vector3 = Jattilaiset.get_closest_cammera_target_pos(global_position)
	lerp_pos = lerp_pos.lerp(target_pos, 1 - pow(0.4, delta))  # Slower/smoother (was 0.2)
	look_at(lerp_pos)


func set_player_color(arg1, arg2 = null):
	## Called by tyokalu (paint bucket) when player flies over it
	## Supports two signatures:
	##   set_player_color(color: Color) - simple, for on-rails mode
	##   set_player_color(player_index: int, color: Color) - for compatibility
	var color: Color
	if arg2 != null:
		# Called with (index, color)
		if arg1 != 0:
			return  # In decoupled mode, only player 0 (the ship) matters
		color = arg2
	else:
		# Called with just (color)
		color = arg1
	
	player_color = color
	
	# Update players array for tyokalu.gd compatibility
	if players.size() > 0:
		players[0]["color"] = color
	
	# Update ship material
	if ship_node:
		var body: MeshInstance3D = ship_node.get_node_or_null("Body")
		if body:
			var mat = body.get_surface_override_material(0)
			if mat == null:
				mat = StandardMaterial3D.new()
			else:
				mat = mat.duplicate()
			mat.albedo_color = color
			mat.emission = color
			body.set_surface_override_material(0, mat)
	
	# Also update reticle indicator to match the current color
	if reticle_indicator:
		var mat = reticle_indicator.get_surface_override_material(0)
		if mat:
			mat = mat.duplicate()
			mat.albedo_color = color
			mat.emission = color
			reticle_indicator.set_surface_override_material(0, mat)
	
	# Update trajectory line color to match current player color
	_update_trajectory_line_color(color)


func get_ship_world_position() -> Vector3:
	## Returns the world position of the ship (for color bucket detection)
	if ship_node:
		return ship_node.global_position
	return global_position


func _handle_movement(delta: float):
	## Left stick/WASD moves ship, Right stick/IJKL moves aim
	var ship_speed = SHIP_SPEED * delta
	var aim_speed = AIM_SPEED * delta
	
	# --- Ship movement (Left stick / WASD) ---
	var ship_input: Vector2 = Vector2.ZERO
	
	# Keyboard: WASD
	if Input.is_action_pressed("p1_thrust_forward"):
		ship_input.y += 1.0
	if Input.is_action_pressed("p1_thurst_backward"):
		ship_input.y -= 1.0
	if Input.is_action_pressed("p1_thurst_left"):
		ship_input.x -= 1.0
	if Input.is_action_pressed("p1_thrust_right"):
		ship_input.x += 1.0
	
	# Gamepad: Left analog stick
	var joy_lx = Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
	var joy_ly = Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
	if abs(joy_lx) > 0.15:
		ship_input.x += joy_lx
	if abs(joy_ly) > 0.15:
		ship_input.y -= joy_ly  # Y is inverted
	
	ship_input = ship_input.limit_length(1.0)
	ship_offset += ship_input * ship_speed
	# Use asymmetric bounds: left side has margin to avoid MALLI HUD, right side is full
	var left_bound = -player_move_bounds.x + ship_left_margin
	ship_offset.x = clampf(ship_offset.x, left_bound, player_move_bounds.x)
	ship_offset.y = clampf(ship_offset.y, -player_move_bounds.y, player_move_bounds.y)
	
	# Update players array for tyokalu.gd compatibility
	if players.size() > 0:
		players[0]["offset"] = ship_offset
	
	# --- Aim movement (Right stick / IJKL) ---
	var aim_input: Vector2 = Vector2.ZERO
	
	# Keyboard: IJKL
	if Input.is_action_pressed("p2_thrust_forward"):
		aim_input.y += 1.0
	if Input.is_action_pressed("p2_thurst_backward"):
		aim_input.y -= 1.0
	if Input.is_action_pressed("p2_thurst_left"):
		aim_input.x -= 1.0
	if Input.is_action_pressed("p2_thrust_right"):
		aim_input.x += 1.0
	
	# Gamepad: Right analog stick
	var joy_rx = Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)
	var joy_ry = Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
	if abs(joy_rx) > 0.15:
		aim_input.x += joy_rx
	if abs(joy_ry) > 0.15:
		aim_input.y -= joy_ry  # Y is inverted
	
	aim_input = aim_input.limit_length(1.0)
	aim_offset += aim_input * aim_speed
	aim_offset.x = clampf(aim_offset.x, -player_move_bounds.x, player_move_bounds.x)
	aim_offset.y = clampf(aim_offset.y, -player_move_bounds.y, player_move_bounds.y)


func _handle_spraying(delta: float):
	spray_timer -= delta
	if spray_timer > 0:
		return
	
	# Check for fire input (Space, Y, or any bumper/trigger)
	var firing = false
	
	# Keyboard: Space or Y
	if Input.is_action_pressed("p1_thrust_up") or Input.is_action_pressed("p2_thrust_up"):
		firing = true
		print("[INPUT] Keyboard fire detected!")
	
	# Gamepad: LB, RB, LT, RT
	if Input.is_joy_button_pressed(0, JOY_BUTTON_LEFT_SHOULDER):
		firing = true
		print("[INPUT] LB pressed!")
	if Input.is_joy_button_pressed(0, JOY_BUTTON_RIGHT_SHOULDER):
		firing = true
		print("[INPUT] RB pressed!")
	if Input.get_joy_axis(0, JOY_AXIS_TRIGGER_LEFT) > 0.5:
		firing = true
		print("[INPUT] LT pressed!")
	if Input.get_joy_axis(0, JOY_AXIS_TRIGGER_RIGHT) > 0.5:
		firing = true
		print("[INPUT] RT pressed!")
	
	if firing:
		_do_spray()
		spray_timer = SPRAY_RATE


func _update_visuals():
	## Update ship and crosshair positions
	
	# Sync ship camera with main camera (SubViewport overlay)
	if ship_camera and camera:
		ship_camera.global_transform = camera.global_transform
	
	# Ship position (color picker)
	ship_node.position = Vector3(ship_offset.x, ship_offset.y, control_plane_z)
	
	# Get target position for ship orientation and crosshair
	var target_pos = _get_target_plane_pos()
	
	# Ship orientation: point towards the target
	var target_world = camera.global_transform * Vector3(target_pos.x, target_pos.y, target_plane_z)
	var ship_world = camera.global_transform * ship_node.position
	var look_direction = (target_world - ship_world).normalized()
	if look_direction.length_squared() > 0.001:
		ship_node.look_at(ship_world + look_direction, Vector3.UP)
	
	# Aim crosshair on control plane (if visible)
	if aim_crosshair:
		aim_crosshair.position = Vector3(aim_offset.x, aim_offset.y, control_plane_z)
	
	# Target crosshair - use the already calculated target_pos
	target_crosshair.position = Vector3(target_pos.x, target_pos.y, target_plane_z)
	
	# Update reticle on surface
	_update_reticle()


func _get_target_plane_pos() -> Vector2:
	## Scale aim offset from control plane bounds to target plane bounds
	## Uses current_target_plane_size which expands during finale
	var target_bounds = current_target_plane_size / 2.0
	var control_bounds = player_move_bounds
	var scale_x = target_bounds.x / control_bounds.x
	var scale_y = target_bounds.y / control_bounds.y
	return Vector2(aim_offset.x * scale_x, aim_offset.y * scale_y)


func _update_reticle():
	## Update the reticle indicator on the actual surface
	
	# Get scaled target position
	var target_pos = _get_target_plane_pos()
	
	# Camera-local 3D points
	var aim_local = Vector3(aim_offset.x, aim_offset.y, control_plane_z)
	var target_local = Vector3(target_pos.x, target_pos.y, target_plane_z)
	
	# Transform to world
	var world_origin: Vector3 = camera.global_transform * aim_local
	var world_target: Vector3 = camera.global_transform * target_local
	var direction = (world_target - world_origin).normalized()
	
	# Raycast
	var space_state = get_world_3d().direct_space_state
	if not space_state:
		reticle_indicator.visible = false
		return
	
	var end_point = world_origin + direction * 200.0
	var query = PhysicsRayQueryParameters3D.create(world_origin, end_point)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	
	var result = space_state.intersect_ray(query)
	if result.is_empty():
		# Not hitting anything - show trajectory line from SHIP toward target
		reticle_indicator.visible = false
		var ship_local = Vector3(ship_offset.x, ship_offset.y, control_plane_z)
		var world_ship: Vector3 = camera.global_transform * ship_local
		var ship_direction = (world_target - world_ship).normalized()
		_update_trajectory_line(world_ship, ship_direction)
		return
	
	var hit_pos: Vector3 = result["position"]
	var hit_normal: Vector3 = result.get("normal", Vector3.UP)
	var collider = result.get("collider")
	
	# Check if we hit a paintable target (has Decoree)
	var decoree = _find_decoree(collider)
	
	if decoree:
		# Hitting a paintable target - show reticle (always visible aiming helper), hide trajectory line
		reticle_indicator.visible = true
		reticle_indicator.global_position = hit_pos + hit_normal * 0.05
		if trajectory_line:
			trajectory_line.visible = false
		
		# Align to surface
		if hit_normal != Vector3.UP and hit_normal != Vector3.DOWN:
			reticle_indicator.look_at(reticle_indicator.global_position + hit_normal, Vector3.UP)
			reticle_indicator.rotate_object_local(Vector3.RIGHT, deg_to_rad(90))
	else:
		# Hitting non-paintable geometry - show trajectory line from SHIP near hit point
		reticle_indicator.visible = false
		var ship_local = Vector3(ship_offset.x, ship_offset.y, control_plane_z)
		var world_ship: Vector3 = camera.global_transform * ship_local
		var ship_direction = (world_target - world_ship).normalized()
		var dist_to_hit = (world_ship - hit_pos).length()
		# Place trajectory line segment near where we hit (shows "close but not on target")
		_update_trajectory_line(world_ship, ship_direction, 10.0, max(5.0, dist_to_hit - 12.0))


func _do_spray():
	## Shoot projectile from SHIP position toward the AIM target
	## The ray for hit detection goes from aim position (straight line)
	## But the visual projectile starts from the ship
	
	print("[SPRAY] Firing from ship at aim target")
	
	# Get scaled target position
	var target_pos = _get_target_plane_pos()
	
	# Camera-local positions
	var ship_local = Vector3(ship_offset.x, ship_offset.y, control_plane_z)
	var aim_local = Vector3(aim_offset.x, aim_offset.y, control_plane_z)
	var target_local = Vector3(target_pos.x, target_pos.y, target_plane_z)
	
	# Transform to world
	var world_ship: Vector3 = camera.global_transform * ship_local
	var world_aim: Vector3 = camera.global_transform * aim_local
	var world_target: Vector3 = camera.global_transform * target_local
	var direction = (world_target - world_aim).normalized()
	
	print("[SPRAY] world_aim=", world_aim, " direction=", direction)
	
	# Raycast from aim position to find what we hit (straight line)
	var space_state = get_world_3d().direct_space_state
	if not space_state:
		print("[SPRAY] No space state!")
		return
	
	var end_point = world_aim + direction * 200.0
	var query = PhysicsRayQueryParameters3D.create(world_aim, end_point)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	
	var result = space_state.intersect_ray(query)
	if result.is_empty():
		print("[SPRAY] Raycast missed - no collision")
		return
	
	var collider = result["collider"]
	var hit_pos: Vector3 = result["position"]
	var hit_normal: Vector3 = result.get("normal", Vector3.UP)
	
	print("[SPRAY] Hit: ", collider.name if collider else "null", " at ", hit_pos)
	
	# Find the Decoree on the giant
	var decoree = _find_decoree(collider)
	if decoree:
		print("[SPRAY] Found decoree: ", decoree.name)
		# Create payload for the paint - using the ship's current color
		var payload = AmpuPayload.new()
		payload.payload_type = AmpuPayload.PayloadType.DECAL
		payload.paint = player_color
		payload.image = decal_textures[randi_range(0, decal_textures.size() - 1)]
		payload.size = 0.2  # Smaller projectile visual
		
		# We already know where it hits, so call _shoot_with_animation
		# This bypasses the raycast inside decoree which doesn't work from ship angle
		_shoot_with_animation(decoree, world_ship, hit_pos, hit_normal, payload)
	else:
		print("[SPRAY] No decoree found for collider: ", collider.name if collider else "null")


func _shoot_with_animation(decoree: Decoree, from_world: Vector3, hit_world: Vector3, hit_normal: Vector3, payload: AmpuPayload):
	## Shoot a projectile from 'from_world' to 'hit_world' with animation
	## Then apply paint at hit location
	
	# Convert hit to local space for the decoree
	var hit_local = decoree.to_local(hit_world)
	var normal_local = decoree.global_transform.basis.inverse() * hit_normal
	
	# Create animated projectile
	var ongoing = AmpuOngoing.new(
		decoree,
		decoree.to_local(from_world),
		payload,
		null,  # No specific collider needed
		hit_local,
		normal_local
	)
	decoree.ongoings.push_back(ongoing)


func _find_decoree(collider: Object) -> Decoree:
	## Find the Decoree node associated with this collider
	if collider == null:
		return null
	
	if collider is Decoree:
		return collider as Decoree
	
	if collider is Node:
		var n := collider as Node
		# Look up the tree
		while n != null:
			# Check if this node has a Decoree child
			var decoree = n.find_child("Decoree", false)
			if decoree and decoree is Decoree:
				return decoree
			# Check if parent has Decoree
			n = n.get_parent()
			if n and n is Decoree:
				return n as Decoree
	
	return null
