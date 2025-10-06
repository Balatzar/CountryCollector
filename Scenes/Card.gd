extends PanelContainer

## Reusable card component for the store system
## Displays card name, bonuses, maluses, and a selection button

# Signals
signal card_selected(card_data: Dictionary)

# Card data structure
var card_data: Dictionary = {
	"name": "Card Name",
	"bonuses": [],  # Array of bonus strings
	"maluses": []   # Array of malus strings
}

# Node references
@onready var bonus_container: VBoxContainer = $CardVBox/BonusSection/BonusContainer
@onready var malus_container: VBoxContainer = $CardVBox/MalusSection/MalusContainer
@onready var select_button: Button = $CardVBox/SelectButton

# Hover effect variables
var is_hovered: bool = false
var hover_tilt_strength: float = 15.0  # Maximum tilt angle in degrees
var hover_scale: float = 1.05  # Scale when hovered
var hover_damping: float = 0.15  # Smoothing factor
var current_rotation: float = 0.0
var current_scale: Vector2 = Vector2.ONE
var mouse_relative_pos: Vector2 = Vector2.ZERO


func _ready() -> void:
	# Connect button signal
	select_button.pressed.connect(_on_select_button_pressed)
	
	# Connect mouse events for hover effect
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# Set pivot to center for proper rotation
	pivot_offset = size / 2.0
	
	# Initialize card display
	_update_card_display()


func _process(_delta: float) -> void:
	if is_hovered:
		_update_hover_effect()
	else:
		_reset_hover_effect()


func set_card_data(data: Dictionary) -> void:
	"""Set the card data and update the display"""
	card_data = data
	if is_node_ready():
		_update_card_display()


func _update_card_display() -> void:
	"""Update all card UI elements based on card_data"""
	# Clear existing bonus/malus labels
	for child in bonus_container.get_children():
		child.queue_free()
	for child in malus_container.get_children():
		child.queue_free()

	# Add bonus labels
	var bonuses: Array = card_data.get("bonuses", [])
	for bonus in bonuses:
		# Bonus can be either a string or a dictionary
		var bonus_text := ""
		if bonus is String:
			bonus_text = str(bonus)
		elif bonus is Dictionary:
			# Display only the description (not the name)
			bonus_text = bonus.get("description", "")

		var label := Label.new()
		label.text = bonus_text
		label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))  # Green
		label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		label.add_theme_constant_override("outline_size", 4)
		label.add_theme_font_size_override("font_size", 28)  # 2x bigger (was 14)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		bonus_container.add_child(label)

	# Add malus labels
	var maluses: Array = card_data.get("maluses", [])
	for malus in maluses:
		# Malus can be either a string or a dictionary
		var malus_text := ""
		if malus is String:
			malus_text = str(malus)
		elif malus is Dictionary:
			# Display only the description (not the name)
			malus_text = malus.get("description", "")

		var label := Label.new()
		label.text = malus_text
		label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))  # Red
		label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		label.add_theme_constant_override("outline_size", 4)
		label.add_theme_font_size_override("font_size", 28)  # 2x bigger (was 14)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		malus_container.add_child(label)


func _on_select_button_pressed() -> void:
	"""Emit signal when card is selected"""
	# Play select sound effect
	AudioManager.play_select()

	card_selected.emit(card_data)

	# Add a quick scale animation on press
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(0.95, 0.95), 0.1)
	tween.tween_property(self, "scale", Vector2.ONE, 0.1)


func _on_mouse_entered() -> void:
	"""Handle mouse entering the card"""
	is_hovered = true


func _on_mouse_exited() -> void:
	"""Handle mouse leaving the card"""
	is_hovered = false


func _update_hover_effect() -> void:
	"""Apply 3D-like hover effect using 2D transformations"""
	# Get mouse position relative to card center
	var local_mouse_pos := get_local_mouse_position()
	var card_center := size / 2.0
	mouse_relative_pos = (local_mouse_pos - card_center) / card_center
	
	# Clamp to prevent extreme values
	mouse_relative_pos.x = clamp(mouse_relative_pos.x, -1.0, 1.0)
	mouse_relative_pos.y = clamp(mouse_relative_pos.y, -1.0, 1.0)
	
	# Calculate target rotation based on mouse position
	# Tilt opposite to mouse position for 3D effect
	var target_rotation := -mouse_relative_pos.x * hover_tilt_strength
	
	# Smooth rotation
	current_rotation = lerp(current_rotation, target_rotation, hover_damping)
	rotation_degrees = current_rotation
	
	# Smooth scale
	var target_scale := Vector2(hover_scale, hover_scale)
	current_scale = current_scale.lerp(target_scale, hover_damping)
	scale = current_scale


func _reset_hover_effect() -> void:
	"""Reset hover effect when mouse leaves"""
	# Smooth return to normal state
	current_rotation = lerp(current_rotation, 0.0, hover_damping)
	rotation_degrees = current_rotation
	
	current_scale = current_scale.lerp(Vector2.ONE, hover_damping)
	scale = current_scale
	
	# Reset completely when close enough
	if abs(current_rotation) < 0.1 and current_scale.distance_to(Vector2.ONE) < 0.01:
		rotation_degrees = 0.0
		scale = Vector2.ONE
		current_rotation = 0.0
		current_scale = Vector2.ONE
