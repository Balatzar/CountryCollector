extends Node2D

@export var max_skew: float = 0.08  ## Maximum horizontal skew for perspective effect (subtle)
@export var max_rotation_degrees: float = 3.0  ## Maximum rotation angle in degrees (subtle)
@export var perspective_damping: float = 0.2  ## Smoothing for skew/rotation (0-1, higher = faster)


## Dart that follows the mouse horizontally at the bottom of the screen
## Switches between left and right sprites based on screen position

# Export variables for configuration
@export var bottom_offset: float = 100.0  ## Distance from bottom of screen
@export var damping: float = 0.15  ## Smoothing factor (0-1, higher = faster response)

# Trajectory preview configuration
@export_group("Trajectory Preview")
@export var trajectory_color: Color = Color(1.0, 1.0, 1.0, 0.6)  ## Color of the trajectory line
@export var trajectory_width: float = 3.0  ## Width of the trajectory line
@export var trajectory_resolution: int = 30  ## Number of points in the curve (smoothness)
@export var min_arch_factor: float = 0.05  ## Arch amount for downward throws (taut)
@export var max_arch_factor: float = 0.35  ## Arch amount for upward throws (arched)
# Per-sprite tip offsets in local coordinates relative to each Sprite2D
@export var tip_offset_left: Vector2 = Vector2(0, -300)
@export var tip_offset_center: Vector2 = Vector2(0, -300)
@export var tip_offset_right: Vector2 = Vector2(0, -300)

# Sprite references
@onready var sprite_left: Sprite2D = $SpriteLeft
@onready var sprite_center: Sprite2D = $SpriteCenter
@onready var sprite_right: Sprite2D = $SpriteRight
@onready var trajectory_line: Line2D = $TrajectoryLine
# Optional anchors (will be null if not present)
@onready var tip_anchor_left: Node2D = get_node_or_null("SpriteLeft/TipAnchor")
@onready var tip_anchor_center: Node2D = get_node_or_null("SpriteCenter/TipAnchor")
@onready var tip_anchor_right: Node2D = get_node_or_null("SpriteRight/TipAnchor")

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

	# Configure trajectory line
	trajectory_line.default_color = trajectory_color
	trajectory_line.width = trajectory_width

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

	# Update trajectory preview
	_update_trajectory(mouse_pos)

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


func _get_dart_tip_position() -> Vector2:
	## Returns the global position of the dart tip based on which sprite is visible
	if sprite_left.visible:
		if tip_anchor_left:
			return tip_anchor_left.global_position
		return sprite_left.to_global(tip_offset_left)
	elif sprite_center.visible:
		if tip_anchor_center:
			return tip_anchor_center.global_position
		return sprite_center.to_global(tip_offset_center)
	else:
		if tip_anchor_right:
			return tip_anchor_right.global_position
		return sprite_right.to_global(tip_offset_right)


func _generate_bezier_curve(start: Vector2, end: Vector2, resolution: int) -> PackedVector2Array:
	## Generates a quadratic Bézier curve from start to end with dynamic control point
	## The control point is calculated based on the vertical direction to create
	## taut curves for downward throws and arched curves for upward throws

	var points: PackedVector2Array = PackedVector2Array()

	# Calculate direction and distance
	var direction: Vector2 = (end - start).normalized()
	var distance: float = start.distance_to(end)

	# Vertical factor: positive when aiming upward, negative when aiming downward
	# In Godot, negative Y is up, so we negate direction.y
	var vertical_factor: float = -direction.y

	# Map vertical factor to arch amount
	# Upward throws (vertical_factor > 0) get more arch
	# Downward throws (vertical_factor < 0) get less arch (taut)
	var normalized_factor: float = clamp(vertical_factor, -1.0, 1.0)
	var arch_amount: float = lerp(min_arch_factor, max_arch_factor, (normalized_factor + 1.0) / 2.0)

	# Calculate control point: ahead along the shot, offset upward by a normal
	var midpoint: Vector2 = start.lerp(end, 0.5)
	var normal: Vector2 = Vector2(-direction.y, direction.x)  # 90deg CCW
	# Ensure the normal points upward on screen (negative Y). Flip if not.
	if normal.y > 0.0:
		normal = -normal
	var control_point: Vector2 = midpoint + normal * distance * arch_amount

	# Generate curve points using quadratic Bézier formula
	# B(t) = (1-t)²P₀ + 2(1-t)tP₁ + t²P₂
	for i in range(resolution + 1):
		var t: float = float(i) / float(resolution)
		var one_minus_t: float = 1.0 - t

		var point: Vector2 = (
			one_minus_t * one_minus_t * start +
			2.0 * one_minus_t * t * control_point +
			t * t * end
		)

		points.append(point)

	return points


func _update_trajectory(mouse_pos: Vector2) -> void:
	## Updates the trajectory line to show the path from dart tip to mouse cursor

	# Get dart tip position in global coordinates
	var dart_tip: Vector2 = _get_dart_tip_position()

	# Generate Bézier curve points
	var curve_points: PackedVector2Array = _generate_bezier_curve(
		dart_tip,
		mouse_pos,
		trajectory_resolution
	)

	# Convert global points to local coordinates for Line2D
	var local_points: PackedVector2Array = PackedVector2Array()
	for point in curve_points:
		local_points.append(point - position)

	# Update the Line2D
	trajectory_line.points = local_points


# [augment] EOF marker
