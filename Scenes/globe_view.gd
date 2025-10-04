extends Node2D

## Configuration
@export var scroll_speed: float = 100.0  # Pixels per second
@export var map_width: float = 1800.0  # Width of one ClickableWorld instance
@export var world_scale: float = 0.85  # Uniform scale applied to WorldScroller


## Node references
@onready var sub_viewport: SubViewport = $SubViewport
@onready var world_scroller: Node2D = $SubViewport/WorldScroller
@onready var clickable_world: Node2D = $SubViewport/WorldScroller/ClickableWorld1

## Internal state
var scroll_offset: float = 0.0
var base_offset: Vector2 = Vector2.ZERO
var world_copy: Node2D = null  # Visual copy for wrapping
var visual_copies_created: bool = false

func _apply_layout() -> void:
	# Compute base offset so the scaled content stays centered in the square viewport
	var vw: float = float(sub_viewport.size.x)
	var vh: float = float(sub_viewport.size.y)
	var scaled_w: float = map_width * world_scale
	var scaled_h: float = vh * world_scale
	base_offset = Vector2((vw - scaled_w) * 0.5, (vh - scaled_h) * 0.5)

	world_scroller.scale = Vector2(world_scale, world_scale)


func _ready() -> void:
	_apply_layout()

	# Create a visual copy container for wrapping
	# Position it at map_width (before WorldScroller scaling is applied)
	world_copy = Node2D.new()
	world_scroller.add_child(world_copy)
	world_copy.position = Vector2(map_width, 0)

	# Wait a frame for ClickableWorld to populate, then create visual copies
	await get_tree().process_frame
	_create_visual_copies()


func _create_visual_copies() -> void:
	if visual_copies_created:
		return

	# Create lightweight visual copies of all sprites (shares textures, no collision)
	for child in clickable_world.get_children():
		if child is Sprite2D:
			var sprite_copy = Sprite2D.new()
			sprite_copy.texture = child.texture
			sprite_copy.centered = child.centered
			sprite_copy.offset = child.offset
			sprite_copy.position = child.position
			sprite_copy.scale = child.scale
			sprite_copy.rotation = child.rotation
			sprite_copy.modulate = child.modulate
			sprite_copy.z_index = child.z_index
			# Don't copy collision shapes or Area2D - purely visual
			world_copy.add_child(sprite_copy)

	visual_copies_created = true
	print("Created ", world_copy.get_child_count(), " visual sprite copies at x=", world_copy.position.x)


func _process(delta: float) -> void:
	# Update scroll offset
	scroll_offset += scroll_speed * delta

	# Wrap offset to stay within one map width
	scroll_offset = fmod(scroll_offset, map_width)

	# Position the world scroller
	# The offset is in unscaled space, so we apply it directly to the scroller's position
	# We keep the Y position constant at base_offset.y
	world_scroller.position.x = base_offset.x - (scroll_offset * world_scroller.scale.x)
	world_scroller.position.y = base_offset.y
