extends Node2D

const ASSETS_DIR = "res://Assets/alphas/"
const IMAGE_WIDTH = 1024
const IMAGE_HEIGHT = 512

# List of countries - hardcoded because DirAccess doesn't work in HTML5 exports
const COUNTRIES = [
	"AE", "AF", "AL", "AM", "AO", "AR", "AT", "AU", "AZ", "BA",
	"BD", "BE", "BF", "BG", "BI", "BJ", "BN", "BO", "BR", "BS",
	"BT", "BW", "BY", "BZ", "CA", "CD", "CF", "CG", "CH", "CI",
	"CL", "CM", "CN", "CO", "CR", "CU", "CV", "CY", "CZ", "DE",
	"DJ", "DK", "DM", "DO", "DZ", "EC", "EE", "EG", "ER", "ES",
	"ET", "FI", "FK", "FR", "GA", "GB", "GE", "GH", "GL", "GM",
	"GN", "GQ", "GR", "GT", "GW", "GY", "HN", "HR", "HT", "HU",
	"ID", "IE", "IL", "IN", "IQ", "IR", "IS", "IT", "JM", "JO",
	"JP", "KE", "KG", "KH", "KM", "KP", "KR", "KW", "KZ", "LA",
	"LB", "LC", "LK", "LR", "LS", "LT", "LU", "LV", "LY", "MA",
	"MD", "ME", "MG", "MK", "ML", "MM", "MN", "MR", "MT", "MU",
	"MV", "MW", "MX", "MY", "MZ", "NA", "NC", "NE", "NG", "NI",
	"NL", "NO", "NP", "NZ", "OM", "PA", "PE", "PG", "PH", "PK",
	"PL", "PR", "PT", "PY", "QA", "RO", "RS", "RU", "RW", "SA",
	"SB", "SC", "SD", "SE", "SG", "SI", "SK", "SL", "SN", "SO",
	"SR", "SS", "ST", "SV", "SY", "SZ", "TD", "TG", "TH", "TJ",
	"TM", "TN", "TR", "TT", "TW", "TZ", "UA", "UG", "US", "UY",
	"UZ", "VC", "VE", "VN", "VU", "YE", "ZA", "ZM", "ZW"
]

# Dictionary to store sprite references by country_id
var country_sprites: Dictionary = {}

func _ready():
	_load_countries()
	# Connect to country collection signal
	GameState.country_collected.connect(_on_country_collected)

func _load_countries():
	print("[StaticMap] Loading countries from: ", ASSETS_DIR)

	# Try directory listing first (works in editor/native builds)
	var dir = DirAccess.open(ASSETS_DIR)
	var country_list = []

	if dir != null:
		var alpha_files = []
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			# Only include .png files, skip .import files
			if file_name.ends_with(".png") and not file_name.ends_with(".import"):
				alpha_files.append(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()

		if alpha_files.size() > 0:
			# Directory listing worked (editor/native)
			for alpha_file in alpha_files:
				country_list.append(alpha_file.replace(".png", ""))
		else:
			# Directory listing failed (HTML5), use hardcoded list
			print("[StaticMap] Directory listing failed, using hardcoded country list")
			country_list = COUNTRIES
	else:
		# Directory access failed, use hardcoded list
		print("[StaticMap] Directory access failed, using hardcoded country list")
		country_list = COUNTRIES
	# TODO REMOVE
	country_list = country_list.slice(0, 60)

	print("[StaticMap] Found ", country_list.size(), " countries")

	# Start loading and notify GameState
	var total = country_list.size()
	GameState.start_loading(total)

	# Load countries in batches to show progress
	var i := 0
	for country_id in country_list:
		_create_country_sprite(country_id)
		i += 1

		# Update progress
		GameState.update_loading_progress(i)

		# Yield every 5 countries to update UI
		if i % 5 == 0:
			await get_tree().process_frame

	print("[StaticMap] Created ", get_child_count(), " sprites")

	# Notify that all countries have been loaded
	GameState.finish_loading()

func _create_country_sprite(country_id: String):
	var alpha_path = ASSETS_DIR + country_id + ".png"
	var alpha_texture = load(alpha_path)

	if alpha_texture == null:
		push_error("Failed to load alpha texture: " + alpha_path)
		return

	# Check if country is already collected
	var is_collected = GameState.is_collected(country_id)

	# Use white for collected countries, random color otherwise
	var color_to_use: Color
	if is_collected:
		color_to_use = Color.WHITE
	else:
		color_to_use = Color(randf(), randf(), randf(), 1.0)

	# Create a colored texture from the alpha mask
	var alpha_image = alpha_texture.get_image()
	var colored_image = Image.create(alpha_image.get_width(), alpha_image.get_height(), false, Image.FORMAT_RGBA8)

	# Fill the image with the chosen color, using the alpha mask
	for y in range(alpha_image.get_height()):
		for x in range(alpha_image.get_width()):
			var alpha_value = alpha_image.get_pixel(x, y).a
			colored_image.set_pixel(x, y, Color(color_to_use.r, color_to_use.g, color_to_use.b, alpha_value))

	var colored_texture = ImageTexture.create_from_image(colored_image)

	var sprite = Sprite2D.new()
	sprite.texture = colored_texture
	sprite.centered = false
	sprite.position = Vector2.ZERO
	add_child(sprite)

	# Store sprite reference
	country_sprites[country_id] = sprite

	# Register color in GameState (only if not collected, white countries don't need color tracking)
	GameState.add_country(country_id)
	if not is_collected:
		GameState.register_country_color(country_id, color_to_use)

func _on_country_collected(country_id: String):
	# Update the sprite color to white when collected
	if country_id not in country_sprites:
		return

	var sprite = country_sprites[country_id]
	var alpha_path = ASSETS_DIR + country_id + ".png"
	var alpha_texture = load(alpha_path)

	if alpha_texture == null:
		return

	# Regenerate texture with white color
	var alpha_image = alpha_texture.get_image()
	var white_image = Image.create(alpha_image.get_width(), alpha_image.get_height(), false, Image.FORMAT_RGBA8)

	for y in range(alpha_image.get_height()):
		for x in range(alpha_image.get_width()):
			var alpha_value = alpha_image.get_pixel(x, y).a
			white_image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha_value))

	sprite.texture = ImageTexture.create_from_image(white_image)
