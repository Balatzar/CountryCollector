extends MarginContainer

## XP Bar component with animations and visual effects

# Node references
@onready var xp_progress_bar: ProgressBar = $XPPanel/XPHBox/XPProgressBar
@onready var xp_panel: PanelContainer = $XPPanel
@onready var xp_label: Label = $XPPanel/XPHBox/XPLabel

# XP bar animation state
var shimmer_time: float = 0.0
var shimmer_speed: float = 1.5
var pulse_time: float = 0.0
var pulse_speed: float = 2.0


func _ready() -> void:
	# Ensure XP panel scales from its center
	xp_panel.pivot_offset = xp_panel.size / 2.0
	xp_panel.resized.connect(_on_xp_panel_resized)

	# Connect to GameState signals
	GameState.xp_changed.connect(_on_xp_changed)
	GameState.level_up.connect(_on_level_up)

	# Setup XP bar animations
	_setup_xp_bar()

	# Initialize progress bar with current XP
	_update_xp_display()


func _process(delta: float) -> void:
	# Animate the shimmer effect on the XP bar
	_animate_xp_shimmer(delta)


func _setup_xp_bar() -> void:
	"""Initialize the XP bar with starting animations"""
	# Start with a subtle pulse animation
	_start_xp_pulse_animation()


func _animate_xp_shimmer(delta: float) -> void:
	"""Animate a shimmer/glow effect on the XP bar"""
	shimmer_time += delta * shimmer_speed

	# Create a subtle brightness modulation using sine wave
	var shimmer_intensity: float = (sin(shimmer_time) + 1.0) / 2.0  # 0.0 to 1.0
	var shimmer_color: Color = Color(1.0, 0.85, 0.3, 0.2 + shimmer_intensity * 0.15)

	# Apply shimmer to the progress bar's fill style
	var fill_style: StyleBoxFlat = xp_progress_bar.get_theme_stylebox("fill")
	if fill_style:
		fill_style.shadow_color = shimmer_color


func _start_xp_pulse_animation() -> void:
	"""Start a subtle pulsing animation on the XP panel"""
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(xp_panel, "modulate:a", 0.95, 1.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(xp_panel, "modulate:a", 1.0, 1.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


func _on_xp_changed(current_xp: int, current_level: int) -> void:
	"""Handle XP change from GameState"""
	# Update level label
	xp_label.text = "Level %d" % current_level

	# Calculate percentage for progress bar (0-100)
	var xp_percentage: float = (float(current_xp) / float(GameState.XP_PER_LEVEL)) * 100.0
	animate_xp_gain(xp_percentage)


func _on_level_up(new_level: int) -> void:
	"""Handle level up from GameState"""
	animate_xp_level_up()


func _update_xp_display() -> void:
	"""Update the XP bar to show current XP without animation"""
	# Update level label
	xp_label.text = "Level %d" % GameState.level

	# Update progress bar
	var xp_percentage: float = (float(GameState.xp) / float(GameState.XP_PER_LEVEL)) * 100.0
	xp_progress_bar.value = xp_percentage


func animate_xp_gain(new_value: float) -> void:
	"""Animate the XP bar filling to a new value"""
	# Smooth fill animation
	var tween := create_tween()
	tween.tween_property(xp_progress_bar, "value", new_value, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	# Add a flash effect during the fill
	tween.parallel().tween_property(xp_panel, "modulate", Color(1.2, 1.1, 1.0, 1.0), 0.2)
	tween.tween_property(xp_panel, "modulate", Color.WHITE, 0.3)


func animate_xp_level_up() -> void:
	"""Celebration animation when player levels up"""

	# Flash effect
	var flash_tween := create_tween()
	flash_tween.tween_property(xp_panel, "modulate", Color(1.5, 1.3, 1.0, 1.0), 0.1)
	flash_tween.tween_property(xp_panel, "modulate", Color.WHITE, 0.1)
	flash_tween.tween_property(xp_panel, "modulate", Color(1.3, 1.2, 1.0, 1.0), 0.1)
	flash_tween.tween_property(xp_panel, "modulate", Color.WHITE, 0.2)

	# Scale bounce effect
	var bounce_tween := create_tween()
	bounce_tween.tween_property(xp_panel, "scale", Vector2(1.05, 1.05), 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	bounce_tween.tween_property(xp_panel, "scale", Vector2.ONE, 0.3).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_ELASTIC)

	# Glow pulse
	var glow_tween := create_tween()
	for i in range(3):
		glow_tween.tween_property(xp_progress_bar, "modulate", Color(1.3, 1.2, 1.0, 1.0), 0.2)
		glow_tween.tween_property(xp_progress_bar, "modulate", Color.WHITE, 0.2)


func _on_xp_panel_resized() -> void:
	# Keep pivot at center so scale animations bounce from the middle
	xp_panel.pivot_offset = xp_panel.size / 2.0
