extends Node

# Signals
signal countries_loaded()
signal country_collected(country_id: String)
signal dart_thrown()
signal dart_landed()
signal darts_changed(remaining_darts: int)
signal loading_started(total: int)
signal country_loading_progress(loaded: int, total: int)
signal store_opened()
signal card_acquired(card_data: Dictionary)
signal notification_requested(text: String, position: Vector2, color: Color)
signal xp_changed(current_xp: int, level: int)
signal level_up(new_level: int)

# List of all countries in the game
var all_countries: Array[String] = []

# List of countries the player has collected
var collected_countries: Array[String] = []

# Dictionary mapping country_id to their assigned color
var country_colors: Dictionary = {}

# Pending country from click (will be collected when dart lands)
var pending_country: String = ""

# Last dart landing position (for notifications)
var last_dart_position: Vector2 = Vector2.ZERO

# Dart tracking
const MAX_DARTS: int = 10
var remaining_darts: int = MAX_DARTS

# Card/bonus tracking
var acquired_cards: Array[Dictionary] = []

# Loading state
var loading_in_progress: bool = false
var countries_loaded_count: int = 0
var countries_total_count: int = 0

# XP and Level tracking
const XP_PER_LEVEL: int = 100
var xp: int = 0
var level: int = 1


func _ready() -> void:
	_apply_custom_cursor()

func _apply_custom_cursor() -> void:
	# Prefer cursor.png, fallback to pointer.png if not present
	var candidates := [
		"res://Assets/cursor.png",
		"res://Assets/pointer.png",
	]
	for p in candidates:
		if ResourceLoader.exists(p):
			var tex: Texture2D = load(p)
			if tex:
				# Center the hotspot by default
				var sz = tex.get_size()
				var hotspot := Vector2i(int(sz.x * 0.5), int(sz.y * 0.5))
				Input.set_custom_mouse_cursor(tex, Input.CURSOR_ARROW, hotspot)
				break


# Add a country to the list of all countries
func add_country(country_id: String) -> void:
	if country_id not in all_countries:
		all_countries.append(country_id)


# Register a country with its assigned color
func register_country_color(country_id: String, color: Color) -> void:
	country_colors[country_id] = color


# Get the country ID by its color, or empty string if not found
func get_country_by_color(color: Color, tolerance: float = 0.01) -> String:
	for country_id in country_colors:
		var stored_color = country_colors[country_id]
		if _colors_match(color, stored_color, tolerance):
			return country_id
	return ""


# Helper function to compare colors with tolerance
func _colors_match(c1: Color, c2: Color, tolerance: float) -> bool:
	return abs(c1.r - c2.r) < tolerance and \
		   abs(c1.g - c2.g) < tolerance and \
		   abs(c1.b - c2.b) < tolerance


# Mark a country as collected
func collect_country(country_id: String) -> void:
	if country_id not in collected_countries:
		collected_countries.append(country_id)
		country_collected.emit(country_id)


# Start loading countries
func start_loading(total: int) -> void:
	print("[GameState] start_loading: ", total)
	loading_in_progress = true
	countries_loaded_count = 0
	countries_total_count = total
	loading_started.emit(total)


# Update loading progress
func update_loading_progress(loaded: int) -> void:
	countries_loaded_count = loaded
	country_loading_progress.emit(loaded, countries_total_count)


# Finish loading and notify completion
func finish_loading() -> void:
	print("[GameState] finish_loading")
	loading_in_progress = false
	countries_loaded_count = 0
	countries_total_count = 0
	countries_loaded.emit()


# Set the pending country that was clicked
func set_pending_country(country_id: String) -> void:
	pending_country = country_id


# Signal that the dart has landed
func land_dart(position: Vector2 = Vector2.ZERO) -> void:
	last_dart_position = position
	dart_landed.emit()


# Request a notification to be displayed at a specific position
func show_notification(text: String, position: Vector2, color: Color = Color.WHITE) -> void:
	notification_requested.emit(text, position, color)


# Check if a country has been collected
func is_collected(country_id: String) -> bool:
	return country_id in collected_countries


# Get the number of collected countries
func get_collected_count() -> int:
	return collected_countries.size()


# Get the total number of countries
func get_total_countries() -> int:
	return all_countries.size()


# Throw a dart (decreases remaining darts)
func throw_dart() -> void:
	if remaining_darts > 0:
		remaining_darts -= 1
		dart_thrown.emit()
		darts_changed.emit(remaining_darts)


# Get remaining darts count
func get_remaining_darts() -> int:
	return remaining_darts


# Check if player has darts remaining
func has_darts() -> bool:
	return remaining_darts > 0


# Reset the game state
func reset() -> void:
	collected_countries.clear()
	remaining_darts = MAX_DARTS
	acquired_cards.clear()
	darts_changed.emit(remaining_darts)


# Open the store overlay
func open_store() -> void:
	store_opened.emit()


# Acquire a card and apply its effects
func acquire_card(card_data: Dictionary) -> void:
	acquired_cards.append(card_data)
	card_acquired.emit(card_data)
	print("[GameState] Card acquired: ", card_data.get("name", "Unknown"))


# Check if a specific card has been acquired
func has_card(card_name: String) -> bool:
	for card in acquired_cards:
		if card.get("name", "") == card_name:
			return true
	return false


# Get all acquired cards
func get_acquired_cards() -> Array[Dictionary]:
	return acquired_cards.duplicate()


# Add experience points and handle level ups
func add_xp(amount: int) -> void:
	xp += amount

	# Handle level ups with overflow
	while xp >= XP_PER_LEVEL:
		xp -= XP_PER_LEVEL
		level += 1
		level_up.emit(level)
		print("[GameState] Level up! New level: ", level)

	# Emit XP change signal
	xp_changed.emit(xp, level)
	print("[GameState] XP: ", xp, " / ", XP_PER_LEVEL, " | Level: ", level)
