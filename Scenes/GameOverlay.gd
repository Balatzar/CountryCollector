extends CanvasLayer

## Beautiful game overlay UI with dart counter, collected countries list, and bonus/malus displays

# Node references
@onready var dart_container: HBoxContainer = $MarginContainer/LayoutContainer/CenterAndRightContainer/TopBar/DartPanel/DartVBox/DartContainer
@onready var countries_list: VBoxContainer = $MarginContainer/LayoutContainer/CenterAndRightContainer/RightPanel/CountriesVBox/ScrollContainer/CountriesList
@onready var bonus_panel: PanelContainer = $MarginContainer/LayoutContainer/LeftPanel/BonusPanel
@onready var bonus_container: VBoxContainer = $MarginContainer/LayoutContainer/LeftPanel/BonusPanel/BonusVBox/BonusEffectsList
@onready var malus_panel: PanelContainer = $MarginContainer/LayoutContainer/LeftPanel/MalusPanel
@onready var malus_container: VBoxContainer = $MarginContainer/LayoutContainer/LeftPanel/MalusPanel/MalusVBox/MalusEffectsList
@onready var xp_progress_bar: ProgressBar = $MarginContainer/XPBarContainer/XPPanel/XPHBox/XPProgressBar
@onready var xp_panel: PanelContainer = $MarginContainer/XPBarContainer/XPPanel

# Dart icon references for updating
var dart_icons: Array[TextureRect] = []

# Reference to CountryNames for displaying full country names
const CountryNames = preload("res://CountryNames.gd")

# XP bar animation state
var shimmer_time: float = 0.0
var shimmer_speed: float = 1.5
var pulse_time: float = 0.0
var pulse_speed: float = 2.0


func _ready() -> void:
	# Setup dart counter
	_setup_dart_counter()

	# Ensure XP panel scales from its center
	xp_panel.pivot_offset = xp_panel.size / 2.0
	xp_panel.resized.connect(_on_xp_panel_resized)

	# Connect to GameState signals
	GameState.country_collected.connect(_on_country_collected)
	GameState.darts_changed.connect(_on_darts_changed)
	GameState.card_acquired.connect(_on_card_acquired)

	# Initialize countries list with any already collected countries
	for country_id in GameState.collected_countries:
		_add_country_to_list(country_id)

	# Initialize bonus/malus displays
	_update_card_displays()

	# Setup XP bar animations
	_setup_xp_bar()


func _process(delta: float) -> void:
	# Animate the shimmer effect on the XP bar
	_animate_xp_shimmer(delta)


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

	# Collect all bonuses and maluses from all cards
	var all_bonuses: Array[String] = []
	var all_maluses: Array[String] = []

	for card in acquired_cards:
		var bonuses: Array = card.get("bonuses", [])
		var maluses: Array = card.get("maluses", [])

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


# ============================================================================
# XP BAR FUNCTIONS
# ============================================================================

func _setup_xp_bar() -> void:
	"""Initialize the XP bar with starting animations"""
	# Start with a subtle pulse animation
	_start_xp_pulse_animation()


func _animate_xp_shimmer(delta: float) -> void:
	"""Animate a shimmer/glow effect on the XP bar"""
	shimmer_time += delta * shimmer_speed

	# Create a subtle brightness modulation using sine wave
	var shimmer_intensity: float = (sin(shimmer_time) + 1.0) / 2.0  # 0.0 to 1.0
	var shimmer_color: Color = Color(1.0, 0.85, 0.3, 0.2 + shimmer_intensity * 0.15)

	# Apply shimmer to the progress bar's fill style
	var fill_style: StyleBoxFlat = xp_progress_bar.get_theme_stylebox("fill")
	if fill_style:
		fill_style.shadow_color = shimmer_color


func _start_xp_pulse_animation() -> void:
	"""Start a subtle pulsing animation on the XP panel"""
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(xp_panel, "modulate:a", 0.95, 1.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(xp_panel, "modulate:a", 1.0, 1.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


func animate_xp_gain(new_value: float) -> void:
	"""Animate the XP bar filling to a new value
	Call this function when XP increases (not connected to game logic yet)"""
	# Smooth fill animation
	var tween := create_tween()
	tween.tween_property(xp_progress_bar, "value", new_value, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	# Add a flash effect during the fill
	tween.parallel().tween_property(xp_panel, "modulate", Color(1.2, 1.1, 1.0, 1.0), 0.2)
	tween.tween_property(xp_panel, "modulate", Color.WHITE, 0.3)


func animate_xp_level_up() -> void:
	"""Celebration animation when XP bar reaches 100%
	Call this function when player levels up (not connected to game logic yet)"""

	# Flash effect
	var flash_tween := create_tween()
	flash_tween.tween_property(xp_panel, "modulate", Color(1.5, 1.3, 1.0, 1.0), 0.1)
	flash_tween.tween_property(xp_panel, "modulate", Color.WHITE, 0.1)
	flash_tween.tween_property(xp_panel, "modulate", Color(1.3, 1.2, 1.0, 1.0), 0.1)
	flash_tween.tween_property(xp_panel, "modulate", Color.WHITE, 0.2)

	# Scale bounce effect
	var bounce_tween := create_tween()
	bounce_tween.tween_property(xp_panel, "scale", Vector2(1.05, 1.05), 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	bounce_tween.tween_property(xp_panel, "scale", Vector2.ONE, 0.3).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_ELASTIC)

	# Glow pulse
	var glow_tween := create_tween()
	for i in range(3):
		glow_tween.tween_property(xp_progress_bar, "modulate", Color(1.3, 1.2, 1.0, 1.0), 0.2)
		glow_tween.tween_property(xp_progress_bar, "modulate", Color.WHITE, 0.2)

func _on_xp_panel_resized() -> void:
	# Keep pivot at center so scale animations bounce from the middle
	xp_panel.pivot_offset = xp_panel.size / 2.0


