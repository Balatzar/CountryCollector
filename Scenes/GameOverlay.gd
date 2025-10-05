extends CanvasLayer

## Beautiful game overlay UI with dart counter, collected countries list, and bonus/malus displays

# Node references
@onready var dart_container: HBoxContainer = $MarginContainer/LayoutContainer/CenterAndRightContainer/TopBar/DartPanel/DartVBox/DartContainer
@onready var countries_list: VBoxContainer = $MarginContainer/LayoutContainer/CenterAndRightContainer/RightPanel/CountriesVBox/ScrollContainer/CountriesList
@onready var bonus_panel: PanelContainer = $MarginContainer/LayoutContainer/LeftPanel/BonusPanel
@onready var bonus_container: VBoxContainer = $MarginContainer/LayoutContainer/LeftPanel/BonusPanel/BonusVBox/BonusEffectsList
@onready var malus_panel: PanelContainer = $MarginContainer/LayoutContainer/LeftPanel/MalusPanel
@onready var malus_container: VBoxContainer = $MarginContainer/LayoutContainer/LeftPanel/MalusPanel/MalusVBox/MalusEffectsList
@onready var zoom_help_panel: PanelContainer = $MarginContainer/LayoutContainer/LeftPanel/ZoomHelpPanel

# Dart icon references for updating
var dart_icons: Array[TextureRect] = []

# Reference to CountryNames for displaying full country names
const CountryNames = preload("res://CountryNames.gd")


func _ready() -> void:
	# Setup dart counter
	_setup_dart_counter()

	# Connect to GameState signals
	GameState.country_collected.connect(_on_country_collected)
	GameState.darts_changed.connect(_on_darts_changed)
	GameState.card_acquired.connect(_on_card_acquired)
	GameState.zoom_bonus_acquired.connect(_on_zoom_bonus_acquired)

	# Initialize countries list with any already collected countries
	for country_id in GameState.collected_countries:
		_add_country_to_list(country_id)

	# Initialize bonus/malus displays
	_update_card_displays()


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





func _on_country_collected(country_id: String) -> void:
	_add_country_to_list(country_id)


func _on_darts_changed(remaining_darts: int) -> void:
	# Update dart icons to reflect current count
	var dart_full_texture: Texture2D = load("res://Assets/dart_left_up.png")
	var dart_empty_texture: Texture2D = load("res://Assets/dart_left_up_empty.png")

	# If we need more icons than we currently have, add them
	while dart_icons.size() < remaining_darts:
		var dart_icon := TextureRect.new()
		dart_icon.custom_minimum_size = Vector2(32, 32)
		dart_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		dart_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		dart_icon.texture = dart_full_texture
		dart_container.add_child(dart_icon)
		dart_icons.append(dart_icon)

	# Update all existing icons
	for i in range(dart_icons.size()):
		if i < remaining_darts:
			dart_icons[i].texture = dart_full_texture
		else:
			dart_icons[i].texture = dart_empty_texture


func _add_country_to_list(country_id: String) -> void:
	var country_label := Label.new()
	var country_name := CountryNames.get_country_name(country_id)
	country_label.text = "✓ " + country_name
	country_label.add_theme_font_size_override("font_size", 20)
	country_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))  # Bright green
	country_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	country_label.add_theme_constant_override("outline_size", 4)
	countries_list.add_child(country_label)


func _on_card_acquired(_card_data: Dictionary) -> void:
	"""Handle when a card is acquired - update the bonus/malus displays"""
	_update_card_displays()


func _update_card_displays() -> void:
	"""Update the bonus and malus containers based on acquired cards"""
	# Clear existing content
	_clear_container(bonus_container)
	_clear_container(malus_container)

	# Get all acquired cards from GameState
	var acquired_cards := GameState.get_acquired_cards()

	# Collect all bonuses and maluses from all power-ups
	var all_bonuses: Array[String] = []
	var all_maluses: Array[String] = []

	for power_up in acquired_cards:
		# Check if this is a new-style power-up (has "type" field)
		if power_up.has("type"):
			var power_up_name: String = power_up.get("name", "Unknown")
			var power_up_type: int = power_up.get("type", 0)

			# PowerUpDefinitions.PowerUpType enum: BONUS = 0, MALUS = 1
			if power_up_type == 0:  # BONUS
				all_bonuses.append(power_up_name)
			else:  # MALUS
				all_maluses.append(power_up_name)
		else:
			# Legacy format: card with bonuses/maluses arrays
			var bonuses: Array = power_up.get("bonuses", [])
			var maluses: Array = power_up.get("maluses", [])

			for bonus in bonuses:
				all_bonuses.append(str(bonus))

			for malus in maluses:
				all_maluses.append(str(malus))

	# Populate bonus container
	if all_bonuses.size() > 0:
		for bonus_text in all_bonuses:
			var label := Label.new()
			label.text = "✓ " + bonus_text
			label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))  # Green
			label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
			label.add_theme_constant_override("outline_size", 3)
			label.add_theme_font_size_override("font_size", 18)
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			bonus_container.add_child(label)
		bonus_panel.visible = true
	else:
		bonus_panel.visible = false

	# Populate malus container
	if all_maluses.size() > 0:
		for malus_text in all_maluses:
			var label := Label.new()
			label.text = "✗ " + malus_text
			label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))  # Red
			label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
			label.add_theme_constant_override("outline_size", 3)
			label.add_theme_font_size_override("font_size", 18)
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			malus_container.add_child(label)
		malus_panel.visible = true
	else:
		malus_panel.visible = false


func _clear_container(container: VBoxContainer) -> void:
	"""Clear all children from a container"""
	for child in container.get_children():
		child.queue_free()


func _on_zoom_bonus_acquired(zoom_level: int) -> void:
	"""Show/hide the zoom help panel based on zoom level"""
	# Show help panel only if zoom is active (level > 0)
	zoom_help_panel.visible = (zoom_level > 0)
