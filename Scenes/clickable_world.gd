extends Node2D

## Exports
@export_file("*.svg") var svg_path: String
@export var fit_size: Vector2 = Vector2(1400, 800)

## Signals
signal country_clicked(country_id: String)

## Internal state
var _scale: Vector2 = Vector2.ONE
var _offset: Vector2 = Vector2.ZERO
var _svg_content: String = ""

func _ready():
	if svg_path.is_empty():
		push_error("No SVG path specified")
		return

	_load_and_render_svg()

func _load_and_render_svg():
	# Load SVG file
	var file = FileAccess.open(svg_path, FileAccess.READ)
	if file == null:
		push_error("Failed to open SVG file: " + svg_path)
		return

	_svg_content = file.get_as_text()
	file.close()

	# Extract viewBox or use width/height
	var viewbox = _extract_viewbox()

	# Calculate scale and offset to fit the map
	_calculate_transform(viewbox)

	# Render background
	_render_background()

	# Parse and create collision areas
	_parse_paths()

func _extract_viewbox() -> Rect2:
	var viewbox_regex = RegEx.new()
	viewbox_regex.compile("viewBox=\"([^\"]+)\"")
	var result = viewbox_regex.search(_svg_content)

	if result:
		var values = result.get_string(1).split(" ")
		if values.size() == 4:
			return Rect2(
				float(values[0]),
				float(values[1]),
				float(values[2]),
				float(values[3])
			)

	# Fallback: try to extract width and height
	var width_regex = RegEx.new()
	width_regex.compile("width=\"([0-9]+)\"")
	var height_regex = RegEx.new()
	height_regex.compile("height=\"([0-9]+)\"")

	var width_result = width_regex.search(_svg_content)
	var height_result = height_regex.search(_svg_content)

	if width_result and height_result:
		var w = float(width_result.get_string(1))
		var h = float(height_result.get_string(1))
		return Rect2(0, 0, w, h)

	# Default fallback
	return Rect2(0, 0, 1024, 512)

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

func _render_background():
	# Create sprite for background
	var sprite = Sprite2D.new()
	sprite.name = "MapBackground"
	add_child(sprite)

	# Load and rasterize SVG
	var image = Image.new()
	var error = image.load_svg_from_string(_svg_content, _scale.x)

	if error != OK:
		push_error("Failed to load SVG: " + str(error))
		return

	var texture = ImageTexture.create_from_image(image)
	sprite.texture = texture
	sprite.centered = false
	sprite.position = _offset

func _parse_paths():
	# Extract all path elements with id attributes
	var path_regex = RegEx.new()
	path_regex.compile("<path[^>]*id=\"([^\"]+)\"[^>]*d=\"([^\"]+)\"[^>]*>")

	var matches = path_regex.search_all(_svg_content)

	for match in matches:
		var country_id = match.get_string(1)
		var path_data = match.get_string(2)

		var points = _flatten_svg_path(path_data)
		if points.size() >= 3:
			_create_collision_area(country_id, points)

func _flatten_svg_path(path_data: String) -> PackedVector2Array:
	var points = PackedVector2Array()
	var current_pos = Vector2.ZERO
	var last_control = Vector2.ZERO
	var path_start = Vector2.ZERO

	var commands = _tokenize_path(path_data)
	var i = 0

	while i < commands.size():
		var cmd = commands[i]
		i += 1

		match cmd:
			"M": # Absolute move
				current_pos = _parse_point(commands, i)
				path_start = current_pos
				points.append(_transform_point(current_pos))
				i += 2
			"m": # Relative move
				var delta = _parse_point(commands, i)
				current_pos += delta
				path_start = current_pos
				points.append(_transform_point(current_pos))
				i += 2
			"L": # Absolute line
				current_pos = _parse_point(commands, i)
				points.append(_transform_point(current_pos))
				i += 2
			"l": # Relative line
				var delta = _parse_point(commands, i)
				current_pos += delta
				points.append(_transform_point(current_pos))
				i += 2
			"H": # Absolute horizontal line
				current_pos.x = float(commands[i])
				points.append(_transform_point(current_pos))
				i += 1
			"h": # Relative horizontal line
				current_pos.x += float(commands[i])
				points.append(_transform_point(current_pos))
				i += 1
			"V": # Absolute vertical line
				current_pos.y = float(commands[i])
				points.append(_transform_point(current_pos))
				i += 1
			"v": # Relative vertical line
				current_pos.y += float(commands[i])
				points.append(_transform_point(current_pos))
				i += 1
			"Z", "z": # Close path
				if points.size() > 0 and points[0] != _transform_point(current_pos):
					points.append(_transform_point(path_start))
				current_pos = path_start
			"C": # Absolute cubic bezier
				var cp1 = _parse_point(commands, i)
				var cp2 = _parse_point(commands, i + 2)
				var end = _parse_point(commands, i + 4)
				_add_cubic_bezier(points, current_pos, cp1, cp2, end)
				last_control = cp2
				current_pos = end
				i += 6
			"c": # Relative cubic bezier
				var cp1 = current_pos + _parse_point(commands, i)
				var cp2 = current_pos + _parse_point(commands, i + 2)
				var end = current_pos + _parse_point(commands, i + 4)
				_add_cubic_bezier(points, current_pos, cp1, cp2, end)
				last_control = cp2
				current_pos = end
				i += 6
			_:
				# Skip unknown commands
				pass

	return points

func _tokenize_path(path_data: String) -> Array:
	var tokens = []
	var current = ""
	var commands = "MmLlHhVvCcSsQqTtAaZz"

	for c in path_data:
		if c in commands:
			if current != "":
				tokens.append(current.strip_edges())
				current = ""
			tokens.append(c)
		elif c == " " or c == "," or c == "\n" or c == "\t":
			if current != "":
				tokens.append(current.strip_edges())
				current = ""
		else:
			current += c

	if current != "":
		tokens.append(current.strip_edges())

	return tokens

func _parse_point(commands: Array, index: int) -> Vector2:
	return Vector2(
		float(commands[index]),
		float(commands[index + 1])
	)

func _transform_point(point: Vector2) -> Vector2:
	return point * _scale + _offset

func _add_cubic_bezier(points: PackedVector2Array, p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2):
	var steps = 10
	for i in range(1, steps + 1):
		var t = float(i) / float(steps)
		var point = _cubic_bezier(p0, p1, p2, p3, t)
		points.append(_transform_point(point))

func _cubic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	var u = 1.0 - t
	var tt = t * t
	var uu = u * u
	var uuu = uu * u
	var ttt = tt * t

	return uuu * p0 + 3 * uu * t * p1 + 3 * u * tt * p2 + ttt * p3

func _create_collision_area(country_id: String, points: PackedVector2Array):
	# Simplify polygon if too complex
	if points.size() > 100:
		points = _simplify_polygon(points, 2.0)

	# Validate polygon
	if points.size() < 3:
		return

	# Create Area2D for collision
	var area = Area2D.new()
	area.name = "Country_" + country_id
	area.set_meta("country_id", country_id)
	add_child(area)

	# Create collision polygon
	var collision = CollisionPolygon2D.new()
	collision.polygon = points
	area.add_child(collision)

	# Connect signals
	area.mouse_entered.connect(_on_country_mouse_entered.bind(country_id))
	area.mouse_exited.connect(_on_country_mouse_exited.bind(country_id))
	area.input_event.connect(_on_country_input_event.bind(country_id))

func _simplify_polygon(points: PackedVector2Array, tolerance: float) -> PackedVector2Array:
	# Ramer-Douglas-Peucker algorithm
	if points.size() <= 2:
		return points

	var dmax = 0.0
	var index = 0
	var end = points.size() - 1

	for i in range(1, end):
		var d = _perpendicular_distance(points[i], points[0], points[end])
		if d > dmax:
			index = i
			dmax = d

	if dmax > tolerance:
		var rec1 = _simplify_polygon(points.slice(0, index + 1), tolerance)
		var rec2 = _simplify_polygon(points.slice(index, end + 1), tolerance)

		var result = PackedVector2Array()
		for i in range(rec1.size() - 1):
			result.append(rec1[i])
		for i in range(rec2.size()):
			result.append(rec2[i])
		return result
	else:
		return PackedVector2Array([points[0], points[end]])

func _perpendicular_distance(point: Vector2, line_start: Vector2, line_end: Vector2) -> float:
	var dx = line_end.x - line_start.x
	var dy = line_end.y - line_start.y

	if dx == 0 and dy == 0:
		return point.distance_to(line_start)

	var t = ((point.x - line_start.x) * dx + (point.y - line_start.y) * dy) / (dx * dx + dy * dy)
	t = clamp(t, 0.0, 1.0)

	var projection = Vector2(line_start.x + t * dx, line_start.y + t * dy)
	return point.distance_to(projection)

func _on_country_mouse_entered(country_id: String):
	# Add hover effect if desired
	pass

func _on_country_mouse_exited(country_id: String):
	# Remove hover effect if desired
	pass

func _on_country_input_event(_viewport: Node, event: InputEvent, _shape_idx: int, country_id: String):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			country_clicked.emit(country_id)
