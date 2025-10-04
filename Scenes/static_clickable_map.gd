extends Node2D

const ASSETS_DIR = "res://Assets/NA/"
const IMAGE_WIDTH = 1024
const IMAGE_HEIGHT = 512

func _ready():
	print("StaticClickableMap: _ready() called")
	_load_countries()
	print("StaticClickableMap: Loaded countries")

func _load_countries():
	var dir = DirAccess.open(ASSETS_DIR)
	if dir == null:
		push_error("Failed to open directory: " + ASSETS_DIR)
		return

	var map_files = []
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with("_map.png"):
			map_files.append(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()

	print("StaticClickableMap: Found %d map files" % map_files.size())
	for map_file in map_files:
		var country_id = map_file.replace("_map.png", "")
		print("StaticClickableMap: Creating sprite for " + country_id)
		_create_country_sprite(country_id)

func _create_country_sprite(country_id: String):
	var map_path = ASSETS_DIR + country_id + "_map.png"
	var alpha_path = ASSETS_DIR + country_id + "_alpha.png"

	var map_texture = load(map_path)
	var alpha_texture = load(alpha_path)

	if map_texture == null:
		push_error("Failed to load map texture: " + map_path)
		return
	if alpha_texture == null:
		push_error("Failed to load alpha texture: " + alpha_path)
		return

	var sprite = Sprite2D.new()
	sprite.texture = map_texture
	sprite.centered = false
	sprite.position = Vector2.ZERO
	add_child(sprite)
	print("StaticClickableMap: Added sprite for " + country_id + " at position " + str(sprite.position) + " with size " + str(map_texture.get_size()))

	var area = Area2D.new()
	area.set_meta("country_id", country_id)
	sprite.add_child(area)

	var alpha_image = alpha_texture.get_image()
	var bitmap = BitMap.new()
	bitmap.create_from_image_alpha(alpha_image, 0.1)

	var polygons = bitmap.opaque_to_polygons(Rect2(Vector2.ZERO, alpha_image.get_size()), 2.0)

	for polygon in polygons:
		var collision = CollisionPolygon2D.new()
		collision.polygon = polygon
		area.add_child(collision)

	area.input_event.connect(_on_country_input_event.bind(country_id))

	GameState.add_country(country_id)

func _on_country_input_event(viewport: Node, event: InputEvent, shape_idx: int, country_id: String):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		GameState.collect_country(country_id)
		print("Collected country: " + country_id)
