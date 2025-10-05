extends Node2D

const CountryNames = preload("res://CountryNames.gd")

## Configuration
@export var scroll_speed: float = 50.0  # Pixels per second

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

	# Connect to game signals
	GameState.dart_thrown.connect(_on_dart_thrown)
	GameState.dart_landed.connect(_on_dart_landed)
	GameState.country_collected.connect(_on_country_collected)

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
	# Collect the pending country when dart lands
	if GameState.pending_country != "":
		GameState.collect_country(GameState.pending_country)
		GameState.pending_country = ""
	else:
		# Show miss notification if we didn't hit a country
		if not dart_hit_country:
			GameState.show_notification("Miss!", GameState.last_dart_position, COLOR_MISS)
			# Show fun fail message after 100ms
			await get_tree().create_timer(0.1).timeout
			var fun_msg = FUN_FAIL_MESSAGES[randi() % FUN_FAIL_MESSAGES.size()]
			GameState.show_notification(fun_msg, GameState.last_dart_position, COLOR_FUN)


func _on_country_collected(country_id: String) -> void:
	# Mark that this dart hit a country
	dart_hit_country = true

	# Show hit notification at dart landing position
	GameState.show_notification("Hit!", GameState.last_dart_position, COLOR_HIT)

	# Wait 100ms before showing country name
	await get_tree().create_timer(0.1).timeout

	# Get the country name and show it
	var country_name := CountryNames.get_country_name(country_id)
	GameState.show_notification(country_name, GameState.last_dart_position, COLOR_COUNTRY)

	# Wait another 100ms before showing fun success message
	await get_tree().create_timer(0.1).timeout
	var fun_msg = FUN_SUCCESS_MESSAGES[randi() % FUN_SUCCESS_MESSAGES.size()]
	GameState.show_notification(fun_msg, GameState.last_dart_position, COLOR_FUN)

	# Rebuild map copies to reflect the new white color
	if copies_created and map_copy != null:
		_rebuild_map_copy()

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
	# Don't update if paused
	if is_paused:
		return

	# Update scroll offset (in unscaled space)
	scroll_offset += scroll_speed * delta

	# Wrap offset to stay within one map width
	scroll_offset = fmod(scroll_offset, map_width)

	# Move the scroller left to simulate rotation
	# Account for the scale and maintain the centering
	var scaled_width = map_width * world_scroller.scale.x
	var base_x = (1024 - scaled_width) / 2.0
	world_scroller.position.x = base_x - (scroll_offset * world_scroller.scale.x)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var vp := get_viewport()
			var img: Image = vp.get_texture().get_image()  # CPU readback of the frame
			if img.is_empty():
					return

			# If your window is stretched/scaled, map mouse -> texture size safely via UV
			var mouse = event.position
			var vp_size: Vector2 = vp.size
			var tex_size: Vector2 = vp.get_texture().get_size()
			var uv = mouse / vp_size
			var px := Vector2i(uv * tex_size)

			# Depending on backend, you may need to flip vertically:
			# img.flip_y()
			if px.x >= 0 and px.y >= 0 and px.x < img.get_width() and px.y < img.get_height():
					var color: Color = img.get_pixelv(px)

					# Use a higher tolerance to account for rendering differences
					var country_id = GameState.get_country_by_color(color, 0.015)

					if country_id != "":
							print("Clicked country: ", country_id)
							GameState.set_pending_country(country_id)
					else:
							print("No country found at color: ", color)
