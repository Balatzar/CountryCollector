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
signal vertical_drift_changed(amplitude: float)
signal direction_chaos_changed(frequency: float)
signal time_freeze_changed(tier: int, shots_until_ready: int, available: bool)
signal game_over()
signal streak_started(streak_count: int)
signal streak_ended(final_count: int)

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
var darts_thrown: int = 0  # Track total darts thrown throughout the game

# Card/bonus tracking
var acquired_cards: Array[Dictionary] = []

# Zoom tracking
var current_zoom_level: int = 0  # Net zoom level: positive = zoom bonus, negative = unzoom malus, 0 = neutral
var zoom_bonus_tier: int = 0  # Track highest zoom bonus tier acquired (0-5)
var unzoom_malus_tier: int = 0  # Track highest unzoom malus tier acquired (0-5)

# Vertical drift tracking
var vertical_drift_tier: int = 0  # Track highest vertical movement malus tier (0-5)

# Direction chaos tracking
var direction_chaos_tier: int = 0  # Track highest direction chaos malus tier (0-5)

# Extra XP bonus tracking
var extra_xp_bonus_tier: int = 0  # Track highest extra XP bonus tier (0-5)

# Dart refund tracking
var has_dart_refund: bool = false  # Track if dart refund power-up is acquired

# Time freeze tracking
var time_freeze_tier: int = 0  # Track highest time freeze bonus tier (0-5)
var time_freeze_available: bool = false  # Track if power is ready to use
var time_freeze_shots_until_ready: int = 0  # Counter for shots remaining until ready
var is_time_frozen: bool = false  # Track if time is currently frozen

# Streak tracking
const STREAK_THRESHOLD: int = 3  # Number of consecutive hits needed to activate streak
var current_streak: int = 0  # Current consecutive hit count
var is_on_streak: bool = false  # Whether streak mode is active

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
	CountryNames.Size.MICROSCOPIC: 200,
	CountryNames.Size.SMALL: 100,
	CountryNames.Size.MEDIUM: 80,
	CountryNames.Size.BIG: 50,
	CountryNames.Size.HUGE: 20
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

		# Add extra XP bonus if acquired
		var extra_xp = get_extra_xp_bonus()
		xp_reward += extra_xp

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
		darts_thrown += 1
		dart_thrown.emit()
		darts_changed.emit(remaining_darts)

		# Update time freeze cooldown if power-up is acquired
		if time_freeze_tier > 0 and not time_freeze_available:
			time_freeze_shots_until_ready -= 1
			if time_freeze_shots_until_ready <= 0:
				time_freeze_available = true
				time_freeze_shots_until_ready = 0
				print("[GameState] Time freeze ready!")
			time_freeze_changed.emit(time_freeze_tier, time_freeze_shots_until_ready, time_freeze_available)

		# Check for game over
		if remaining_darts == 0:
			game_over.emit()


# Get remaining darts count
func get_remaining_darts() -> int:
	return remaining_darts


# Get total darts thrown
func get_darts_thrown() -> int:
	return darts_thrown


# Check if player has darts remaining
func has_darts() -> bool:
	return remaining_darts > 0


# Refund a dart (used when hitting already-collected countries with dart refund power-up)
func refund_dart() -> void:
	remaining_darts += 1
	darts_changed.emit(remaining_darts)
	print("[GameState] Dart refunded. New count: ", remaining_darts)


# Reset the game state
func reset() -> void:
	collected_countries.clear()
	remaining_darts = MAX_DARTS
	darts_thrown = 0
	acquired_cards.clear()
	xp = 0
	level = 1
	zoom_bonus_tier = 0
	unzoom_malus_tier = 0
	current_zoom_level = 0
	vertical_drift_tier = 0
	direction_chaos_tier = 0
	extra_xp_bonus_tier = 0
	has_dart_refund = false
	time_freeze_tier = 0
	time_freeze_available = false
	time_freeze_shots_until_ready = 0
	is_time_frozen = false
	current_streak = 0
	is_on_streak = false
	darts_changed.emit(remaining_darts)
	xp_changed.emit(xp, level)


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
	if card_id.begins_with("slower_map_") or card_id.begins_with("faster_map_"):
		# Update rotation speed when speed-affecting cards are acquired
		var new_multiplier = get_rotation_speed_multiplier()
		rotation_speed_changed.emit(new_multiplier)
		print("[GameState] Rotation speed multiplier updated: ", new_multiplier)
	elif card_id.begins_with("vertical_movement_"):
		# Update vertical drift tier (keep highest acquired)
		if card_id == "vertical_movement_t1":
			vertical_drift_tier = max(vertical_drift_tier, 1)
		elif card_id == "vertical_movement_t2":
			vertical_drift_tier = max(vertical_drift_tier, 2)
		elif card_id == "vertical_movement_t3":
			vertical_drift_tier = max(vertical_drift_tier, 3)
		elif card_id == "vertical_movement_t4":
			vertical_drift_tier = max(vertical_drift_tier, 4)
		elif card_id == "vertical_movement_t5":
			vertical_drift_tier = max(vertical_drift_tier, 5)

		# Emit signal with new drift amplitude
		var amplitude = get_vertical_drift_amplitude()
		vertical_drift_changed.emit(amplitude)
		print("[GameState] Vertical drift amplitude updated: ", amplitude)
	elif card_id.begins_with("direction_chaos_"):
		# Update direction chaos tier (keep highest acquired)
		if card_id == "direction_chaos_t1":
			direction_chaos_tier = max(direction_chaos_tier, 1)
		elif card_id == "direction_chaos_t2":
			direction_chaos_tier = max(direction_chaos_tier, 2)
		elif card_id == "direction_chaos_t3":
			direction_chaos_tier = max(direction_chaos_tier, 3)
		elif card_id == "direction_chaos_t4":
			direction_chaos_tier = max(direction_chaos_tier, 4)
		elif card_id == "direction_chaos_t5":
			direction_chaos_tier = max(direction_chaos_tier, 5)

		# Emit signal with new chaos frequency
		var frequency = get_direction_chaos_frequency()
		direction_chaos_changed.emit(frequency)
		print("[GameState] Direction chaos updated: frequency=", frequency)
	elif card_id.begins_with("unzoom_"):
		# Update unzoom malus tier (keep highest acquired)
		if card_id == "unzoom_t1":
			unzoom_malus_tier = max(unzoom_malus_tier, 1)
		elif card_id == "unzoom_t2":
			unzoom_malus_tier = max(unzoom_malus_tier, 2)
		elif card_id == "unzoom_t3":
			unzoom_malus_tier = max(unzoom_malus_tier, 3)
		elif card_id == "unzoom_t4":
			unzoom_malus_tier = max(unzoom_malus_tier, 4)
		elif card_id == "unzoom_t5":
			unzoom_malus_tier = max(unzoom_malus_tier, 5)

		# Recalculate net zoom level (zoom bonus - unzoom malus)
		_update_net_zoom_level()

		# Update globe scale when unzoom maluses are acquired
		var new_multiplier = get_globe_scale_multiplier()
		globe_scale_changed.emit(new_multiplier)
		print("[GameState] Globe scale multiplier updated: ", new_multiplier)
	elif card_id.begins_with("zoom_"):
		# Update zoom bonus tier (keep highest acquired)
		if card_id == "zoom_t1":
			zoom_bonus_tier = max(zoom_bonus_tier, 1)
		elif card_id == "zoom_t2":
			zoom_bonus_tier = max(zoom_bonus_tier, 2)
		elif card_id == "zoom_t3":
			zoom_bonus_tier = max(zoom_bonus_tier, 3)
		elif card_id == "zoom_t4":
			zoom_bonus_tier = max(zoom_bonus_tier, 4)
		elif card_id == "zoom_t5":
			zoom_bonus_tier = max(zoom_bonus_tier, 5)

		# Recalculate net zoom level (zoom bonus - unzoom malus)
		_update_net_zoom_level()

		# Also update globe scale since zoom can cancel out unzoom's effect
		var new_multiplier = get_globe_scale_multiplier()
		globe_scale_changed.emit(new_multiplier)
		print("[GameState] Globe scale multiplier updated: ", new_multiplier)
	elif card_id.begins_with("extra_xp_"):
		# Update extra XP bonus tier (keep highest acquired)
		if card_id == "extra_xp_t1":
			extra_xp_bonus_tier = max(extra_xp_bonus_tier, 1)
		elif card_id == "extra_xp_t2":
			extra_xp_bonus_tier = max(extra_xp_bonus_tier, 2)
		elif card_id == "extra_xp_t3":
			extra_xp_bonus_tier = max(extra_xp_bonus_tier, 3)
		elif card_id == "extra_xp_t4":
			extra_xp_bonus_tier = max(extra_xp_bonus_tier, 4)
		elif card_id == "extra_xp_t5":
			extra_xp_bonus_tier = max(extra_xp_bonus_tier, 5)
		print("[GameState] Extra XP bonus tier updated: ", extra_xp_bonus_tier)
	elif card_id == "dart_refund":
		# Enable dart refund
		has_dart_refund = true
		print("[GameState] Dart refund enabled")
	elif card_id.begins_with("time_freeze_"):
		# Update time freeze tier (keep highest acquired)
		if card_id == "time_freeze_t1":
			time_freeze_tier = max(time_freeze_tier, 1)
		elif card_id == "time_freeze_t2":
			time_freeze_tier = max(time_freeze_tier, 2)
		elif card_id == "time_freeze_t3":
			time_freeze_tier = max(time_freeze_tier, 3)
		elif card_id == "time_freeze_t4":
			time_freeze_tier = max(time_freeze_tier, 4)
		elif card_id == "time_freeze_t5":
			time_freeze_tier = max(time_freeze_tier, 5)

		# Initialize cooldown and make it available immediately for first acquisition
		time_freeze_available = true
		time_freeze_shots_until_ready = 0

		# Emit signal to update UI
		time_freeze_changed.emit(time_freeze_tier, time_freeze_shots_until_ready, time_freeze_available)
		print("[GameState] Time freeze tier updated: ", time_freeze_tier, " (cooldown: ", get_time_freeze_cooldown(), " shots)")


# Check if a specific card has been acquired
func has_card(card_name: String) -> bool:
	for card in acquired_cards:
		if card.get("name", "") == card_name:
			return true
	return false


# Get all acquired cards
func get_acquired_cards() -> Array[Dictionary]:
	return acquired_cards.duplicate()



# Return highest-tier active power-ups per family, split by type
func get_active_powerups_by_family() -> Dictionary:
	var best := {}
	for p in acquired_cards:
		if not (p.has("family") and p.has("tier")):
			continue
		var fam := String(p["family"])
		var current_best = best.get(fam, null)
		if current_best == null or int(p.get("tier", 0)) > int(current_best.get("tier", 0)):
			best[fam] = p
	var out := {"bonuses": [], "maluses": []}
	for v in best.values():
		var t := int(v.get("type", 0))
		if t == PowerUpDefinitions.PowerUpType.BONUS:
			out["bonuses"].append(v)
		else:
			out["maluses"].append(v)
	return out

# Get the current rotation speed multiplier based on acquired cards
func get_rotation_speed_multiplier() -> float:
	var slow_multiplier := 1.0
	var fast_multiplier := 1.0

	# Check for slower map bonuses (reduce speed) - inverse of faster map values
	if has_card("Slower Map V"):
		slow_multiplier = 0.5  # 50% reduction (inverse of 2.0x)
	elif has_card("Slower Map IV"):
		slow_multiplier = 0.556  # ~44% reduction (inverse of 1.8x)
	elif has_card("Slower Map III"):
		slow_multiplier = 0.625  # 37.5% reduction (inverse of 1.6x)
	elif has_card("Slower Map II"):
		slow_multiplier = 0.714  # ~29% reduction (inverse of 1.4x)
	elif has_card("Slower Map I"):
		slow_multiplier = 0.833  # ~17% reduction (inverse of 1.2x)

	# Check for faster map maluses (increase speed)
	if has_card("Faster Map V"):
		fast_multiplier = 2.0  # 100% increase
	elif has_card("Faster Map IV"):
		fast_multiplier = 1.8  # 80% increase
	elif has_card("Faster Map III"):
		fast_multiplier = 1.6  # 60% increase
	elif has_card("Faster Map II"):
		fast_multiplier = 1.4  # 40% increase
	elif has_card("Faster Map I"):
		fast_multiplier = 1.2  # 20% increase

	# Combine: multiply them together so they perfectly cancel when equal tiers
	return slow_multiplier * fast_multiplier


# Get the current globe scale multiplier based on acquired unzoom maluses
func get_globe_scale_multiplier() -> float:
	var multiplier := 1.0

	# Only apply unzoom if it exceeds zoom bonus (net negative zoom)
	# This ensures zoom and unzoom cancel each other out
	var excess_unzoom = unzoom_malus_tier - zoom_bonus_tier

	if excess_unzoom > 0:
		# Apply unzoom scaling based on the excess tiers
		if excess_unzoom >= 5:
			multiplier *= 0.2  # 80% reduction (equivalent to Unzoom V)
		elif excess_unzoom == 4:
			multiplier *= 0.35  # 65% reduction (equivalent to Unzoom IV)
		elif excess_unzoom == 3:
			multiplier *= 0.5  # 50% reduction (equivalent to Unzoom III)
		elif excess_unzoom == 2:
			multiplier *= 0.7  # 30% reduction (equivalent to Unzoom II)
		elif excess_unzoom == 1:
			multiplier *= 0.85  # 15% reduction (equivalent to Unzoom I)

	return multiplier


# Get the current vertical drift amplitude based on acquired maluses
func get_vertical_drift_amplitude() -> float:
	match vertical_drift_tier:
		1:
			return 20.0  # ±20px
		2:
			return 40.0  # ±40px
		3:
			return 60.0  # ±60px
		4:
			return 80.0  # ±80px
		5:
			return 100.0  # ±100px
		_:
			return 0.0  # No drift


func get_direction_chaos_frequency() -> float:
	"""Returns average frequency (changes per second) for map rotation direction chaos based on tier
	The map will randomly flip rotation direction (clockwise <-> counterclockwise)
	The actual timing is randomized to be unpredictable"""
	match direction_chaos_tier:
		1:
			return 0.067  # Average: Flip direction every ~15 seconds (range 10-20s)
		2:
			return 0.11  # Average: Flip direction every ~9 seconds (range 6-12s)
		3:
			return 0.167  # Average: Flip direction every ~6 seconds (range 4-8s)
		4:
			return 0.25  # Average: Flip direction every ~4 seconds (range 2.7-5.3s)
		5:
			return 0.125  # Average: Flip direction every ~8 seconds (range 6-10s)
		_:
			return 0.0  # No chaos


# Get the extra XP bonus per successful hit based on acquired bonuses
func get_extra_xp_bonus() -> int:
	match extra_xp_bonus_tier:
		1:
			return 5
		2:
			return 10
		3:
			return 15
		4:
			return 20
		5:
			return 25
		_:
			return 0


# Get the time freeze cooldown (shots needed) based on tier
func get_time_freeze_cooldown() -> int:
	match time_freeze_tier:
		1:
			return 10
		2:
			return 9
		3:
			return 8
		4:
			return 7
		5:
			return 6
		_:
			return 0


# Use the time freeze ability
func use_time_freeze() -> void:
	if not time_freeze_available or time_freeze_tier == 0:
		return

	is_time_frozen = true
	time_freeze_available = false
	time_freeze_shots_until_ready = get_time_freeze_cooldown()

	# Emit signal to update UI
	time_freeze_changed.emit(time_freeze_tier, time_freeze_shots_until_ready, time_freeze_available)
	print("[GameState] Time freeze activated! Next available in ", time_freeze_shots_until_ready, " shots")


# Unfreeze time (called when dart lands)
func unfreeze_time() -> void:
	if is_time_frozen:
		is_time_frozen = false
		print("[GameState] Time unfrozen")


# Update the net zoom level based on zoom bonus and unzoom malus tiers
func _update_net_zoom_level() -> void:
	var old_zoom_level = current_zoom_level

	# Calculate net zoom: zoom bonus tier - unzoom malus tier
	# Result can be -5 to +5
	var net_level = zoom_bonus_tier - unzoom_malus_tier

	# Clamp to valid zoom controller range (0-5)
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

		# Award 3 darts on every level up
		remaining_darts += 3
		darts_changed.emit(remaining_darts)
		print("[GameState] Level up! New level: ", level, " - Awarded 3 darts, new count: ", remaining_darts)

		level_up.emit(level)

	# Emit XP change signal
	xp_changed.emit(xp, level)
	print("[GameState] XP: ", xp, " / ", XP_PER_LEVEL, " | Level: ", level)
