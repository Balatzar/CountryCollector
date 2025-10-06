extends Node2D

const CountryNames = preload("res://CountryNames.gd")

## Configuration
@export var base_scroll_speed: float = 150.0  # Base pixels per second
var scroll_speed: float  # Current scroll speed (base * multiplier)

# Base scale for the globe display
var base_globe_scale: Vector2 = Vector2.ONE

# Vertical drift parameters
var vertical_drift_amplitude: float = 0.0  # Amplitude of vertical oscillation (0 = disabled)
var vertical_drift_time: float = 0.0  # Time accumulator for sine wave
const VERTICAL_DRIFT_FREQUENCY: float = 0.5  # Oscillations per second (higher = faster)

# Direction chaos parameters
var direction_chaos_frequency: float = 0.0  # How often to change direction (changes per second)
var direction_chaos_next_change_time: float = 0.0  # When next direction change occurs
var direction_multiplier: int = 1  # 1 for normal, -1 for reversed

## Node references
@onready var sub_viewport: SubViewport = $SubViewport
@onready var world_scroller: Node2D = $SubViewport/WorldScroller
@onready var static_map: Node2D = $SubViewport/WorldScroller/StaticClickableMap
@onready var globe_display: TextureRect = $GlobeDisplay

## Internal state
var scroll_offset: float = 0.0
var map_width: float = 1024.0  # Width of the PNG images
var map_copy: Node2D = null
var copies_created: bool = false
var is_paused: bool = true  # Start paused until loading is complete

# Track if current dart hit a country (reset on each throw)
var dart_hit_country: bool = false

# Notification colors
const COLOR_HIT = Color.LIGHT_GREEN
const COLOR_MISS = Color.ORANGE
const COLOR_COUNTRY = Color.CYAN
const COLOR_FUN = Color.YELLOW
const COLOR_XP = Color.GOLD
const COLOR_STREAK = Color(1.0, 0.6, 0.0)  # Bright orange/gold for streak

# Fun notification messages
const FUN_SUCCESS_MESSAGES = [
	"WOW!",
	"Impressive!",
	"Amazing!",
	"Spectacular!",
	"Fantastic!",
	"Brilliant!",
	"Incredible!",
	"Awesome!",
	"Nice shot!",
	"Perfect!"
]

const FUN_FAIL_MESSAGES = [
	"Oh no!",
	"Damn!",
	"Oops!",
	"So close!",
	"Missed!",
	"Not quite!",
	"Try again!",
	"Unlucky!",
	"Oof!",
	"Almost!"
]

func _ready() -> void:
	# Scale the map to fit better in the globe (maps are 1024x512)
	# Scale to 0.8 so it fits nicely with some margin
	world_scroller.scale = Vector2(0.8, 0.8)

	# Center the scaled map in the 1024x1024 viewport
	# After scaling, the map is 819.2 x 409.6
	var scaled_width = map_width * world_scroller.scale.x
	var scaled_height = 512.0 * world_scroller.scale.y
	world_scroller.position = Vector2(
		(1024 - scaled_width) / 2.0,
		(1024 - scaled_height) / 2.0
	)

	# Set the viewport texture on the globe display
	globe_display.texture = sub_viewport.get_texture()

	# Store the base scale of the globe display
	base_globe_scale = globe_display.scale

	# Connect to game signals
	GameState.dart_thrown.connect(_on_dart_thrown)
	GameState.dart_landed.connect(_on_dart_landed)
	GameState.country_collected.connect(_on_country_collected)
	GameState.rotation_speed_changed.connect(_on_rotation_speed_changed)
	GameState.globe_scale_changed.connect(_on_globe_scale_changed)
	GameState.vertical_drift_changed.connect(_on_vertical_drift_changed)
	GameState.direction_chaos_changed.connect(_on_direction_chaos_changed)
	GameState.time_freeze_changed.connect(_on_time_freeze_changed)

	# Initialize scroll speed, globe scale, vertical drift, and direction chaos with current values
	_update_scroll_speed()
	_update_globe_scale()
	_update_vertical_drift()
	_update_direction_chaos()

func start_rotation() -> void:
	"""Called externally when loading is complete and it's safe to copy sprites"""
	if not copies_created:
		_create_map_copy()
	is_paused = false
	print("[RotatingMap] Rotation started")

func _on_dart_thrown() -> void:
	# Reset hit tracking for new dart
	dart_hit_country = false


func _on_dart_landed() -> void:
	# Unfreeze time when dart lands
	GameState.unfreeze_time()

	# Skip streak logic during multishot
	var is_multishot = GameState.is_multishot_active

	# Collect the pending country when dart lands
	if GameState.pending_country != "":
		# Check if the country is already collected (for dart refund)
		var was_already_collected = GameState.is_collected(GameState.pending_country)
		var country_id = GameState.pending_country

		print("[DEBUG] Dart landed on country: ", country_id)
		print("[DEBUG] Was already collected: ", was_already_collected)
		print("[DEBUG] Has dart refund power-up: ", GameState.has_dart_refund)

		GameState.collect_country(country_id)
		GameState.pending_country = ""

		# Update streak: increment on successful hit (but not during multishot)
		if not is_multishot:
			GameState.current_streak += 1
			print("[STREAK] Hit! Current streak: ", GameState.current_streak)

		# Check if we just activated streak mode (but not during multishot)
		if not is_multishot:
			if not GameState.is_on_streak and GameState.current_streak >= GameState.STREAK_THRESHOLD:
				GameState.is_on_streak = true
				GameState.streak_started.emit(GameState.current_streak)
				print("[STREAK] Streak activated at ", GameState.current_streak, " hits!")

				# Show dramatic streak activation notification
				await get_tree().create_timer(0.6).timeout  # Wait a bit for effect
				GameState.show_notification("🔥 STREAK ACTIVATED! 🔥", GameState.last_dart_position, COLOR_STREAK)
			elif GameState.is_on_streak:
				# Already on streak: refund 1 dart for successful hit
				GameState.refund_dart()
				print("[STREAK] Hit during streak! Dart refunded. New count: ", GameState.get_remaining_darts())

				# Show dart refund notification during streak
				await get_tree().create_timer(0.6).timeout
				GameState.show_notification("+1 DART (Streak Bonus!)", GameState.last_dart_position, COLOR_STREAK)

		# If dart refund is active and country was already collected, refund the dart
		if was_already_collected and GameState.has_dart_refund:
			print("[DEBUG] Refunding dart!")
			# Mark that this dart hit a country (even if already collected)
			dart_hit_country = true

			GameState.refund_dart()

			# Show notifications for already-collected country
			GameState.show_notification("Already collected!", GameState.last_dart_position, COLOR_COUNTRY)
			await get_tree().create_timer(0.2).timeout
			GameState.show_notification("Reimbursed!", GameState.last_dart_position, COLOR_HIT)
	else:
		# Miss: break streak if active (but not during multishot)
		if not is_multishot:
			if GameState.is_on_streak:
				var final_streak = GameState.current_streak
				GameState.is_on_streak = false
				GameState.current_streak = 0
				GameState.streak_ended.emit(final_streak)
				print("[STREAK] Streak ended at ", final_streak, " hits")

				# Show streak end notification
				GameState.show_notification("STREAK ENDED! (" + str(final_streak) + " hits)", GameState.last_dart_position, COLOR_STREAK)
				await get_tree().create_timer(0.2).timeout
			else:
				# Reset streak counter on miss (even if not in streak mode yet)
				GameState.current_streak = 0
				print("[STREAK] Miss! Streak reset to 0")

		# Show miss notification if we didn't hit a country
		if not dart_hit_country:
			# Play miss sound
			AudioManager.play_miss()

			GameState.show_notification("Miss!", GameState.last_dart_position, COLOR_MISS)
			# Show fun fail message after 100ms
			await get_tree().create_timer(0.1).timeout
			var fun_msg = FUN_FAIL_MESSAGES[randi() % FUN_FAIL_MESSAGES.size()]
			GameState.show_notification(fun_msg, GameState.last_dart_position, COLOR_FUN)


func _on_country_collected(country_id: String) -> void:
	# Mark that this dart hit a country
	dart_hit_country = true

	# Rebuild map copies to reflect the new white color
	if copies_created and map_copy != null:
		_rebuild_map_copy()

	# Show hit notification at dart landing position
	GameState.show_notification("Hit!", GameState.last_dart_position, COLOR_HIT)

	# Wait 100ms before showing country name
	await get_tree().create_timer(0.1).timeout

	# Get the country name and show it
	var country_name := CountryNames.get_country_name(country_id)
	GameState.show_notification(country_name, GameState.last_dart_position, COLOR_COUNTRY)

	# Wait another 100ms before showing country size
	await get_tree().create_timer(0.1).timeout
	var country_size := CountryNames.get_country_size(country_id)
	var size_text := _get_size_text(country_size)
	GameState.show_notification("You hit a " + size_text + " country!", GameState.last_dart_position, COLOR_COUNTRY)

	# Wait another 100ms before showing XP reward
	await get_tree().create_timer(0.1).timeout
	var xp_reward := GameState.get_xp_reward_for_country(country_id)
	var extra_xp := GameState.get_extra_xp_bonus()
	var total_xp := xp_reward + extra_xp
	GameState.show_notification("+" + str(total_xp) + " XP", GameState.last_dart_position, COLOR_XP)

	# Wait another 100ms before showing fun success message
	await get_tree().create_timer(0.1).timeout
	var fun_msg = FUN_SUCCESS_MESSAGES[randi() % FUN_SUCCESS_MESSAGES.size()]
	GameState.show_notification(fun_msg, GameState.last_dart_position, COLOR_FUN)


func _get_size_text(size: CountryNames.Size) -> String:
	match size:
		CountryNames.Size.MICROSCOPIC:
			return "Microscopic"
		CountryNames.Size.SMALL:
			return "Small"
		CountryNames.Size.MEDIUM:
			return "Medium"
		CountryNames.Size.BIG:
			return "Big"
		CountryNames.Size.HUGE:
			return "Huge"
		_:
			return "Unknown"

func _create_map_copy() -> void:
	if copies_created:
		return

	print("[RotatingMap] Creating map copy...")
	print("[RotatingMap] StaticMap has ", static_map.get_child_count(), " children")

	# Create a duplicate container for seamless wrapping
	map_copy = Node2D.new()
	world_scroller.add_child(map_copy)
	map_copy.position = Vector2(map_width, 0)

	var sprite_count = 0
	# Copy all sprites from the static map (visual only, no collision)
	for child in static_map.get_children():
		if child is Sprite2D:
			if child.texture == null:
				print("[RotatingMap] WARNING: Sprite has null texture: ", child.name)
				continue
			var sprite_copy = Sprite2D.new()
			sprite_copy.texture = child.texture
			sprite_copy.centered = child.centered
			sprite_copy.position = child.position
			sprite_copy.scale = child.scale
			sprite_copy.rotation = child.rotation
			sprite_copy.modulate = child.modulate
			# Don't copy Area2D or collision - purely visual
			map_copy.add_child(sprite_copy)
			sprite_count += 1

	print("[RotatingMap] Created ", sprite_count, " sprite copies")
	copies_created = true

func _rebuild_map_copy() -> void:
	"""Rebuild the map copy to reflect updated textures (e.g., collected countries)"""
	if map_copy == null:
		return

	# Remove all existing copied sprites
	for child in map_copy.get_children():
		child.queue_free()

	# Recreate them with current textures
	var sprite_count = 0
	for child in static_map.get_children():
		if child is Sprite2D:
			if child.texture == null:
				continue
			var sprite_copy = Sprite2D.new()
			sprite_copy.texture = child.texture
			sprite_copy.centered = child.centered
			sprite_copy.position = child.position
			sprite_copy.scale = child.scale
			sprite_copy.rotation = child.rotation
			sprite_copy.modulate = child.modulate
			map_copy.add_child(sprite_copy)
			sprite_count += 1

	print("[RotatingMap] Rebuilt ", sprite_count, " sprite copies")

func _process(delta: float) -> void:
	# Don't update if paused or time is frozen
	if is_paused or GameState.is_time_frozen:
		return

	# Handle direction chaos - randomly flip rotation direction
	if direction_chaos_frequency > 0.0:
		direction_chaos_next_change_time -= delta
		if direction_chaos_next_change_time <= 0.0:
			# Flip direction
			direction_multiplier *= -1
			# Schedule next change with randomization (0.5x to 2.0x the average interval)
			# This creates very irregular timing so you can't predict when the direction will change
			var base_interval = 1.0 / direction_chaos_frequency
			var random_multiplier = randf_range(0.5, 2.0)
			direction_chaos_next_change_time = base_interval * random_multiplier
			print("[RotatingMap] Direction chaos! Flipped direction, multiplier now: ", direction_multiplier, " next change in: ", direction_chaos_next_change_time, "s")

	# Update scroll offset (in unscaled space)
	scroll_offset += scroll_speed * direction_multiplier * delta

	# Wrap offset to stay within one map width (handle negative values)
	scroll_offset = fmod(scroll_offset, map_width)
	if scroll_offset < 0:
		scroll_offset += map_width

	# Update vertical drift time
	if vertical_drift_amplitude > 0.0:
		vertical_drift_time += delta

	# Move the scroller left to simulate rotation
	# Account for the scale and maintain the centering
	var scaled_width = map_width * world_scroller.scale.x
	var scaled_height = 512.0 * world_scroller.scale.y
	var base_x = (1024 - scaled_width) / 2.0
	var base_y = (1024 - scaled_height) / 2.0

	world_scroller.position.x = base_x - (scroll_offset * world_scroller.scale.x)

	# Apply vertical drift using sine wave
	if vertical_drift_amplitude > 0.0:
		var drift_offset = sin(vertical_drift_time * VERTICAL_DRIFT_FREQUENCY * TAU) * vertical_drift_amplitude
		world_scroller.position.y = base_y + drift_offset
	else:
		world_scroller.position.y = base_y

func _sample_colors_in_radius(img: Image, center: Vector2i, radius: int) -> Array[Color]:
	"""Sample colors in a circular pattern around a center point"""
	var colors: Array[Color] = []
	var img_width = img.get_width()
	var img_height = img.get_height()

	# Sample in a circle around the center point
	for y in range(-radius, radius + 1):
		for x in range(-radius, radius + 1):
			# Check if point is within circle
			if x * x + y * y <= radius * radius:
				var px = center + Vector2i(x, y)
				# Check bounds
				if px.x >= 0 and px.y >= 0 and px.x < img_width and px.y < img_height:
					colors.append(img.get_pixelv(px))

	return colors


func _normalize_color(color: Color, quantize_steps: int = 16) -> Color:
	"""Quantize color values to reduce anti-aliasing gradient variations"""
	var step_size = 1.0 / float(quantize_steps)
	var normalized = Color(
		round(color.r / step_size) * step_size,
		round(color.g / step_size) * step_size,
		round(color.b / step_size) * step_size,
		1.0
	)
	return normalized


func _get_most_frequent_color(colors: Array[Color], tolerance: float = 0.015) -> Color:
	"""Find the most frequent color in an array, ignoring dark/background colors"""
	if colors.is_empty():
		print("[ColorSampling] No colors to analyze")
		return Color.BLACK

	# Dictionary to store color counts
	# Key is normalized color string, value is [count, original_color, normalized_color]
	var color_counts: Dictionary = {}
	var total_samples = colors.size()
	var ignored_count = 0

	for color in colors:
		# Ignore very dark colors (likely background or borders)
		if color.r < 0.05 and color.g < 0.05 and color.b < 0.05:
			ignored_count += 1
			continue

		# Normalize the color to group similar shades together
		var normalized = _normalize_color(color, 16)  # 16 steps = quantize to 1/16 increments
		var key = str(normalized)

		if key in color_counts:
			# Increment count for this normalized color
			color_counts[key][0] += 1
		else:
			# Store: [count, first_sample_color, normalized_color]
			color_counts[key] = [1, color, normalized]

	# Log sampling results
	print("[ColorSampling] Total samples: ", total_samples, " | Ignored dark pixels: ", ignored_count, " | Unique colors found: ", color_counts.size())

	# Find the color with the highest count
	var max_count = 0
	var most_frequent_color = Color.BLACK
	var winner_normalized = Color.BLACK

	for key in color_counts.keys():
		var count = color_counts[key][0]
		var original_color = color_counts[key][1]
		var normalized_color = color_counts[key][2]
		print("[ColorSampling]   Normalized (%.3f, %.3f, %.3f): %d votes (%.1f%%)" % [normalized_color.r, normalized_color.g, normalized_color.b, count, (float(count) / total_samples) * 100.0])
		if count > max_count:
			max_count = count
			most_frequent_color = original_color  # Return original color for better matching
			winner_normalized = normalized_color

	print("[ColorSampling] Winner: (%.3f, %.3f, %.3f) normalized from original samples, %d votes (%.1f%%)" % [winner_normalized.r, winner_normalized.g, winner_normalized.b, max_count, (float(max_count) / total_samples) * 100.0])
	return most_frequent_color


func _unhandled_input(event: InputEvent) -> void:
	# Handle Enter key for time freeze
	if event is InputEventKey:
		if event.keycode == KEY_ENTER and event.pressed and not event.echo:
			if GameState.time_freeze_tier > 0 and GameState.time_freeze_available:
				GameState.use_time_freeze()

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var vp := get_viewport()
			var img: Image = vp.get_texture().get_image()  # CPU readback of the rendered frame
			if img.is_empty():
					return

			# With viewport stretch mode, event.position is in viewport space (1800x1200)
			# but we need to sample from the actual rendered texture
			var mouse_pos = event.position
			var viewport_rect = vp.get_visible_rect()

			# Map mouse position to texture coordinates
			# viewport_rect.size is the logical viewport size (1800x1200)
			# img size is the actual texture size (should match)
			var uv = mouse_pos / viewport_rect.size
			var px := Vector2i(uv * Vector2(img.get_width(), img.get_height()))

			# Clamp to valid pixel range
			if px.x >= 0 and px.y >= 0 and px.x < img.get_width() and px.y < img.get_height():
					# Sample colors in a circular area around the click point (radius 10 = ~314 pixels sampled)
					var sampled_colors = _sample_colors_in_radius(img, px, 10)
					var color: Color = _get_most_frequent_color(sampled_colors)

					# Use a higher tolerance to account for rendering differences
					var country_id = GameState.get_country_by_color(color, 0.015)

					if country_id != "":
							print("Clicked country: ", country_id)
							GameState.set_pending_country(country_id)
					else:
							print("No country found at color: ", color)


func _on_rotation_speed_changed(_multiplier: float) -> void:
	"""Handle rotation speed changes from GameState"""
	_update_scroll_speed()


func _on_globe_scale_changed(_multiplier: float) -> void:
	"""Handle globe scale changes from GameState"""
	_update_globe_scale()


func _on_vertical_drift_changed(_amplitude: float) -> void:
	"""Handle vertical drift changes from GameState"""
	_update_vertical_drift()


func _update_scroll_speed() -> void:
	"""Update scroll speed based on current multiplier from GameState"""
	var multiplier = GameState.get_rotation_speed_multiplier()
	scroll_speed = base_scroll_speed * multiplier


func _update_globe_scale() -> void:
	"""Update globe scale based on current multiplier from GameState"""
	var multiplier = GameState.get_globe_scale_multiplier()

	# Get the center of the globe before scaling
	var globe_rect = globe_display.get_rect()
	var center_before = globe_display.position + globe_rect.size * globe_display.scale / 2.0

	# Apply new scale
	var new_scale = base_globe_scale * multiplier
	globe_display.scale = new_scale

	# Calculate new center position and adjust to keep globe centered
	var center_after = globe_display.position + globe_rect.size * new_scale / 2.0
	globe_display.position += center_before - center_after


func _update_vertical_drift() -> void:
	"""Update vertical drift amplitude based on current value from GameState"""
	vertical_drift_amplitude = GameState.get_vertical_drift_amplitude()
	print("[RotatingMap] Vertical drift amplitude updated to: ", vertical_drift_amplitude)


func _on_direction_chaos_changed(frequency: float) -> void:
	"""Handle direction chaos changes from GameState"""
	_update_direction_chaos()


func _update_direction_chaos() -> void:
	"""Update direction chaos parameters based on current value from GameState"""
	direction_chaos_frequency = GameState.get_direction_chaos_frequency()
	if direction_chaos_frequency > 0.0:
		# Initialize with randomized timing
		var base_interval = 1.0 / direction_chaos_frequency
		var random_multiplier = randf_range(0.5, 2.0)
		direction_chaos_next_change_time = base_interval * random_multiplier
	print("[RotatingMap] Direction chaos frequency updated to: ", direction_chaos_frequency)


func _on_time_freeze_changed(_tier: int, _shots_until_ready: int, _available: bool) -> void:
	"""Handle time freeze changes from GameState"""
	# Nothing needed here, we check GameState.is_time_frozen directly in _process
	pass
