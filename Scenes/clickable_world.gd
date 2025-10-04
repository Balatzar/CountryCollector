extends Node2D

## Exports
@export_file("*.svg") var svg_path: String
@export var fit_size: Vector2 = Vector2(1800, 1200)

## Signals
signal country_clicked(country_id: String)

## Internal state
var _scale: Vector2 = Vector2.ONE
var _offset: Vector2 = Vector2.ZERO
var _svg_content: String = ""

func _ready():
	# Remove display SVG when running the game
	var display_sprite = get_node_or_null("Sprite2D")
	if display_sprite:
		display_sprite.queue_free()

	if svg_path.is_empty():
		push_error("No SVG path specified")
		return

	_load_and_render_svg()

func _load_and_render_svg():
	var file = FileAccess.open(svg_path, FileAccess.READ)
	if file == null:
		push_error("Failed to open SVG file: " + svg_path)
		return

	_svg_content = file.get_as_text()
	file.close()

	var viewbox = _extract_viewbox()
	_calculate_transform(viewbox)
	_parse_and_render_countries()

func _extract_viewbox() -> Rect2:
	var regex = RegEx.new()
	regex.compile("viewbox=\"([^\"]+)\"")
	var result = regex.search(_svg_content)

	if result:
		var values = result.get_string(1).split(" ")
		return Rect2(float(values[0]), float(values[1]), float(values[2]), float(values[3]))

	return Rect2(0, 0, 2000, 857)

func _calculate_transform(viewbox: Rect2):
	var svg_size = viewbox.size
	var scale_x = fit_size.x / svg_size.x
	var scale_y = fit_size.y / svg_size.y
	var scale_factor = min(scale_x, scale_y)

	_scale = Vector2(scale_factor, scale_factor)

	# Center the map
	var scaled_size = svg_size * scale_factor
	_offset = (fit_size - scaled_size) / 2.0
	_offset -= Vector2(viewbox.position.x, viewbox.position.y) * scale_factor

	# Print transform values for manual configuration
	print("Display Sprite2D transform values:")
	print("  - Centered: false")
	print("  - Position: ", _offset)
	print("  - Scale: ", _scale)

func _parse_and_render_countries():
	var path_regex = RegEx.new()
	path_regex.compile("<path[^>]+>")

	var d_regex = RegEx.new()
	d_regex.compile("d=\"([^\"]+)\"")

	var name_regex = RegEx.new()
	name_regex.compile("name=\"([^\"]+)\"")

	var class_regex = RegEx.new()
	class_regex.compile("class=\"([^\"]+)\"")

	var id_regex = RegEx.new()
	id_regex.compile("id=\"([^\"]+)\"")

	var path_matches = path_regex.search_all(_svg_content)
	var viewbox = _extract_viewbox()

	for path_match in path_matches:
		var path_element = path_match.get_string()

		var d_match = d_regex.search(path_element)
		if not d_match:
			continue

		var path_data = d_match.get_string(1)

		# Priority: name > class > id
		var country_id = ""
		var name_match = name_regex.search(path_element)
		if name_match:
			country_id = name_match.get_string(1)
		else:
			var class_match = class_regex.search(path_element)
			if class_match:
				country_id = class_match.get_string(1)
			else:
				var id_match = id_regex.search(path_element)
				if id_match:
					country_id = id_match.get_string(1)

		if country_id != "":
			_create_country_sprite(country_id, path_data, viewbox)

	GameState.notify_countries_loaded()

func _create_country_sprite(country_id: String, path_data: String, viewbox: Rect2):
	# Add country to GameState
	GameState.add_country(country_id)

	# Create a minimal SVG for just this country
	var country_svg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="%s %s %s %s"><path d="%s" fill="#cccccc" stroke="black" stroke-width="0.2"/></svg>' % [
		viewbox.position.x, viewbox.position.y, viewbox.size.x, viewbox.size.y,
		path_data
	]

	# Rasterize the SVG
	var image = Image.new()
	var error = image.load_svg_from_string(country_svg, _scale.x)
	if error != OK:
		return

	# Create sprite
	var sprite = Sprite2D.new()
	sprite.name = "Country_" + country_id
	sprite.texture = ImageTexture.create_from_image(image)
	sprite.centered = false
	sprite.position = _offset
	sprite.set_meta("country_id", country_id)
	add_child(sprite)

	# Add Area2D for click detection using pixel-perfect collision
	var area = Area2D.new()
	area.set_meta("country_id", country_id)
	sprite.add_child(area)

	# Create bitmap from image alpha channel for pixel-perfect collision
	var bitmap = BitMap.new()
	bitmap.create_from_image_alpha(image, 0.1)

	# Convert bitmap to collision polygons
	var polygons = bitmap.opaque_to_polygons(Rect2(Vector2.ZERO, image.get_size()), 2.0)

	for polygon in polygons:
		if polygon.size() >= 3:
			var collision = CollisionPolygon2D.new()
			collision.polygon = polygon
			area.add_child(collision)

	area.input_event.connect(_on_country_input_event.bind(country_id))

func _on_country_input_event(_viewport: Node, event: InputEvent, _shape_idx: int, country_id: String):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			GameState.collect_country(country_id)
			country_clicked.emit(country_id)
			_fill_country_black(country_id)

func _fill_country_black(country_id: String):
	# Find all sprites with this country_id (handles multi-part countries)
	for child in get_children():
		if child is Sprite2D and child.has_meta("country_id") and child.get_meta("country_id") == country_id:
			# Apply dark modulate to make it appear black
			child.modulate = Color(0.2, 0.2, 0.2, 1.0)
