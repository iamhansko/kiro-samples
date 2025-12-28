extends Node3D
## Displays pole markers and reference lines on the globe
## Self-contained visual component

var globe_radius: float = 2.0

func _ready():
	create_pole_markers()

func create_pole_markers():
	create_pole_marker(Vector3(0, globe_radius + 0.01, 0), Color(1.0, 1.0, 1.0), "North Pole")
	create_pole_marker(Vector3(0, -globe_radius - 0.01, 0), Color(1.0, 1.0, 1.0), "South Pole")
	create_equator_dashed_line()
	create_prime_meridian_dashed_line()

func create_pole_marker(position: Vector3, color: Color, label: String):
	var mesh_instance = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.02
	sphere_mesh.height = 0.04
	
	mesh_instance.mesh = sphere_mesh
	mesh_instance.position = position
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_instance.material_override = material
	
	mesh_instance.name = label
	add_child(mesh_instance)

func create_equator_dashed_line():
	var segments = 360
	var dash_length = 2
	var gap_length = 2
	
	for i in range(segments):
		if i % (dash_length + gap_length) < dash_length:
			var angle_start = (float(i) / segments) * TAU
			var angle_end = (float(i + 1) / segments) * TAU
			
			var x_start = (globe_radius + 0.01) * sin(angle_start)
			var z_start = (globe_radius + 0.01) * cos(angle_start)
			var x_end = (globe_radius + 0.01) * sin(angle_end)
			var z_end = (globe_radius + 0.01) * cos(angle_end)
			
			var immediate_mesh = ImmediateMesh.new()
			var mesh_instance = MeshInstance3D.new()
			
			var material = StandardMaterial3D.new()
			material.albedo_color = Color(1.0, 1.0, 1.0, 0.5)
			material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mesh_instance.material_override = material
			
			immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
			immediate_mesh.surface_add_vertex(Vector3(x_start, 0, z_start))
			immediate_mesh.surface_add_vertex(Vector3(x_end, 0, z_end))
			immediate_mesh.surface_end()
			
			mesh_instance.mesh = immediate_mesh
			mesh_instance.name = "Equator_Dash_" + str(i)
			add_child(mesh_instance)

func create_prime_meridian_dashed_line():
	var segments = 180
	var dash_length = 2
	var gap_length = 2
	var lon_rad = 0.0
	
	for i in range(segments):
		if i % (dash_length + gap_length) < dash_length:
			var lat_start = -PI/2 + (float(i) / segments) * PI
			var lat_end = -PI/2 + (float(i + 1) / segments) * PI
			
			var x_start = (globe_radius + 0.01) * cos(lat_start) * sin(lon_rad)
			var y_start = (globe_radius + 0.01) * sin(lat_start)
			var z_start = (globe_radius + 0.01) * cos(lat_start) * cos(lon_rad)
			
			var x_end = (globe_radius + 0.01) * cos(lat_end) * sin(lon_rad)
			var y_end = (globe_radius + 0.01) * sin(lat_end)
			var z_end = (globe_radius + 0.01) * cos(lat_end) * cos(lon_rad)
			
			var immediate_mesh = ImmediateMesh.new()
			var mesh_instance = MeshInstance3D.new()
			
			var material = StandardMaterial3D.new()
			material.albedo_color = Color(1.0, 1.0, 1.0, 0.5)
			material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mesh_instance.material_override = material
			
			immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
			immediate_mesh.surface_add_vertex(Vector3(x_start, y_start, z_start))
			immediate_mesh.surface_add_vertex(Vector3(x_end, y_end, z_end))
			immediate_mesh.surface_end()
			
			mesh_instance.mesh = immediate_mesh
			mesh_instance.name = "PrimeMeridian_Dash_" + str(i)
			add_child(mesh_instance)
