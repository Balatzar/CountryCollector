extends Node2D

## Configuration
@export var scroll_speed: float = 100.0  # Pixels per second
@export var map_width: float = 1800.0  # Width of one ClickableWorld instance

## Node references
@onready var world_scroller: Node2D = $SubViewport/WorldScroller

## Internal state
var tween: Tween = null


func _ready() -> void:
	_start_scrolling_animation()


func _start_scrolling_animation() -> void:
	if tween:
		tween.kill()
	
	# Calculate animation duration based on speed
	var duration: float = map_width / scroll_speed
	
	# Create infinite looping tween
	tween = create_tween()
	tween.set_loops()
	tween.set_trans(Tween.TRANS_LINEAR)

	# Animate from 0 to -map_width (one full map scroll)
	# When it reaches -map_width, it loops back to 0, creating seamless scroll
	tween.tween_property(world_scroller, "position:x", -map_width, duration).from(0.0)
