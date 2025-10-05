extends Node2D

## Test scene for XP bar animations
## Demonstrates the fill animation and level-up celebration

@onready var game_overlay: CanvasLayer = $GameOverlay
@onready var test_panel: PanelContainer = $TestUILayer/TestPanel
@onready var info_label: Label = $TestUILayer/TestPanel/VBox/InfoLabel
@onready var add_xp_button: Button = $TestUILayer/TestPanel/VBox/AddXPButton
@onready var level_up_button: Button = $TestUILayer/TestPanel/VBox/LevelUpButton
@onready var reset_button: Button = $TestUILayer/TestPanel/VBox/ResetButton

var current_xp: float = 50.0


func _ready() -> void:
	# Connect button signals
	add_xp_button.pressed.connect(_on_add_xp_pressed)
	level_up_button.pressed.connect(_on_level_up_pressed)
	reset_button.pressed.connect(_on_reset_pressed)

	_update_info_label()


func _on_add_xp_pressed() -> void:
	"""Add 25 XP and animate the fill"""
	current_xp = min(current_xp + 25.0, 100.0)
	game_overlay.animate_xp_gain(current_xp)
	_update_info_label()

	# If we reached 100%, trigger level up automatically
	if current_xp >= 100.0:
		await get_tree().create_timer(0.6).timeout
		_on_level_up_pressed()


func _on_level_up_pressed() -> void:
	"""Trigger the level-up celebration animation"""
	game_overlay.animate_xp_level_up()
	await get_tree().create_timer(1.5).timeout
	# Reset to 0 after celebration
	current_xp = 0.0
	game_overlay.animate_xp_gain(0.0)
	_update_info_label()


func _on_reset_pressed() -> void:
	"""Reset XP to 50%"""
	current_xp = 50.0
	game_overlay.animate_xp_gain(current_xp)
	_update_info_label()


func _update_info_label() -> void:
	"""Update the info label with current XP"""
	info_label.text = "Current XP: %.0f%%\n\nClick buttons to test animations:\n• Add XP: +25 XP with smooth fill\n• Level Up: Celebration animation\n• Reset: Back to 50%%" % current_xp
