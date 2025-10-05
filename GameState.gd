extends Node

const CountryNames = preload("res://CountryNames.gd")
const PowerUpDefinitions = preload("res://PowerUpDefinitions.gd")

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
signal rotation_speed_changed(multiplier: float)
signal globe_scale_changed(multiplier: float)
signal zoom_bonus_acquired(zoom_level: int)

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

# Zoom tracking
var current_zoom_level: int = 0  # Net zoom level: positive = zoom bonus, negative = unzoom malus, 0 = neutral
var zoom_bonus_tier: int = 0  # Track highest zoom bonus tier acquired (0-3)
var unzoom_malus_tier: int = 0  # Track highest unzoom malus tier acquired (0-3)

# Loading state
var loading_in_progress: bool = false
var countries_loaded_count: int = 0
var countries_total_count: int = 0

# XP and Level tracking
const XP_PER_LEVEL: int = 100
var xp: int = 0
var level: int = 1

# XP rewards based on country size
const XP_REWARDS = {
	CountryNames.Size.MICROSCOPIC: 300,
	CountryNames.Size.SMALL: 150,
	CountryNames.Size.MEDIUM: 100,
	CountryNames.Size.BIG: 60,
	CountryNames.Size.HUGE: 40
}


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

		# Award XP based on country size
		var country_size = CountryNames.get_country_size(country_id)
		var xp_reward = XP_REWARDS.get(country_size, 100)
		add_xp(xp_reward)

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

	# Apply immediate effects based on card ID
	var card_id = card_data.get("id", "")
	if card_id == "extra_shots":
		remaining_darts += 5
		darts_changed.emit(remaining_darts)
		print("[GameState] Added 5 darts, new count: ", remaining_darts)
	elif card_id.begins_with("slower_map_") or card_id.begins_with("faster_map_"):
		# Update rotation speed when speed-affecting cards are acquired
		var new_multiplier = get_rotation_speed_multiplier()
		rotation_speed_changed.emit(new_multiplier)
		print("[GameState] Rotation speed multiplier updated: ", new_multiplier)
	elif card_id.begins_with("unzoom_"):
		# Update unzoom malus tier
		if card_id == "unzoom_t1":
			unzoom_malus_tier = 1
		elif card_id == "unzoom_t2":
			unzoom_malus_tier = 2
		elif card_id == "unzoom_t3":
			unzoom_malus_tier = 3

		# Recalculate net zoom level (zoom bonus - unzoom malus)
		_update_net_zoom_level()

		# Update globe scale when unzoom maluses are acquired
		var new_multiplier = get_globe_scale_multiplier()
		globe_scale_changed.emit(new_multiplier)
		print("[GameState] Globe scale multiplier updated: ", new_multiplier)
	elif card_id.begins_with("zoom_"):
		# Update zoom bonus tier
		if card_id == "zoom_t1":
			zoom_bonus_tier = 1
		elif card_id == "zoom_t2":
			zoom_bonus_tier = 2
		elif card_id == "zoom_t3":
			zoom_bonus_tier = 3

		# Recalculate net zoom level (zoom bonus - unzoom malus)
		_update_net_zoom_level()

		# Also update globe scale since zoom can cancel out unzoom's effect
		var new_multiplier = get_globe_scale_multiplier()
		globe_scale_changed.emit(new_multiplier)
		print("[GameState] Globe scale multiplier updated: ", new_multiplier)


# Check if a specific card has been acquired
func has_card(card_name: String) -> bool:
	for card in acquired_cards:
		if card.get("name", "") == card_name:
			return true
	return false


# Get all acquired cards
func get_acquired_cards() -> Array[Dictionary]:
	return acquired_cards.duplicate()


# Get the current rotation speed multiplier based on acquired cards
func get_rotation_speed_multiplier() -> float:
	var multiplier := 1.0

	# Check for slower map bonuses (reduce speed)
	if has_card("Slower Map III"):
		multiplier *= 0.5  # 50% reduction
	elif has_card("Slower Map II"):
		multiplier *= 0.7  # 30% reduction
	elif has_card("Slower Map I"):
		multiplier *= 0.85  # 15% reduction

	# Check for faster map maluses (increase speed)
	if has_card("Faster Map III"):
		multiplier *= 1.6  # 60% increase
	elif has_card("Faster Map II"):
		multiplier *= 1.4  # 40% increase
	elif has_card("Faster Map I"):
		multiplier *= 1.2  # 20% increase

	return multiplier


# Get the current globe scale multiplier based on acquired unzoom maluses
func get_globe_scale_multiplier() -> float:
	var multiplier := 1.0

	# Only apply unzoom if it exceeds zoom bonus (net negative zoom)
	# This ensures zoom and unzoom cancel each other out
	var excess_unzoom = unzoom_malus_tier - zoom_bonus_tier

	if excess_unzoom > 0:
		# Apply unzoom scaling based on the excess tiers
		if excess_unzoom >= 3:
			multiplier *= 0.5  # 50% reduction (equivalent to Unzoom III)
		elif excess_unzoom == 2:
			multiplier *= 0.7  # 30% reduction (equivalent to Unzoom II)
		elif excess_unzoom == 1:
			multiplier *= 0.85  # 15% reduction (equivalent to Unzoom I)

	return multiplier


# Update the net zoom level based on zoom bonus and unzoom malus tiers
func _update_net_zoom_level() -> void:
	var old_zoom_level = current_zoom_level

	# Calculate net zoom: zoom bonus tier - unzoom malus tier
	# Result can be -3 to +3
	var net_level = zoom_bonus_tier - unzoom_malus_tier

	# Clamp to valid zoom controller range (0-3)
	# If net is negative or zero, no zoom ability
	# If net is positive, that's the zoom level
	current_zoom_level = max(0, net_level)

	print("[GameState] Zoom calculation: bonus_tier=", zoom_bonus_tier, " - unzoom_tier=", unzoom_malus_tier, " = net=", net_level, " -> zoom_level=", current_zoom_level)

	# Emit signal if zoom level changed
	if current_zoom_level != old_zoom_level:
		zoom_bonus_acquired.emit(current_zoom_level)
		print("[GameState] Zoom level updated to: ", current_zoom_level)


# Generate random card choices for the store
func generate_card_choices(num_choices: int = 2) -> Array[Dictionary]:
	var choices: Array[Dictionary] = []
	for i in range(num_choices):
		var card = PowerUpDefinitions.generate_card(acquired_cards)
		choices.append(card)
	return choices


# Get XP reward for a country based on its size
func get_xp_reward_for_country(country_id: String) -> int:
	var country_size = CountryNames.get_country_size(country_id)
	return XP_REWARDS.get(country_size, 100)


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
