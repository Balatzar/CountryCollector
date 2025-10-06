extends AnimatedSprite2D

## Smoke effect that plays once and auto-destroys


func _ready() -> void:
	# Play the animation forward (not backwards)
	play("default")
	
	# Connect to animation_finished signal to auto-destroy
	animation_finished.connect(_on_animation_finished)


func _on_animation_finished() -> void:
	# Remove this node when animation completes
	queue_free()

