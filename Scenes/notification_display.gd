extends Node2D

## Animation settings
@export_group("Animation Timing")
@export var animation_duration: float = 1.2
@export var fade_start_time: float = 0.6  # When to start fading (0.0 = immediately, 1.0 = at end)

@export_group("Movement")
@export var base_move_distance: Vector2 = Vector2(0, -150)  # Base upward movement
@export var horizontal_spread: float = 200.0  # Random horizontal variance
@export var vertical_variance: float = 80.0  # Random vertical variance

@export_group("Rotation & Scale")
@export var max_rotation_degrees: float = 25.0  # Random rotation range
@export var spawn_scale: float = 0.3  # Starting scale (pops in from this size)
@export var end_scale: float = 1.4  # Ending scale
@export var scale_variance: float = 0.4  # Random scale variation

@export_group("Visual Style")
@export var font_size: int = 32
@export var default_color: Color = Color.WHITE
@export var outline_size: int = 8
@export var outline_color: Color = Color.BLACK

@export_group("Animation Styles")
@export var use_random_curve: bool = true
@export var enable_bounce: bool = true
@export var enable_rotation: bool = true

@onready var spawner: Node2D = $Spawner
@onready var debug_point: ColorRect = $DebugPoint


func _ready() -> void:
	# Hide debug visualization when game is running
	debug_point.visible = false

	# Ensure notifications render above everything (UI, overlays, etc.)
	z_index = 1000


func spawn_notification(text: String, custom_color: Color = default_color) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", custom_color)
	label.add_theme_color_override("font_outline_color", outline_color)
	label.add_theme_constant_override("outline_size", outline_size)

	# Position at spawner
	spawner.add_child(label)
	label.position = Vector2.ZERO
	label.pivot_offset = label.size / 2.0  # Center pivot for rotation/scale

	# Start small for pop-in effect
	label.scale = Vector2.ONE * spawn_scale
	label.modulate.a = 1.0

	# Generate random movement
	var random_offset := Vector2(
		randf_range(-horizontal_spread, horizontal_spread),
		randf_range(-vertical_variance, vertical_variance)
	)
	var target_position := base_move_distance + random_offset

	# Generate random rotation
	var target_rotation := 0.0
	if enable_rotation:
		target_rotation = deg_to_rad(randf_range(-max_rotation_degrees, max_rotation_degrees))

	# Generate random scale
	var final_scale := end_scale + randf_range(-scale_variance, scale_variance)

	# Create animation
	var tween := create_tween()
	tween.set_parallel(true)

	# Choose animation curve
	var curve_type := Tween.TRANS_CUBIC
	var ease_type := Tween.EASE_OUT

	if use_random_curve:
		var curves := [Tween.TRANS_BOUNCE, Tween.TRANS_ELASTIC]
		if enable_bounce:
			curves.append(Tween.TRANS_BACK)
		curve_type = curves[randi() % curves.size()]

	# Movement animation
	tween.tween_property(label, "position", target_position, animation_duration)\
		.set_trans(curve_type).set_ease(ease_type)

	# Scale animation - pop in then grow
	tween.tween_property(label, "scale", Vector2.ONE * final_scale, animation_duration)\
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

	# Rotation animation
	if enable_rotation:
		tween.tween_property(label, "rotation", target_rotation, animation_duration)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# Fade out
	var fade_delay := animation_duration * fade_start_time
	var fade_duration := animation_duration * (1.0 - fade_start_time)
	tween.tween_property(label, "modulate:a", 0.0, fade_duration)\
		.set_delay(fade_delay).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

	# Cleanup when done
	tween.finished.connect(func(): label.queue_free())
