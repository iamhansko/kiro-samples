extends Node
## Main game manager that coordinates between Globe and UI
## Follows dependency injection pattern - parent manages child relationships

@onready var globe: Node3D = $Globe
@onready var ui: CanvasLayer = $UI
@onready var camera: Camera3D = $Camera3D

func _ready():
	# Initialize dependencies - parent provides references to children
	if globe and ui:
		# Connect signals for loose coupling
		globe.crosshair_moved.connect(_on_globe_crosshair_moved)
		ui.submit_pressed.connect(_on_ui_submit_pressed)
		ui.reset_pressed.connect(_on_ui_reset_pressed)
		ui.hint_pressed.connect(_on_ui_hint_pressed)
		ui.direction_toggled.connect(_on_ui_direction_toggled)
		
		# Inject camera reference into globe
		globe.set_camera(camera)
		
		# Initialize UI with first country
		ui.initialize_game()

func _on_globe_crosshair_moved(lat: float, lon: float, country: String):
	if ui:
		ui.update_crosshair_info(lat, lon, country)

func _on_ui_submit_pressed():
	if globe and ui:
		var pos_data = globe.get_crosshair_position()
		var selected_country = globe.get_country_from_coords(pos_data.latitude, pos_data.longitude)
		ui.check_answer(selected_country)

func _on_ui_reset_pressed():
	if ui:
		ui.reset_game()

func _on_ui_hint_pressed():
	if globe and ui:
		var target_country = ui.get_current_target_country()
		if target_country != "":
			var coords = CountryData.get_country_representative_point(target_country)
			if coords.has("latitude") and coords.has("longitude"):
				globe.move_to_location(coords.latitude, coords.longitude)

func _on_ui_direction_toggled(inverted: bool):
	if globe:
		globe.set_drag_inversion(inverted)
