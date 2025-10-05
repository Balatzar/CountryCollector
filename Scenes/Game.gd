extends Node2D

@onready var notification_display: Node2D = $NotificationDisplay


func _ready() -> void:
	# Connect to notification signal
	GameState.notification_requested.connect(_on_notification_requested)


func _on_notification_requested(text: String, position: Vector2, color: Color) -> void:
	# Move notification display to requested position and spawn
	notification_display.global_position = position
	notification_display.spawn_notification(text, color)
