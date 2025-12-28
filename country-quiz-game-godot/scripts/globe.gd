extends Node3D
## Globe controller that manages 3D globe interaction and rotation
## Self-contained scene with minimal external dependencies

signal crosshair_moved(lat: float, lon: float, country: String)

@export var rotation_speed: float = 2.5
@export var zoom_speed: float = 0.2
@export var min_distance: float = 2.1
@export var max_distance: float = 10.0
@export var show_pole_markers: bool = true
@export var show_crosshair_lines: bool = true
@export var drag_sensitivity: float = 0.5

var is_dragging: bool = false
var last_mouse_position: Vector2
var current_crosshair_lat: float = 0.0
var current_crosshair_lon: float = 0.0
var invert_drag_direction: bool = false
var target_rotation: Vector3 = Vector3.ZERO
var is_rotating: bool = false
var drag_rotation: Vector3 = Vector3.ZERO

# Injected dependency - provided by parent
var camera: Camera3D = null

@onready var globe_mesh: MeshInstance3D = $GlobeMesh
@onready var world_map_drawer: Node3D = $WorldMapDrawer
@onready var pole_markers: Node3D = $PoleMarkers
@onready var crosshair_lines: Node3D = $CrosshairLines

func _ready():
	rotation = Vector3(0, 0, 0)
	target_rotation = Vector3(0, 0, 0)
	drag_rotation = Vector3(0, 0, 0)
	
	create_globe()
	
	set_process_input(true)
	set_process(true)
	
	# Initialize child nodes with configuration
	await get_tree().create_timer(0.1).timeout
	_initialize_children()

func _initialize_children():
	"""Initialize child nodes - keeps dependencies internal"""
	if world_map_drawer:
		world_map_drawer.globe_radius = 2.0
	
	if pole_markers:
		pole_markers.globe_radius = 2.0
		pole_markers.visible = show_pole_markers
	
	if crosshair_lines:
		crosshair_lines.globe_radius = 2.0
		crosshair_lines.toggle_lines_visibility(show_crosshair_lines)

## Dependency injection - parent provides camera reference
func set_camera(p_camera: Camera3D):
	camera = p_camera

## Dependency injection - parent controls drag inversion
func set_drag_inversion(inverted: bool):
	invert_drag_direction = inverted

func create_globe():
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 2.0
	sphere_mesh.height = 4.0
	sphere_mesh.radial_segments = 64
	sphere_mesh.rings = 32
	
	globe_mesh.mesh = sphere_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.0, 0.0, 0.0)
	material.metallic = 0.2
	material.roughness = 0.8
	material.specular = 0.3
	globe_mesh.set_surface_override_material(0, material)

func _process(delta):
	if is_rotating:
		rotation = rotation.lerp(target_rotation, delta * rotation_speed)
		
		if rotation.distance_to(target_rotation) < 0.01:
			rotation = target_rotation
			is_rotating = false

func _input(event):
	handle_mouse_input(event)

func update_globe_rotation():
	var lat_rad = deg_to_rad(current_crosshair_lat)
	var lon_rad = deg_to_rad(current_crosshair_lon)
	
	var target_x = cos(lat_rad) * sin(lon_rad)
	var target_y = sin(lat_rad)
	var target_z = cos(lat_rad) * cos(lon_rad)
	var target_point = Vector3(target_x, target_y, target_z)
	
	var from_dir = target_point.normalized()
	var to_dir = Vector3(0, 0, 1)
	
	var dot = from_dir.dot(to_dir)
	var quat: Quaternion
	
	if dot > 0.9999:
		quat = Quaternion.IDENTITY
	elif dot < -0.9999:
		quat = Quaternion(Vector3(0, 1, 0), PI)
	else:
		var axis = from_dir.cross(to_dir).normalized()
		var angle = acos(clamp(dot, -1.0, 1.0))
		quat = Quaternion(axis, angle)
	
	var basis1 = Basis(quat)
	
	var north_pole = Vector3(0, 1, 0)
	var rotated_north = basis1 * north_pole
	
	var north_projected = Vector3(rotated_north.x, rotated_north.y, 0)
	
	if north_projected.length_squared() > 0.001:
		north_projected = north_projected.normalized()
		
		var target_up = Vector3(0, 1, 0)
		
		var dot_up = north_projected.dot(target_up)
		var angle_up = acos(clamp(dot_up, -1.0, 1.0))
		
		var cross_z = north_projected.x * target_up.y - north_projected.y * target_up.x
		if cross_z < 0:
			angle_up = -angle_up
		
		var quat_up = Quaternion(Vector3(0, 0, 1), angle_up)
		
		var final_quat = quat_up * quat
		global_transform = Transform3D(Basis(final_quat), global_transform.origin)
	else:
		global_transform = Transform3D(basis1, global_transform.origin)

func handle_mouse_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging = true
				last_mouse_position = event.position
			else:
				is_dragging = false
		
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			if camera:
				camera.position.z = max(min_distance, camera.position.z - zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if camera:
				camera.position.z = min(max_distance, camera.position.z + zoom_speed)
	
	elif event is InputEventMouseMotion and is_dragging:
		var delta_mouse = event.position - last_mouse_position
		
		var distance_factor = 1.0
		if camera:
			var normalized_distance = (camera.position.z - min_distance) / (max_distance - min_distance)
			distance_factor = clamp(normalized_distance, 0.05, 1.0)
		
		var sensitivity = drag_sensitivity * 0.3 * distance_factor
		var lon_change = delta_mouse.x * sensitivity
		var lat_change = -delta_mouse.y * sensitivity
		
		if invert_drag_direction:
			lon_change = -lon_change
			lat_change = -lat_change
		
		current_crosshair_lon += lon_change
		current_crosshair_lat = clamp(current_crosshair_lat + lat_change, -90.0, 90.0)
		
		update_globe_rotation()
		_emit_crosshair_update()
		
		last_mouse_position = event.position

func _emit_crosshair_update():
	"""Emit signal when crosshair moves - loose coupling via signals"""
	var country = get_country_from_coords(current_crosshair_lat, current_crosshair_lon)
	crosshair_moved.emit(current_crosshair_lat, fmod(current_crosshair_lon + 180.0, 360.0) - 180.0, country)

func get_country_from_coords(lat: float, lon: float) -> String:
	return CountryData.get_country_from_coords(lat, lon)

func get_crosshair_position() -> Dictionary:
	return {
		"valid": true, 
		"latitude": current_crosshair_lat, 
		"longitude": fmod(current_crosshair_lon + 180.0, 360.0) - 180.0
	}

func move_to_location(lat: float, lon: float):
	current_crosshair_lat = clamp(lat, -90.0, 90.0)
	current_crosshair_lon = lon
	
	update_globe_rotation()
	_emit_crosshair_update()
