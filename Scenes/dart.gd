extends Node2D

## Dart that follows the mouse horizontally at the bottom of the screen
## Switches between left and right sprites based on screen position

# Export variables for configuration
@export var bottom_offset: float = 100.0  ## Distance from bottom of screen
@export var damping: float = 0.15  ## Smoothing factor (0-1, higher = faster response)

# Sprite references
@onready var sprite_left: Sprite2D = $SpriteLeft
@onready var sprite_center: Sprite2D = $SpriteCenter
@onready var sprite_right: Sprite2D = $SpriteRight

# Target and current positions
var target_x: float = 0.0
var current_x: float = 0.0
var fixed_y: float = 0.0

func _ready() -> void:
	# Calculate fixed Y position (bottom of screen)
	var viewport_size = get_viewport_rect().size
	fixed_y = viewport_size.y - bottom_offset

	# Initialize position at screen center
	current_x = viewport_size.x / 2.0
	target_x = current_x
	position = Vector2(current_x, fixed_y)

	# Start with right sprite visible
	_update_sprite_visibility()

func _process(delta: float) -> void:
	# Get mouse position
	var mouse_pos = get_viewport().get_mouse_position()
	var viewport_size = get_viewport_rect().size

	# Inverse X position to simulate 3D perspective
	# When mouse is left, dart is right (and vice versa)
	target_x = viewport_size.x - mouse_pos.x

	# Apply damping for smooth movement
	current_x = lerp(current_x, target_x, damping)

	# Update position (only X changes, Y stays fixed)
	position = Vector2(current_x, fixed_y)

	# Update which sprite is visible based on screen position
	_update_sprite_visibility()

func _update_sprite_visibility() -> void:
	# Three horizontal zones: left, center, right
	var viewport_size = get_viewport_rect().size
	var width: float = viewport_size.x
	var left_bound: float = 0.45 * width
	var right_bound: float = 0.55 * width
	var x: float = current_x

	# Determine visibility per zone (45% | 10% | 45%)
	sprite_left.visible = x < left_bound
	sprite_center.visible = x >= left_bound and x < right_bound
	sprite_right.visible = x >= right_bound
