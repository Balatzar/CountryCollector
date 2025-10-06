extends CanvasLayer

## Dramatic game over screen with stats and restart button

signal restart_game_pressed()

# Node references
@onready var restart_button: Button = $Control/CenterContainer/VBoxContainer/RestartButton
@onready var game_over_label: Label = $Control/CenterContainer/VBoxContainer/GameOverLabel
@onready var stats_container: VBoxContainer = $Control/CenterContainer/VBoxContainer/StatsContainer
@onready var countries_collected_label: Label = $Control/CenterContainer/VBoxContainer/StatsContainer/CountriesCollectedLabel
@onready var darts_used_label: Label = $Control/CenterContainer/VBoxContainer/StatsContainer/DartsUsedLabel

# Animation variables
var time_passed: float = 0.0
var pulse_speed: float = 2.0
var pulse_amount: float = 0.05
var title_animation_time: float = 0.0


func _ready() -> void:
	# Set pivot offset to center of button for proper scaling
	restart_button.pivot_offset = restart_button.size / 2.0

	# Connect button signal
	restart_button.pressed.connect(_on_restart_button_pressed)


func show_screen() -> void:
	# Update stats from GameState
	_update_stats()

	# Start with title invisible for dramatic entrance
	game_over_label.modulate.a = 0.0
	stats_container.modulate.a = 0.0
	restart_button.modulate.a = 0.0

	# Show and animate entrance
	show()
	_animate_entrance()


func _process(delta: float) -> void:
	# Animate the restart button with a pulsing effect
	time_passed += delta
	var pulse: float = sin(time_passed * pulse_speed) * pulse_amount
	var scale_factor: float = 1.0 + pulse
	restart_button.scale = Vector2(scale_factor, scale_factor)
	
	# Animate title with subtle shake/pulse
	title_animation_time += delta
	var shake_x: float = sin(title_animation_time * 3.0) * 2.0
	var shake_y: float = cos(title_animation_time * 2.5) * 1.5
	game_over_label.position.x = shake_x
	game_over_label.position.y = shake_y


func _animate_entrance() -> void:
	# Dramatic entrance animation
	var tween := create_tween()
	tween.set_parallel(true)
	
	# Title fades in and scales up
	tween.tween_property(game_over_label, "modulate:a", 1.0, 0.8).set_delay(0.2)
	tween.tween_property(game_over_label, "scale", Vector2.ONE, 0.8).from(Vector2(0.5, 0.5)).set_delay(0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Stats fade in
	tween.tween_property(stats_container, "modulate:a", 1.0, 0.6).set_delay(1.0)
	
	# Button fades in
	tween.tween_property(restart_button, "modulate:a", 1.0, 0.6).set_delay(1.5)


func _update_stats() -> void:
	var collected := GameState.get_collected_count()
	var total := GameState.get_total_countries()
	var darts_used := GameState.get_darts_thrown()

	countries_collected_label.text = "Countries Collected: %d / %d" % [collected, total]
	darts_used_label.text = "Darts Used: %d" % darts_used


func _on_restart_button_pressed() -> void:
	# Play click sound
	AudioManager.play_click()

	# Emit signal to notify that game should restart
	restart_game_pressed.emit()

	# Add a quick scale animation on press
	var tween := create_tween()
	tween.tween_property(restart_button, "scale", Vector2(0.95, 0.95), 0.1)
	tween.tween_property(restart_button, "scale", Vector2.ONE, 0.1)

