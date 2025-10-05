extends CanvasLayer

## Beautiful game overlay UI with timer, dart counter, and collected countries list

# Timer variables
@export var countdown_time: int = 60
var current_time: int = 60

# Node references
@onready var timer_label: Label = $MarginContainer/LayoutContainer/TopBar/TimerPanel/TimerContainer/TimeLabel
@onready var countdown_timer: Timer = $CountdownTimer
@onready var dart_container: HBoxContainer = $MarginContainer/LayoutContainer/TopBar/DartPanel/DartVBox/DartContainer
@onready var countries_list: VBoxContainer = $MarginContainer/LayoutContainer/RightPanel/CountriesVBox/ScrollContainer/CountriesList

# Dart icon references for updating
var dart_icons: Array[TextureRect] = []


func _ready() -> void:
	# Initialize timer
	current_time = countdown_time
	_update_timer_display()

	# Start countdown
	countdown_timer.start()

	# Setup dart counter
	_setup_dart_counter()

	# Connect to GameState signals
	GameState.country_collected.connect(_on_country_collected)
	GameState.darts_changed.connect(_on_darts_changed)

	# Initialize countries list with any already collected countries
	for country_id in GameState.collected_countries:
		_add_country_to_list(country_id)


func _setup_dart_counter() -> void:
	# Clear any existing children and icon references
	for child in dart_container.get_children():
		child.queue_free()
	dart_icons.clear()

	# Load dart textures
	var dart_full_texture: Texture2D = load("res://Assets/dart_left_up.png")
	var dart_empty_texture: Texture2D = load("res://Assets/dart_left_up_empty.png")

	# Get current dart count from GameState
	var remaining := GameState.get_remaining_darts()

	# Create dart icons
	for i in range(GameState.MAX_DARTS):
		var dart_icon := TextureRect.new()
		dart_icon.custom_minimum_size = Vector2(32, 32)
		dart_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		dart_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

		# Show full dart for available darts, empty for used darts
		if i < remaining:
			dart_icon.texture = dart_full_texture
		else:
			dart_icon.texture = dart_empty_texture

		dart_container.add_child(dart_icon)
		dart_icons.append(dart_icon)


func _on_countdown_timer_timeout() -> void:
	current_time -= 1
	_update_timer_display()
	
	if current_time <= 0:
		countdown_timer.stop()
		# Game over logic could go here


func _update_timer_display() -> void:
	var minutes := current_time / 60
	var seconds := current_time % 60
	timer_label.text = "%02d:%02d" % [minutes, seconds]
	
	# Add visual feedback for low time
	if current_time <= 10:
		timer_label.add_theme_color_override("font_color", Color.RED)
	elif current_time <= 30:
		timer_label.add_theme_color_override("font_color", Color.ORANGE)
	else:
		timer_label.add_theme_color_override("font_color", Color.WHITE)


func _on_country_collected(country_id: String) -> void:
	_add_country_to_list(country_id)


func _on_darts_changed(remaining_darts: int) -> void:
	# Update dart icons to reflect current count
	var dart_full_texture: Texture2D = load("res://Assets/dart_left_up.png")
	var dart_empty_texture: Texture2D = load("res://Assets/dart_left_up_empty.png")

	for i in range(dart_icons.size()):
		if i < remaining_darts:
			dart_icons[i].texture = dart_full_texture
		else:
			dart_icons[i].texture = dart_empty_texture


func _add_country_to_list(country_id: String) -> void:
	var country_label := Label.new()
	country_label.text = "✓ " + country_id
	country_label.add_theme_font_size_override("font_size", 20)
	country_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))  # Bright green
	country_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	country_label.add_theme_constant_override("outline_size", 4)
	countries_list.add_child(country_label)

