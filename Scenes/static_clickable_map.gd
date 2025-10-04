extends Node2D

const ASSETS_DIR = "res://Assets/alphas/"
const IMAGE_WIDTH = 1024
const IMAGE_HEIGHT = 512

func _ready():
	_load_countries()

func _load_countries():
	var dir = DirAccess.open(ASSETS_DIR)
	if dir == null:
		push_error("Failed to open directory: " + ASSETS_DIR)
		return

	var alpha_files = []
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with("_alpha.png"):
			alpha_files.append(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()

	for alpha_file in alpha_files:
		var country_id = alpha_file.replace("_alpha.png", "")
		_create_country_sprite(country_id)

func _create_country_sprite(country_id: String):
	var alpha_path = ASSETS_DIR + country_id + "_alpha.png"
	var alpha_texture = load(alpha_path)

	if alpha_texture == null:
		push_error("Failed to load alpha texture: " + alpha_path)
		return

	# Generate a random bright color for each country
	var random_color = Color(randf(), randf(), randf(), 1.0)

	# Create a colored texture from the alpha mask
	var alpha_image = alpha_texture.get_image()
	var colored_image = Image.create(alpha_image.get_width(), alpha_image.get_height(), false, Image.FORMAT_RGBA8)

	# Fill the image with the random color, using the alpha mask
	for y in range(alpha_image.get_height()):
		for x in range(alpha_image.get_width()):
			var alpha_value = alpha_image.get_pixel(x, y).a
			colored_image.set_pixel(x, y, Color(random_color.r, random_color.g, random_color.b, alpha_value))

	var colored_texture = ImageTexture.create_from_image(colored_image)

	var sprite = Sprite2D.new()
	sprite.texture = colored_texture
	sprite.centered = false
	sprite.position = Vector2.ZERO
	add_child(sprite)

	# Register color in GameState
	GameState.add_country(country_id)
	GameState.register_country_color(country_id, random_color)
