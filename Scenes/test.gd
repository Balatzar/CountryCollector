extends Node2D
signal country_clicked(id: String)

@export_file("*.svg") var svg_path: String
@export var fit_size := Vector2(1400, 800)        # Target size to fit the map in
@export var show_polygons := true                 # Draw clickable polygons (useful for debug/hover)
@export var polygon_fill := Color8(210, 220, 232) # Light fill so you can see areas
@export var polygon_hover := Color8(255, 200, 80) # Hover color

var _scale := 1.0
var _offset := Vector2.ZERO
var _areas_by_id := {} # id -> Array[Area2D]

func _ready() -> void:
	if svg_path.is_empty():
		push_warning("Assign svg_path in the Inspector.")
		return

	var svg_text := FileAccess.get_file_as_string(svg_path)
	var viewbox := _read_viewbox(svg_text)
	_compute_fit(viewbox)

	# Draw the original SVG as a raster background at the same scale we use for polygons.
	_draw_svg_background(svg_text)

	# Build clickable areas from <path id="..."> elements.
	_build_click_areas(svg_text)

	print("[ClickableSVGMap] Ready. Click a country to see its ID in the output.")

# ---------- SVG BACKGROUND RENDERING ----------

func _draw_svg_background(svg_text: String) -> void:
	var img := Image.new()
	# Godot 4 supports rasterizing SVG at runtime; we match our precomputed _scale
	# so the background aligns with the generated polygons.
	# Docs: Image.load_svg_from_string(svg_str: String, scale: float = 1.0)
	img.load_svg_from_string(svg_text, _scale)
	var tex := ImageTexture.create_from_image(img)

	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.centered = false
	sprite.position = _offset
	sprite.z_index = -100
	add_child(sprite)

# ---------- SVG PARSING / FIT ----------

func _read_viewbox(svg_text: String) -> Rect2:
	var parser := XMLParser.new()
	parser.open_buffer(svg_text.to_utf8_buffer())
	while parser.read() == OK:
		if parser.get_node_type() == XMLParser.NODE_ELEMENT and parser.get_node_name() == "svg":
			var vb := parser.get_named_attribute_value_safe("viewBox")
			if vb != "":
				var p := vb.strip_edges().split(" ")
				if p.size() == 4:
					return Rect2(_f(p[0]), _f(p[1]), _f(p[2]), _f(p[3]))
			# Fall back to width/height if no viewBox is present
			var w := parser.get_named_attribute_value_safe("width")
			var h := parser.get_named_attribute_value_safe("height")
			if w != "" and h != "":
				return Rect2(0, 0, _to_px(w), _to_px(h))
			break
	return Rect2(0, 0, 2048, 1024) # sensible default world-ish aspect

func _compute_fit(vb: Rect2) -> void:
	_scale = min(fit_size.x / vb.size.x, fit_size.y / vb.size.y)
	_offset = -vb.position * _scale

func _to_px(s: String) -> float:
	if s.ends_with("px"):
		return _f(s.trim_suffix("px"))
	return _f(s)

func _f(s: String) -> float:
	return float(s)

# ---------- BUILD CLICKABLE AREAS ----------

func _build_click_areas(svg_text: String) -> void:
	var parser := XMLParser.new()
	parser.open_buffer(svg_text.to_utf8_buffer())

	while parser.read() == OK:
		if parser.get_node_type() == XMLParser.NODE_ELEMENT and parser.get_node_name() == "path":
			var id := parser.get_named_attribute_value_safe("id")
			var d  := parser.get_named_attribute_value_safe("d")
			if d == "":
				continue

			var polys: Array = _flatten_svg_path(d) # Array of PackedVector2Array

			for p: PackedVector2Array in polys:
				if p.size() < 3:
					print("[ClickableSVGMap] Skipping tiny polygon for '%s': size=%d" % [id, p.size()])
					continue

				# Scale+offset to our canvas coordinates
				var world_poly := PackedVector2Array()
				for v in p:
					world_poly.push_back(v * _scale + _offset)

				# Skip invalid polygons (degenerate, self-intersecting, etc.)
				var validation_result = _is_valid_polygon(world_poly)
				if not validation_result:
					print("[ClickableSVGMap] Skipping invalid polygon for '%s': points=%d" % [id, world_poly.size()])
					continue

				print("[ClickableSVGMap] Creating collision polygon for '%s': points=%d" % [id, world_poly.size()])

				# Simplify polygon if it has too many points (collision system can't handle complex polygons)
				var collision_poly = world_poly
				if world_poly.size() > 100:
					collision_poly = _simplify_polygon(world_poly, 2.0)
					print("[ClickableSVGMap] Simplified '%s' from %d to %d points" % [id, world_poly.size(), collision_poly.size()])

				# Visible polygon (optional)
				var poly_node := Polygon2D.new()
				poly_node.polygon = world_poly
				poly_node.color = polygon_fill
				poly_node.visible = show_polygons

				# Clickable collider
				var area := Area2D.new()
				area.input_pickable = true
				area.set_meta("country_id", id)
				var cp := CollisionPolygon2D.new()
				cp.polygon = collision_poly
				area.add_child(cp)

				# Hover effect (optional)
				area.mouse_entered.connect(func():
					if show_polygons: poly_node.color = polygon_hover)
				area.mouse_exited.connect(func():
					if show_polygons: poly_node.color = polygon_fill)

				# Click handling
				area.input_event.connect(func(_vp, ev, _shape_idx):
					if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
						var cid := String(area.get_meta("country_id"))
						emit_signal("country_clicked", cid)
						print("Clicked country:", cid)
				)

				add_child(poly_node)
				add_child(area)

				if not _areas_by_id.has(id):
					_areas_by_id[id] = []
				_areas_by_id[id].append(area)

# ---------- SVG PATH FLATTENER ----------
# Supports M/m, L/l, H/h, V/v, C/c, S/s, Q/q, T/t, Z/z.
# A/a (elliptical arc) is approximated as a straight line to the endpoint (simple but works for most maps).

func _flatten_svg_path(d: String) -> Array:
	var out: Array = [] # Array of PackedVector2Array
	var tokens := _tokenize_path(d)
	var i := 0

	var curr := Vector2.ZERO
	var start := Vector2.ZERO
	var prev_cmd := ""
	var last_cubic_ctrl := Vector2.ZERO
	var last_quad_ctrl := Vector2.ZERO
	var poly := PackedVector2Array()

	while i < tokens.size():
		var cmd = tokens[i]; i += 1
		if typeof(cmd) != TYPE_STRING:
			# If omitted, some commands repeat the previous one (e.g. multiple L coordinates).
			# Put the token back and reuse prev_cmd if valid.
			i -= 1
			cmd = prev_cmd

		match cmd:
			"M", "m":
				var rel = (cmd == "m")
				if poly.size() > 0:
					out.append(poly); poly = PackedVector2Array()
				curr = _read_point(tokens, i, rel, curr); i += 2
				start = curr
				poly.push_back(curr)
				# Subsequent coordinate pairs are implicit L:
				while i + 1 < tokens.size() and typeof(tokens[i]) == TYPE_FLOAT and typeof(tokens[i+1]) == TYPE_FLOAT:
					var p := _read_point(tokens, i, rel, curr); i += 2
					curr = p
					poly.push_back(curr)

			"L", "l":
				var rel = (cmd == "l")
				while i + 1 < tokens.size() and typeof(tokens[i]) == TYPE_FLOAT and typeof(tokens[i+1]) == TYPE_FLOAT:
					var p := _read_point(tokens, i, rel, curr); i += 2
					curr = p
					poly.push_back(curr)

			"H", "h":
				var rel = (cmd == "h")
				while i < tokens.size() and typeof(tokens[i]) == TYPE_FLOAT:
					var x := float(tokens[i]); i += 1
					curr = Vector2(curr.x + x if rel else x, curr.y)
					poly.push_back(curr)

			"V", "v":
				var rel = (cmd == "v")
				while i < tokens.size() and typeof(tokens[i]) == TYPE_FLOAT:
					var y := float(tokens[i]); i += 1
					curr = Vector2(curr.x, curr.y + y if rel else y)
					poly.push_back(curr)

			"C", "c":
				var rel = (cmd == "c")
				while i + 5 < tokens.size():
					var c1 := _read_point(tokens, i, rel, curr); i += 2
					var c2 := _read_point(tokens, i, rel, curr); i += 2
					var p3 := _read_point(tokens, i, rel, curr); i += 2
					var seg := _sample_cubic(curr, c1, c2, p3)
					_append_segment(poly, seg)
					curr = p3
					last_cubic_ctrl = c2
					last_quad_ctrl = curr

			"S", "s":
				var rel = (cmd == "s")
				while i + 3 < tokens.size():
					var c2 := _read_point(tokens, i, rel, curr); i += 2
					var p3 := _read_point(tokens, i, rel, curr); i += 2
					var c1 := curr * 2.0 - last_cubic_ctrl
					var seg := _sample_cubic(curr, c1, c2, p3)
					_append_segment(poly, seg)
					curr = p3
					last_cubic_ctrl = c2
					last_quad_ctrl = curr

			"Q", "q":
				var rel = (cmd == "q")
				while i + 3 < tokens.size():
					var c1 := _read_point(tokens, i, rel, curr); i += 2
					var p2 := _read_point(tokens, i, rel, curr); i += 2
					var seg := _sample_quadratic(curr, c1, p2)
					_append_segment(poly, seg)
					curr = p2
					last_quad_ctrl = c1
					last_cubic_ctrl = curr

			"T", "t":
				var rel = (cmd == "t")
				while i + 1 < tokens.size():
					var p2 := _read_point(tokens, i, rel, curr); i += 2
					var c1 := curr * 2.0 - last_quad_ctrl
					var seg := _sample_quadratic(curr, c1, p2)
					_append_segment(poly, seg)
					curr = p2
					last_quad_ctrl = c1
					last_cubic_ctrl = curr

			"A", "a":
				# Elliptical arcs are approximated with a straight line to endpoint (good enough for most political maps).
				var rel = (cmd == "a")
				while i + 6 - 1 < tokens.size():
					# rx ry x-axis-rotation large-arc-flag sweep-flag x y
					# We only advance the read head and go to (x,y).
					i += 5
					var p := _read_point(tokens, i, rel, curr); i += 2
					curr = p
					poly.push_back(curr)

			"Z", "z":
				if poly.size() > 0 and poly[0] != poly[poly.size()-1]:
					poly.push_back(poly[0])
				if poly.size() >= 3:
					out.append(poly)
				poly = PackedVector2Array()
				curr = start

			_:
				# Unsupported/unknown command; try to skip gracefully.
				pass

		prev_cmd = String(cmd)

	# If last subpath wasn’t explicitly closed, flush it.
	if poly.size() >= 3:
		if poly[0] != poly[poly.size()-1]:
			poly.push_back(poly[0])
		out.append(poly)

	return out

# ---------- PATH TOKENIZER / HELPERS ----------

func _tokenize_path(d: String) -> Array:
	var t: Array = []
	var i := 0
	while i < d.length():
		var c := d[i]
		if c.is_valid_identifier() and c.to_ascii_buffer()[0] >= 65 and c.to_ascii_buffer()[0] <= 122:
			t.append(String(c))
			i += 1
		elif c == "+" or c == "-" or c.is_valid_float() or c.is_valid_int():
			var j := i
			var saw_e := false
			while j < d.length():
				var ch := d[j]
				if ch == "e" or ch == "E":
					saw_e = true
				elif (ch == "-" or ch == "+") and saw_e:
					# sign in exponent, keep parsing
					pass
				elif not (ch.is_valid_int() or ch == "." or ch == "e" or ch == "E" or ch == "-" or ch == "+"):
					break
				j += 1
			var num_str := d.substr(i, j - i).strip_edges().trim_suffix(",")
			if num_str != "":
				t.append(float(num_str))
			i = j
		else:
			i += 1 # skip spaces/commas/unknowns
	return t

func _read_point(tokens: Array, i: int, relative: bool, origin: Vector2) -> Vector2:
	var x := float(tokens[i])
	var y := float(tokens[i + 1])
	return origin + Vector2(x, y) if relative else Vector2(x, y)

func _append_segment(poly: PackedVector2Array, pts: PackedVector2Array) -> void:
	for k in range(1, pts.size()):
		poly.push_back(pts[k])

func _sample_cubic(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2) -> PackedVector2Array:
	var d := p0.distance_to(p3)
	var steps = clamp(int(d / 8.0), 8, 64)
	var out := PackedVector2Array()
	for s in range(0, steps + 1):
		var t := float(s) / float(steps)
		var u := 1.0 - t
		var p := u*u*u*p0 + 3.0*u*u*t*p1 + 3.0*u*t*t*p2 + t*t*t*p3
		out.push_back(p)
	return out

func _sample_quadratic(p0: Vector2, c: Vector2, p1: Vector2) -> PackedVector2Array:
	var d := p0.distance_to(p1)
	var steps = clamp(int(d / 8.0), 8, 48)
	var out := PackedVector2Array()
	for s in range(0, steps + 1):
		var t := float(s) / float(steps)
		var u := 1.0 - t
		var p := u*u*p0 + 2.0*u*t*c + t*t*p1
		out.push_back(p)
	return out

func _is_valid_polygon(poly: PackedVector2Array) -> bool:
	if poly.size() < 3:
		return false

	# Remove duplicate consecutive points
	var cleaned := PackedVector2Array()
	cleaned.push_back(poly[0])
	for i in range(1, poly.size()):
		if poly[i].distance_squared_to(cleaned[cleaned.size() - 1]) > 0.01:
			cleaned.push_back(poly[i])

	# Need at least 3 distinct points
	if cleaned.size() < 3:
		return false

	# Calculate polygon area (should be non-zero)
	var area = 0.0
	for i in range(cleaned.size()):
		var j = (i + 1) % cleaned.size()
		area += cleaned[i].x * cleaned[j].y
		area -= cleaned[j].x * cleaned[i].y

	return abs(area) > 1.0  # Minimum area threshold

func _simplify_polygon(poly: PackedVector2Array, tolerance: float) -> PackedVector2Array:
	# Ramer-Douglas-Peucker algorithm for polygon simplification
	if poly.size() < 3:
		return poly

	return _rdp_simplify(poly, 0, poly.size() - 1, tolerance)

func _rdp_simplify(poly: PackedVector2Array, start: int, end: int, tolerance: float) -> PackedVector2Array:
	var max_dist = 0.0
	var max_index = 0

	# Find the point with maximum distance from the line segment
	for i in range(start + 1, end):
		var dist = _point_to_line_distance(poly[i], poly[start], poly[end])
		if dist > max_dist:
			max_dist = dist
			max_index = i

	# If max distance is greater than tolerance, recursively simplify
	if max_dist > tolerance:
		var left = _rdp_simplify(poly, start, max_index, tolerance)
		var right = _rdp_simplify(poly, max_index, end, tolerance)

		# Merge results (remove duplicate middle point)
		var result := PackedVector2Array()
		for i in range(left.size() - 1):
			result.push_back(left[i])
		for i in range(right.size()):
			result.push_back(right[i])
		return result
	else:
		# Return just the endpoints
		var result := PackedVector2Array()
		result.push_back(poly[start])
		result.push_back(poly[end])
		return result

func _point_to_line_distance(point: Vector2, line_start: Vector2, line_end: Vector2) -> float:
	var line_vec = line_end - line_start
	var point_vec = point - line_start
	var line_len = line_vec.length()

	if line_len < 0.001:
		return point_vec.length()

	var line_unit = line_vec / line_len
	var proj_length = point_vec.dot(line_unit)

	if proj_length < 0.0:
		return point_vec.length()
	elif proj_length > line_len:
		return (point - line_end).length()
	else:
		var proj_point = line_start + line_unit * proj_length
		return (point - proj_point).length()
