extends Node2D

## Zoom controller for the map
## Handles zoom levels and smooth transitions centered on mouse cursor
## Zooms the entire globe display (GlobeDisplay TextureRect)

# Zoom level configuration
@export var zoom_level_1: float = 1.5
@export var zoom_level_2: float = 2.0
@export var zoom_level_3: float = 3.0
@export var zoom_level_4: float = 4.0
@export var zoom_level_5: float = 5.0
@export var zoom_duration: float = 0.3  # Duration of zoom animation in seconds

# Node references - will be set from the RotatingStaticMap
var globe_display: TextureRect = null
var rotating_map: Node2D = null

# Internal state
var current_zoom_level: int = 1  # 1, 2, 3, 4, or 5
var is_zoomed: bool = false
var base_scale: Vector2 = Vector2.ONE
var base_position: Vector2 = Vector2.ZERO
var zoom_tween: Tween = null


func _ready() -> void:
	# Get references from the RotatingStaticMap child
	rotating_map = get_node_or_null("RotatingStaticMap")
	if rotating_map:
		globe_display = rotating_map.get_node_or_null("GlobeDisplay")

	if not globe_display:
		push_error("[ZoomController] Could not find GlobeDisplay node!")
		return

	# Wait a frame for the rotating map to set up its initial position
	await get_tree().process_frame

	# Store the initial scale and position of the globe display
	base_scale = globe_display.scale
	base_position = globe_display.position
	print("[ZoomController] Base scale: ", base_scale, " Base position: ", base_position)

	# Connect to GameState signals
	GameState.zoom_bonus_acquired.connect(_on_zoom_bonus_acquired)

	# Initialize zoom level from GameState
	current_zoom_level = GameState.current_zoom_level


func _input(event: InputEvent) -> void:
	# Only handle zoom if we have a zoom bonus
	if current_zoom_level == 0:
		return

	# Handle spacebar press/release for zoom
	if event is InputEventKey:
		if event.keycode == KEY_SPACE:
			if event.pressed and not event.echo and not is_zoomed:
				_zoom_in()
			elif not event.pressed and is_zoomed:
				_zoom_out()


func set_zoom_level(level: int) -> void:
	"""Set the current zoom level (1, 2, 3, 4, or 5)"""
	if level < 1 or level > 5:
		push_error("Invalid zoom level: " + str(level))
		return

	current_zoom_level = level
	print("[ZoomController] Zoom level set to: ", level)


func get_zoom_factor() -> float:
	"""Get the zoom factor for the current level"""
	match current_zoom_level:
		1:
			return zoom_level_1
		2:
			return zoom_level_2
		3:
			return zoom_level_3
		4:
			return zoom_level_4
		5:
			return zoom_level_5
		_:
			return zoom_level_1


func _zoom_in() -> void:
	"""Zoom in on the globe display centered on mouse cursor"""
	if is_zoomed:
		return

	is_zoomed = true

	# Get mouse position in viewport coordinates
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()

	# Get the zoom factor
	var zoom_factor: float = get_zoom_factor()

	# Calculate the target scale
	var target_scale: Vector2 = base_scale * zoom_factor

	# Calculate the mouse position relative to the globe display
	# We want to zoom in such that the point under the mouse stays under the mouse

	# Mouse position relative to the globe display's current position
	var mouse_in_globe: Vector2 = (mouse_pos - globe_display.position) / globe_display.scale

	# After zooming, we want the same point to be under the mouse
	# new_position + mouse_in_globe * new_scale = mouse_pos
	# new_position = mouse_pos - mouse_in_globe * new_scale
	# But we can also express it as:
	# new_position = old_position + mouse_in_globe * (old_scale - new_scale)

	var target_position: Vector2 = globe_display.position + mouse_in_globe * (globe_display.scale - target_scale)

	# Create smooth zoom animation
	if zoom_tween:
		zoom_tween.kill()

	zoom_tween = create_tween()
	zoom_tween.set_parallel(true)
	zoom_tween.set_ease(Tween.EASE_OUT)
	zoom_tween.set_trans(Tween.TRANS_CUBIC)

	zoom_tween.tween_property(globe_display, "scale", target_scale, zoom_duration)
	zoom_tween.tween_property(globe_display, "position", target_position, zoom_duration)

	print("[ZoomController] Zooming in to level ", current_zoom_level, " (", zoom_factor, "x)")


func _zoom_out() -> void:
	"""Zoom out to normal view"""
	if not is_zoomed:
		return

	is_zoomed = false

	# Create smooth zoom out animation
	if zoom_tween:
		zoom_tween.kill()

	zoom_tween = create_tween()
	zoom_tween.set_parallel(true)
	zoom_tween.set_ease(Tween.EASE_OUT)
	zoom_tween.set_trans(Tween.TRANS_CUBIC)

	zoom_tween.tween_property(globe_display, "scale", base_scale, zoom_duration)
	zoom_tween.tween_property(globe_display, "position", base_position, zoom_duration)

	print("[ZoomController] Zooming out to normal view")


func _on_zoom_bonus_acquired(zoom_level: int) -> void:
	"""Handle zoom bonus acquisition from GameState"""
	if zoom_level == 0:
		# Zoom was cancelled out, zoom out if currently zoomed
		current_zoom_level = 0
		if is_zoomed:
			_zoom_out()
		print("[ZoomController] Zoom disabled (cancelled by unzoom)")
	else:
		set_zoom_level(zoom_level)

