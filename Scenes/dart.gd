extends Node2D

@export var max_skew: float = 0.08  ## Maximum horizontal skew for perspective effect (subtle)
@export var max_rotation_degrees: float = 3.0  ## Maximum rotation angle in degrees (subtle)
@export var perspective_damping: float = 0.2  ## Smoothing for skew/rotation (0-1, higher = faster)


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

	# Cache base local positions and init perspective state
	sprite_left.set_meta("base_pos", sprite_left.position)
	sprite_center.set_meta("base_pos", sprite_center.position)
	sprite_right.set_meta("base_pos", sprite_right.position)
	set_meta("cur_skew", 0.0)
	set_meta("cur_rot", 0.0)


	# Start with right sprite visible
	_update_sprite_visibility()

func _process(delta: float) -> void:
	# Get mouse position
	var mouse_pos = get_viewport().get_mouse_position()
	var viewport_size = get_viewport_rect().size

	# Inverted, centered, and reduced movement:
	# Dart offset from center = -0.5 * (mouse_offset_from_center)
	# Keeps dart near center while preserving left/right inversion.
	var center_x: float = viewport_size.x / 2.0
	target_x = center_x - 0.5 * (mouse_pos.x - center_x)

	# Apply damping for smooth movement
	current_x = lerp(current_x, target_x, damping)

	# Update position (only X changes, Y stays fixed)
	position = Vector2(current_x, fixed_y)

	# Apply subtle perspective transform before deciding visibility
	var nx: float = clamp((mouse_pos.x / max(1.0, viewport_size.x)) * 2.0 - 1.0, -1.0, 1.0)
	var ny: float = clamp((mouse_pos.y / max(1.0, viewport_size.y)) * 2.0 - 1.0, -1.0, 1.0)
	var t_skew: float = nx * max_skew
	# Determine zone to control rotation behavior
	var width: float = viewport_size.x
	var left_bound: float = 0.45 * width
	var right_bound: float = 0.55 * width
	var is_left: bool = current_x < left_bound
	var is_center: bool = current_x >= left_bound and current_x < right_bound
	var is_right: bool = current_x >= right_bound
	# Base rotation from vertical position
	var t_rot_base: float = ny * max_rotation_degrees
	# Keep rotation visually consistent: flip on right side; disable in center
	var facing_sign: float = -1.0 if is_right else 1.0
	var t_rot: float = 0.0 if is_center else t_rot_base * facing_sign
	var c_skew: float = (float(get_meta("cur_skew")) if has_meta("cur_skew") else 0.0)
	var c_rot: float = (float(get_meta("cur_rot")) if has_meta("cur_rot") else 0.0)
	var alpha: float = clamp(perspective_damping, 0.0, 1.0)
	c_skew = lerp(c_skew, t_skew, alpha)
	c_rot = lerp(c_rot, t_rot, alpha)
	set_meta("cur_skew", c_skew)
	set_meta("cur_rot", c_rot)
	var basis: Transform2D = Transform2D(0.0, Vector2.ZERO)
	basis.x = Vector2(1.0, c_skew)
	basis.y = Vector2(0.0, 1.0)
	basis = basis.rotated(deg_to_rad(c_rot))
	for s in [sprite_left, sprite_center, sprite_right]:
		s.transform = basis
		if s.has_meta("base_pos"):
			s.position = s.get_meta("base_pos")

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


# [augment] EOF marker
