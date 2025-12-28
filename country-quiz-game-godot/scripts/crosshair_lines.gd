extends Node3D
## Draws latitude and longitude crosshair lines on the globe
## Self-contained visual component that updates based on parent's state

@export var globe_radius: float = 2.0
@export var line_color: Color = Color(0.7, 0.7, 0.7, 0.15)
@export var line_width: float = 0.01
@export var segments: int = 64

var latitude_line: MeshInstance3D
var longitude_line: MeshInstance3D
var current_lat: float = 0.0
var current_lon: float = 0.0

func _ready():
	latitude_line = MeshInstance3D.new()
	add_child(latitude_line)
	
	longitude_line = MeshInstance3D.new()
	add_child(longitude_line)
	
	update_lines(0.0, 0.0)

func _process(_delta):
	var globe = get_parent()
	if globe and globe.has_method("get_crosshair_position"):
		var pos_data = globe.get_crosshair_position()
		if pos_data.valid:
			var lat = pos_data.latitude
			var lon = pos_data.longitude
			
			if abs(lat - current_lat) > 0.1 or abs(lon - current_lon) > 0.1:
				update_lines(lat, lon)
				current_lat = lat
				current_lon = lon

func update_lines(lat_deg: float, lon_deg: float):
	draw_latitude_line(lat_deg)
	draw_longitude_line(lon_deg)

func draw_latitude_line(lat_deg: float):
	var lat_rad = deg_to_rad(lat_deg)
	
	var circle_radius = globe_radius * cos(lat_rad)
	var circle_height = globe_radius * sin(lat_rad)
	
	if abs(circle_radius) < 0.1:
		latitude_line.visible = false
		return
	
	latitude_line.visible = true
	
	var immediate_mesh = ImmediateMesh.new()
	
	var material = StandardMaterial3D.new()
	material.albedo_color = line_color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, material)
	
	for i in range(segments + 1):
		var angle = (float(i) / segments) * TAU
		var x = circle_radius * sin(angle)
		var y = circle_height
		var z = circle_radius * cos(angle)
		
		var point = Vector3(x, y, z)
		var offset = point.normalized() * (line_width + 0.005)
		point += offset
		
		immediate_mesh.surface_add_vertex(point)
	
	immediate_mesh.surface_end()
	
	latitude_line.mesh = immediate_mesh

func draw_longitude_line(lon_deg: float):
	var lon_rad = deg_to_rad(lon_deg)
	
	longitude_line.visible = true
	
	var immediate_mesh = ImmediateMesh.new()
	
	var material = StandardMaterial3D.new()
	material.albedo_color = line_color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, material)
	
	for i in range(segments + 1):
		var lat = -PI/2 + (float(i) / segments) * PI
		
		var x = globe_radius * cos(lat) * sin(lon_rad)
		var y = globe_radius * sin(lat)
		var z = globe_radius * cos(lat) * cos(lon_rad)
		
		var point = Vector3(x, y, z)
		var offset = point.normalized() * (line_width + 0.005)
		point += offset
		
		immediate_mesh.surface_add_vertex(point)
	
	immediate_mesh.surface_end()
	
	longitude_line.mesh = immediate_mesh

func toggle_lines_visibility(visible: bool):
	if latitude_line:
		latitude_line.visible = visible
	if longitude_line:
		longitude_line.visible = visible
