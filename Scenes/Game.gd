extends Node2D

@onready var notification_display: Node2D = $NotificationDisplay
@onready var store_overlay: CanvasLayer = $StoreOverlay
@onready var xp_bar: MarginContainer = $GameOverlay/MarginContainer/XPBarContainer
@onready var game_over_screen: CanvasLayer = $GameOverScreen


func _ready() -> void:
	# Connect to notification signal
	GameState.notification_requested.connect(_on_notification_requested)

	# Connect to XP bar animation complete signal to open store
	xp_bar.level_up_animation_complete.connect(_on_xp_bar_animation_complete)

	# Connect to store closed signal to unpause
	store_overlay.store_closed.connect(_on_store_closed)

	# Connect to game over signal
	GameState.game_over.connect(_on_game_over)

	# Connect to restart button
	game_over_screen.restart_game_pressed.connect(_on_restart_game)

	# Hide game over screen initially
	game_over_screen.hide()


func _on_notification_requested(text: String, notif_position: Vector2, color: Color) -> void:
	# Move notification display to requested position and spawn
	notification_display.global_position = notif_position
	notification_display.spawn_notification(text, color)


func _on_xp_bar_animation_complete() -> void:
	# Open store after XP bar level up animation completes
	get_tree().paused = true
	store_overlay.show_store()


func _on_store_closed() -> void:
	# Unpause when store closes
	get_tree().paused = false


func _on_game_over() -> void:
	# Show game over screen and pause
	get_tree().paused = true
	game_over_screen.show_screen()


func _on_restart_game() -> void:
	# Reset game state
	GameState.reset()

	# Unpause and reload the scene
	get_tree().paused = false
	get_tree().reload_current_scene()
