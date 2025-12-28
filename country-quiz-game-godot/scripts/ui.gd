extends CanvasLayer
## UI controller that manages game interface and user interactions
## Communicates with parent via signals for loose coupling

signal submit_pressed()
signal reset_pressed()
signal hint_pressed()
signal direction_toggled(inverted: bool)

@onready var flag_display: TextureRect = $Control/MarginContainer/VBoxContainer/FlagDisplay
@onready var score_label: Label = $Control/MarginContainer/VBoxContainer/ScoreLabel
@onready var feedback_label: Label = $Control/MarginContainer/VBoxContainer/FeedbackLabel
@onready var target_country_label: Label = $Control/MarginContainer/VBoxContainer/TargetCountryLabel
@onready var crosshair: Control = $Control/Crosshair
@onready var crosshair_info_label: Label = $Control/CrosshairInfoLabel
@onready var direction_toggle: CheckButton = $Control/DirectionToggle
@onready var compass_labels: Control = $Control/CompassLabels
@onready var north_label: Label = $Control/CompassLabels/NorthLabel
@onready var south_label: Label = $Control/CompassLabels/SouthLabel
@onready var east_label: Label = $Control/CompassLabels/EastLabel
@onready var west_label: Label = $Control/CompassLabels/WestLabel
@onready var reset_button: Button = $Control/BottomLeftPanel/ResetButton
@onready var submit_button: Button = $Control/BottomLeftPanel/SubmitButton
@onready var answer_button: Button = $Control/BottomLeftPanel/HintButton

var current_target_country: String = ""
var game_score: int = 0

# Injected dependency - provided by parent
var globe: Node3D = null
var camera: Camera3D = null

func _ready():
	feedback_label.text = ""
	update_score(0)
	
	if crosshair:
		crosshair.visible = true
	
	# Connect UI signals - loose coupling
	if direction_toggle:
		direction_toggle.toggled.connect(_on_direction_toggle)
		direction_toggle.button_pressed = true
	
	if reset_button:
		reset_button.pressed.connect(_on_reset_button_pressed)
	if submit_button:
		submit_button.pressed.connect(_on_submit_button_pressed)
	if answer_button:
		answer_button.pressed.connect(_on_answer_button_pressed)
	
	set_process(true)

## Initialize game - called by parent after dependencies are set
func initialize_game():
	await get_tree().create_timer(0.1).timeout
	select_random_country()

func _process(_delta):
	update_compass_labels()

## Update crosshair info from external source (via signal)
func update_crosshair_info(lat: float, lon: float, country: String):
	if not crosshair_info_label:
		return
	
	if country == "":
		country = "(Ocean or Unknown)"
	
	crosshair_info_label.text = "Country: " + country + "\n"
	crosshair_info_label.text += "Latitude: %.1f°\n" % lat
	crosshair_info_label.text += "Longitude: %.1f°" % lon

func _on_direction_toggle(button_pressed: bool):
	direction_toggled.emit(button_pressed)

## Get current target country - called by parent
func get_current_target_country() -> String:
	return current_target_country

func update_score(new_score: int):
	score_label.text = "Score: " + str(new_score)

func update_compass_labels():
	# Get references from parent if not set
	if not globe:
		globe = get_node_or_null("../Globe")
	if not camera:
		camera = get_node_or_null("../Camera3D")
	
	if not globe or not camera or not compass_labels:
		return
	
	var north_local = Vector3(0, 1, 0)
	var south_local = Vector3(0, -1, 0)
	
	var north_world = globe.global_transform.basis * north_local
	var south_world = globe.global_transform.basis * south_local
	
	var cam_forward = -camera.global_transform.basis.z
	var cam_right = camera.global_transform.basis.x
	var cam_up = camera.global_transform.basis.y
	
	var north_proj = project_to_screen_direction(north_world, cam_forward, cam_right, cam_up)
	var south_proj = project_to_screen_direction(south_world, cam_forward, cam_right, cam_up)
	
	var viewport_size = get_viewport().get_visible_rect().size
	var center = viewport_size / 2
	var margin = 40.0
	
	update_label_position(north_label, north_proj, center, viewport_size, margin)
	update_label_position(south_label, south_proj, center, viewport_size, margin)
	
	var east_proj = Vector2(-north_proj.y, north_proj.x)
	var west_proj = Vector2(north_proj.y, -north_proj.x)
	
	update_label_position(east_label, east_proj, center, viewport_size, margin)
	update_label_position(west_label, west_proj, center, viewport_size, margin)

func project_to_screen_direction(world_dir: Vector3, cam_forward: Vector3, cam_right: Vector3, cam_up: Vector3) -> Vector2:
	var proj = world_dir - cam_forward * world_dir.dot(cam_forward)
	
	if proj.length_squared() < 0.001:
		return Vector2.ZERO
	
	proj = proj.normalized()
	
	var x = proj.dot(cam_right)
	var y = proj.dot(cam_up)
	
	return Vector2(x, -y)

func update_label_position(label: Label, direction: Vector2, center: Vector2, viewport_size: Vector2, margin: float):
	if direction.length_squared() < 0.001:
		label.modulate.a = 0.3
		return
	
	label.modulate.a = 0.8
	
	var dir_normalized = direction.normalized()
	
	var max_x = (viewport_size.x / 2) - margin
	var max_y = (viewport_size.y / 2) - margin
	
	var scale_x = max_x / abs(dir_normalized.x) if abs(dir_normalized.x) > 0.001 else 999999
	var scale_y = max_y / abs(dir_normalized.y) if abs(dir_normalized.y) > 0.001 else 999999
	var label_scale = min(scale_x, scale_y)
	
	var screen_pos = center + dir_normalized * label_scale
	
	var label_size = label.size
	label.position = screen_pos - label_size / 2

func select_random_country():
	var countries_with_flags = CountryData.get_countries_with_flags()
	
	if countries_with_flags.size() > 0:
		current_target_country = countries_with_flags[randi() % countries_with_flags.size()]
		
		var iso_code = CountryData.get_country_iso_code(current_target_country)
		
		if iso_code != "":
			var flag_path = "res://public/flags/" + iso_code + ".svg"
			
			if ResourceLoader.exists(flag_path):
				var flag_texture = load(flag_path)
				
				if flag_display:
					flag_display.texture = flag_texture
					flag_display.visible = true
			else:
				if flag_display:
					flag_display.visible = false
		
		if target_country_label:
			target_country_label.text = "Find:"
			target_country_label.add_theme_color_override("font_color", Color.WHITE)
	else:
		if flag_display:
			flag_display.visible = false

func _on_reset_button_pressed():
	reset_pressed.emit()

func _on_submit_button_pressed():
	submit_pressed.emit()

func _on_answer_button_pressed():
	hint_pressed.emit()

## Reset game state - called by parent
func reset_game():
	select_random_country()
	game_score = 0
	update_score(game_score)

## Check answer - called by parent with selected country
func check_answer(selected_country: String):
	if selected_country == current_target_country:
		game_score += 1
		update_score(game_score)
		target_country_label.text = "Find: Correct"
		target_country_label.add_theme_color_override("font_color", Color.GREEN)
		
		await get_tree().create_timer(1.5).timeout
		select_random_country()
	else:
		target_country_label.text = "Find: Wrong"
		target_country_label.add_theme_color_override("font_color", Color.RED)
		
		await get_tree().create_timer(2.0).timeout
		target_country_label.text = "Find:"
		target_country_label.add_theme_color_override("font_color", Color.WHITE)
