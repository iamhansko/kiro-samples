extends Node
## Autoload singleton for country data management
## Appropriate use of autoload: manages its own data, globally accessible,
## doesn't interfere with other objects' state

var country_polygons = {}
var country_iso_codes = {}
var is_loaded = false

func _ready():
	load_country_data()

func load_country_data():
	var file_path = "res://public/earth.geo.json"
	var file = FileAccess.open(file_path, FileAccess.READ)
	
	if not file:
		return
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_text)
	
	if error != OK:
		return
	
	var data = json.data
	
	if not data.has("features"):
		return
	
	for feature in data.features:
		if not feature.has("properties") or not feature.has("geometry"):
			continue
		
		var properties = feature.properties
		var geometry = feature.geometry
		
		var country_name = ""
		if properties.has("ADMIN"):
			country_name = properties.ADMIN
		elif properties.has("name"):
			country_name = properties.name
		else:
			continue
		
		if properties.has("iso_a2") and properties.iso_a2 != "-99":
			country_iso_codes[country_name] = properties.iso_a2.to_lower()
		
		if geometry.type == "Polygon":
			if not country_polygons.has(country_name):
				country_polygons[country_name] = []
			country_polygons[country_name].append(geometry.coordinates)
		elif geometry.type == "MultiPolygon":
			if not country_polygons.has(country_name):
				country_polygons[country_name] = []
			for polygon in geometry.coordinates:
				country_polygons[country_name].append(polygon)
	
	is_loaded = true

static func get_country_from_coords(lat: float, lon: float) -> String:
	var instance = null
	var tree = Engine.get_main_loop() as SceneTree
	if tree and tree.root:
		instance = tree.root.get_node_or_null("/root/CountryData")
	
	if not instance or not instance.is_loaded:
		return "Unknown"
	
	for country_name in instance.country_polygons:
		var polygons = instance.country_polygons[country_name]
		
		for polygon in polygons:
			if polygon.size() > 0:
				var outer_ring = polygon[0]
				if point_in_polygon(lon, lat, outer_ring):
					var in_hole = false
					for i in range(1, polygon.size()):
						if point_in_polygon(lon, lat, polygon[i]):
							in_hole = true
							break
					
					if not in_hole:
						return country_name
	
	return ""

static func point_in_polygon(x: float, y: float, polygon: Array) -> bool:
	var inside = false
	var n = polygon.size()
	
	if n < 3:
		return false
	
	var p1 = polygon[0]
	var x1 = p1[0]
	var y1 = p1[1]
	
	for i in range(1, n + 1):
		var p2 = polygon[i % n]
		var x2 = p2[0]
		var y2 = p2[1]
		
		if y > min(y1, y2):
			if y <= max(y1, y2):
				if x <= max(x1, x2):
					var x_intersection = (y - y1) * (x2 - x1) / (y2 - y1) + x1
					if x1 == x2 or x <= x_intersection:
						inside = not inside
		
		x1 = x2
		y1 = y2
	
	return inside

static func get_all_countries() -> Array:
	var instance = null
	var tree = Engine.get_main_loop() as SceneTree
	if tree and tree.root:
		instance = tree.root.get_node_or_null("/root/CountryData")
	
	if not instance or not instance.is_loaded:
		return []
	
	return instance.country_polygons.keys()

static func get_country_iso_code(country_name: String) -> String:
	var instance = null
	var tree = Engine.get_main_loop() as SceneTree
	if tree and tree.root:
		instance = tree.root.get_node_or_null("/root/CountryData")
	
	if not instance or not instance.is_loaded:
		return ""
	
	if instance.country_iso_codes.has(country_name):
		return instance.country_iso_codes[country_name]
	
	return ""

static func get_countries_with_flags() -> Array:
	var instance = null
	var tree = Engine.get_main_loop() as SceneTree
	if tree and tree.root:
		instance = tree.root.get_node_or_null("/root/CountryData")
	
	if not instance or not instance.is_loaded:
		return []
	
	var countries_with_flags = []
	for country_name in instance.country_polygons.keys():
		var iso_code = get_country_iso_code(country_name)
		if iso_code != "":
			var flag_path = "res://public/flags/" + iso_code + ".svg"
			if ResourceLoader.exists(flag_path):
				countries_with_flags.append(country_name)
	
	return countries_with_flags

static func get_country_representative_point(country_name: String) -> Dictionary:
	var instance = null
	var tree = Engine.get_main_loop() as SceneTree
	if tree and tree.root:
		instance = tree.root.get_node_or_null("/root/CountryData")
	
	if not instance or not instance.is_loaded:
		return {}
	
	if not instance.country_polygons.has(country_name):
		return {}
	
	var polygons = instance.country_polygons[country_name]
	
	if polygons.size() == 0:
		return {}
	
	var first_polygon = polygons[0]
	if first_polygon.size() == 0:
		return {}
	
	var outer_ring = first_polygon[0]
	
	if outer_ring.size() == 0:
		return {}
	
	var sum_lon = 0.0
	var sum_lat = 0.0
	var count = 0
	
	for point in outer_ring:
		sum_lon += point[0]
		sum_lat += point[1]
		count += 1
	
	if count == 0:
		return {}
	
	return {
		"longitude": sum_lon / count,
		"latitude": sum_lat / count
	}
