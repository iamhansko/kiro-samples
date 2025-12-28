extends Node3D
## Draws world map borders on the globe surface
## Self-contained component with minimal dependencies

var globe_radius: float = 2.0
var countries_data: Array = []

func _ready():
	load_geojson_data()
	draw_country_borders()

func load_geojson_data():
	var file_path = "res://public/earth.geo.json"
	var file = FileAccess.open(file_path, FileAccess.READ)
	
	if file == null:
		return
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		return
	
	var data = json.get_data()
	
	if data.has("features"):
		countries_data = data["features"]
	else:
		return

func draw_country_borders():
	if countries_data.is_empty():
		return
	
	var country_count = 0
	
	for feature in countries_data:
		if not feature.has("geometry"):
			continue
		
		var geometry = feature["geometry"]
		var properties = feature.get("properties", {})
		var country_name = properties.get("ADMIN", properties.get("name", "Unknown"))
		
		if geometry["type"] == "Polygon":
			draw_polygon_border(geometry["coordinates"], country_name)
		elif geometry["type"] == "MultiPolygon":
			draw_multipolygon_border(geometry["coordinates"], country_name)
		
		country_count += 1

func draw_polygon_border(coordinates: Array, country_name: String):
	if coordinates.is_empty():
		return
	
	var outer_ring = coordinates[0]
	draw_country_outline(outer_ring, country_name)

func draw_multipolygon_border(coordinates: Array, country_name: String):
	var polygon_index = 0
	for polygon in coordinates:
		if polygon.is_empty():
			continue
		var outer_ring = polygon[0]
		draw_country_outline(outer_ring, country_name + "_" + str(polygon_index))
		polygon_index += 1

func draw_country_outline(ring: Array, country_name: String):
	if ring.size() < 3:
		return
	
	var immediate_mesh = ImmediateMesh.new()
	var mesh_instance = MeshInstance3D.new()
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 1.0, 1.0, 1.0)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	mesh_instance.material_override = material
	
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	
	for coord in ring:
		if coord.size() < 2:
			continue
		
		var lon = coord[0]
		var lat = coord[1]
		var pos = latlon_to_3d(lat, lon, globe_radius + 0.005)
		immediate_mesh.surface_add_vertex(pos)
	
	if ring.size() > 0:
		var first_coord = ring[0]
		var pos = latlon_to_3d(first_coord[1], first_coord[0], globe_radius + 0.005)
		immediate_mesh.surface_add_vertex(pos)
	
	immediate_mesh.surface_end()
	
	mesh_instance.mesh = immediate_mesh
	mesh_instance.name = country_name + "_border"
	add_child(mesh_instance)

func latlon_to_3d(lat: float, lon: float, radius: float) -> Vector3:
	var lat_rad = deg_to_rad(lat)
	var lon_rad = deg_to_rad(lon)
	
	var x = radius * cos(lat_rad) * sin(lon_rad)
	var y = radius * sin(lat_rad)
	var z = radius * cos(lat_rad) * cos(lon_rad)
	
	return Vector3(x, y, z)
