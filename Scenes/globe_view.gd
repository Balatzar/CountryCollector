extends Node2D

## Configuration
@export var scroll_speed: float = 100.0  # Pixels per second
@export var map_width: float = 1800.0  # Width of one ClickableWorld instance
@export var world_scale: float = 0.85  # Uniform scale applied to WorldScroller


## Node references
@onready var sub_viewport: SubViewport = $SubViewport
@onready var world_scroller: Node2D = $SubViewport/WorldScroller

## Internal state
var tween: Tween = null
func _apply_layout() -> void:
	# Compute base offset so the scaled content stays centered in the square viewport
	var vw: float = float(sub_viewport.size.x)
	var vh: float = float(sub_viewport.size.y)
	var scaled_w: float = map_width * world_scale
	var scaled_h: float = vh * world_scale
	base_offset = Vector2((vw - scaled_w) * 0.5, (vh - scaled_h) * 0.5)

	world_scroller.scale = Vector2(world_scale, world_scale)
	world_scroller.position = base_offset

var base_offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	_apply_layout()
	_start_scrolling_animation()


func _start_scrolling_animation() -> void:
	if tween:
		tween.kill()

	# Calculate animation duration based on speed (in screen space, independent of scale)
	var effective_width: float = map_width * world_scale
	var duration: float = effective_width / scroll_speed

	# Create infinite looping tween
	tween = create_tween()
	tween.set_loops()
	tween.set_trans(Tween.TRANS_LINEAR)

	# Animate from 0 to -map_width (one full map scroll)
	# When it reaches -map_width, it loops back to 0, creating seamless scroll
	tween.tween_property(world_scroller, "position:x", base_offset.x - map_width, duration).from(base_offset.x)
