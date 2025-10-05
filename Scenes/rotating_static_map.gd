extends Node2D

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

	# Wait for StaticClickableMap to load its sprites and GameState to register countries
	if GameState.all_countries.is_empty():
		await GameState.countries_loaded
	else:
		await get_tree().process_frame

	_create_map_copy()

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

func _process(delta: float) -> void:
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
							GameState.collect_country(country_id)
					else:
							print("No country found at color: ", color)
