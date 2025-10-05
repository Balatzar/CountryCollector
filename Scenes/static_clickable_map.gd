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

func _ready():
	_load_countries()

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
