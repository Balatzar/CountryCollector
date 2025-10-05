extends Control

## Title screen with animated start button

signal start_game_pressed()

# Node references
@onready var start_button: Button = $CenterContainer/VBoxContainer/StartButton
@onready var logo: TextureRect = $CenterContainer/VBoxContainer/Logo

# Animation variables
var time_passed: float = 0.0
var pulse_speed: float = 2.0
var pulse_amount: float = 0.05


func _ready() -> void:
	# Set pivot offset to center of button for proper scaling
	start_button.pivot_offset = start_button.size / 2.0

	# Connect button signal
	start_button.pressed.connect(_on_start_button_pressed)


func _process(delta: float) -> void:
	# Animate the start button with a pulsing effect
	time_passed += delta
	var pulse: float = sin(time_passed * pulse_speed) * pulse_amount
	var scale_factor: float = 1.0 + pulse
	start_button.scale = Vector2(scale_factor, scale_factor)


func _on_start_button_pressed() -> void:
	# Emit signal to notify that game should start
	start_game_pressed.emit()

	# Add a quick scale animation on press
	var tween := create_tween()
	tween.tween_property(start_button, "scale", Vector2(0.95, 0.95), 0.1)
	tween.tween_property(start_button, "scale", Vector2.ONE, 0.1)

