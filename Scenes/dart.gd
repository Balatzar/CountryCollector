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
@export var show_preview := true
@export var trajectory_color: Color = Color(1.0, 1.0, 1.0, 0.6)  ## Color of the trajectory line
@export var trajectory_width: float = 3.0  ## Width of the trajectory line
@export var trajectory_resolution: int = 30  ## Number of points in the curve (smoothness)
@export var min_arch_factor: float = 0.05  ## Arch amount for downward throws (taut)
@export var max_arch_factor: float = 0.35  ## Arch amount for upward throws (arched)
# Asymmetric handle tuning (cubic Bézier)
@export var start_handle_strength: float = 1.0   ## Multiplier for start handle length (relative to base arch)
@export var end_handle_strength: float = 0.35    ## Multiplier for end handle length (weaker for perspective)
@export var start_forward_bias: float = 0.10     ## Small along-trajectory bias at the start (0..0.5)
@export var end_backward_bias: float = 0.05      ## Small backward bias on the end handle (0..0.5)
# Per-sprite tip offsets in local coordinates relative to each Sprite2D
@export var tip_offset_left: Vector2 = Vector2(0, -300)
@export var tip_offset_center: Vector2 = Vector2(0, -300)
@export var tip_offset_right: Vector2 = Vector2(0, -300)

# Projectile animation configuration
@export_group("Projectile Animation")
@export var projectile_rotation_factor: float = 0.2  ## How much the projectile rotates toward the curve tangent (0=none, 1=full)

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

	# Configure trajectory line and ensure it renders above the dart
	trajectory_line.visible = show_preview
	trajectory_line.default_color = trajectory_color
	trajectory_line.width = trajectory_width
	trajectory_line.z_index = 100  # make sure line is always drawn on top

	# Start with right sprite visible
	_update_sprite_visibility()

func _process(_delta: float) -> void:
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
	var _is_left: bool = current_x < left_bound
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
	## Generates a cubic Bézier curve with asymmetric handles for perspective
	## Stronger handle near the start, weaker near the end.

	var points: PackedVector2Array = PackedVector2Array()

	# Direction and distance
	var direction: Vector2 = (end - start)
	var distance: float = max(0.001, direction.length())
	var dir: Vector2 = direction / distance

	# Vertical factor: positive when aiming upward (screen -Y)
	var vertical_factor: float = -dir.y
	var normalized_factor: float = clamp(vertical_factor, -1.0, 1.0)
	var arch_amount: float = lerp(min_arch_factor, max_arch_factor, (normalized_factor + 1.0) / 2.0)

	# Upward-pointing normal (flip if needed)
	var n: Vector2 = Vector2(-dir.y, dir.x)
	if n.y > 0.0:
		n = -n

	# Handle lengths (asymmetric)
	var base_len: float = distance * arch_amount
	var len_start: float = base_len * max(0.0, start_handle_strength)
	var len_end: float = base_len * max(0.0, end_handle_strength)

	# Small forward/backward bias scaled by arch so downward shots remain taut
	var f_start: float = distance * start_forward_bias * arch_amount
	var f_end: float = distance * end_backward_bias * arch_amount

	# Cubic control points
	var p0: Vector2 = start
	var p3: Vector2 = end
	var p1: Vector2 = p0 + n * len_start + dir * f_start
	var p2: Vector2 = p3 - dir * f_end - n * len_end

	# Sample cubic Bézier
	for i in range(resolution + 1):
		var t: float = float(i) / float(resolution)
		var omt: float = 1.0 - t
		var omt2: float = omt * omt
		var t2: float = t * t
		var point: Vector2 = (
			omt2 * omt * p0 +
			3.0 * omt2 * t * p1 +
			3.0 * omt * t2 * p2 +
			t2 * t * p3
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


# --- Throw animation along current Bézier preview ---
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_start_throw_to((event as InputEventMouseButton).position)

func _start_throw_to(mouse_pos: Vector2) -> void:
	var start_tip: Vector2 = _get_dart_tip_position()
	var controls := _compute_bezier_controls(start_tip, mouse_pos)
	var p0: Vector2 = controls[0]
	var p1: Vector2 = controls[1]
	var p2: Vector2 = controls[2]
	var p3: Vector2 = controls[3]
	var proj: Node2D = _make_projectile_sprite()
	add_child(proj)
	proj.global_position = start_tip
	# Store initial rotation for interpolation
	var initial_rotation: float = proj.rotation
	proj.set_meta("initial_rotation", initial_rotation)
	var distance: float = start_tip.distance_to(mouse_pos)
	var duration: float = clamp(distance / 1400.0, 0.25, 0.9)
	var tween := create_tween()
	var cb := Callable(self, "_update_projectile_along_bezier").bind(proj, p0, p1, p2, p3)
	tween.tween_method(cb, 0.0, 1.0, duration)
	tween.finished.connect(func():
		if is_instance_valid(proj):
			proj.queue_free()
	)

func _update_projectile_along_bezier(t: float, proj: Node2D, p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2) -> void:
	var omt := 1.0 - t
	var omt2 := omt * omt
	var t2 := t * t
	var pos: Vector2 = (
		omt2 * omt * p0 +
		3.0 * omt2 * t * p1 +
		3.0 * omt * t2 * p2 +
		t2 * t * p3
	)
	proj.global_position = pos
	var s: float = lerp(1.0, 0.5, t)
	proj.scale = Vector2(s, s)
	# Orientation-aware rotation
	var sprite_orientation: String = str(proj.get_meta("sprite_orientation", "right"))
	# Disable rotation for center projectile
	if sprite_orientation == "center":
		return
	# Tangent (derivative) for rotation
	var tangent: Vector2 = (
		3.0 * omt2 * (p1 - p0) +
		6.0 * omt * t * (p2 - p1) +
		3.0 * t2 * (p3 - p2)
	)
	var tangent_angle: float = atan2(tangent.y, tangent.x)
	# Align tip to tangent using art's precomputed forward direction in world (without parent)
	var forward_world_no_parent: float = float(proj.get_meta("forward_world_no_parent", 0.0))
	var desired_parent_rot: float = tangent_angle - forward_world_no_parent
	proj.rotation = lerp_angle(proj.rotation, desired_parent_rot, projectile_rotation_factor)


func _make_projectile_sprite() -> Node2D:
	var source: Sprite2D = sprite_left if sprite_left.visible else (sprite_center if sprite_center.visible else sprite_right)
	var proj := Node2D.new()
	var dup := source.duplicate() as Sprite2D
	proj.add_child(dup)
	# Get the tip position in the source sprite's local space
	var tip_local: Vector2
	var tip_anchor: Node2D = dup.get_node_or_null("TipAnchor")
	if tip_anchor:
		# TipAnchor position is in sprite's local space
		tip_local = tip_anchor.position
	else:
		# Fallback to configured offsets
		if source == sprite_left:
			tip_local = tip_offset_left
		elif source == sprite_center:
			tip_local = tip_offset_center
		else:
			tip_local = tip_offset_right

	# Store which sprite orientation is being used for rotation logic
	var sprite_orientation: String = ""
	if source == sprite_left:
		sprite_orientation = "left"
	elif source == sprite_center:
		sprite_orientation = "center"
	else:
		sprite_orientation = "right"
	proj.set_meta("sprite_orientation", sprite_orientation)

	# Apply 180° rotation for right dart around the tip anchor
	if sprite_orientation == "right":
		# Rotate the sprite 180° around the tip point
		dup.rotation = PI
		# After rotation, the tip position changes due to the rotation
		# We need to recalculate where the tip is now
		var tip_in_parent: Vector2 = dup.transform * tip_local
		# Offset the duplicated sprite so the tip is at the projectile's origin
		dup.position -= tip_in_parent
	else:
		# For center and left, normal behavior
		# Transform the tip position through the sprite's transform to get it in the duplicated sprite's parent space
		var tip_in_parent: Vector2 = dup.transform * tip_local
		# Offset the duplicated sprite so the tip is at the projectile's origin
		dup.position -= tip_in_parent

	# Store child base rotation so parent can align to tangent relative to art
	proj.set_meta("child_base_rotation", dup.rotation)

	return proj

func _compute_bezier_controls(start: Vector2, end: Vector2) -> Array[Vector2]:
	var direction: Vector2 = (end - start)
	var distance: float = max(0.001, direction.length())
	var dir: Vector2 = direction / distance
	var vertical_factor: float = -dir.y
	var normalized_factor: float = clamp(vertical_factor, -1.0, 1.0)
	var arch_amount: float = lerp(min_arch_factor, max_arch_factor, (normalized_factor + 1.0) / 2.0)
	var n: Vector2 = Vector2(-dir.y, dir.x)
	if n.y > 0.0:
		n = -n
	var base_len: float = distance * arch_amount
	var len_start: float = base_len * max(0.0, start_handle_strength)
	var len_end: float = base_len * max(0.0, end_handle_strength)
	var f_start: float = distance * start_forward_bias * arch_amount
	var f_end: float = distance * end_backward_bias * arch_amount
	var p0: Vector2 = start
	var p3: Vector2 = end
	var p1: Vector2 = p0 + n * len_start + dir * f_start
	var p2: Vector2 = p3 - dir * f_end - n * len_end
	return [p0, p1, p2, p3]

# [augment] EOF marker
