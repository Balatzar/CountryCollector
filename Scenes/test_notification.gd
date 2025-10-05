extends Control

@onready var notification_display: Node2D = $NotificationDisplay
@onready var button: Button = $Button

var test_messages: Array[String] = [
	"+100 points!",
	"Amazing!",
	"Great shot!",
	"Combo x2!",
	"Perfect!",
	"Incredible!",
	"New country collected!",
	"Level up!",
	"Bonus!",
	"Fantastic!"
]

var test_colors: Array[Color] = [
	Color.WHITE,
	Color.YELLOW,
	Color.ORANGE,
	Color.LIGHT_GREEN,
	Color.CYAN,
	Color.PINK
]


func _ready() -> void:
	button.pressed.connect(_on_button_pressed)


func _on_button_pressed() -> void:
	# Spawn a random notification with random color
	var message := test_messages[randi() % test_messages.size()]
	var color := test_colors[randi() % test_colors.size()]
	notification_display.spawn_notification(message, color)
