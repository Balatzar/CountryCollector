extends HBoxContainer

## UI component for zoom level selection buttons
## Implements radio button behavior (only one selected at a time)

signal zoom_level_changed(level: int)

# Button references
var button_1: Button
var button_2: Button
var button_3: Button

# Current selection
var current_level: int = 1


func _ready() -> void:
	# Create the three zoom level buttons
	button_1 = _create_zoom_button("1", 1)
	button_2 = _create_zoom_button("2", 2)
	button_3 = _create_zoom_button("3", 3)
	
	add_child(button_1)
	add_child(button_2)
	add_child(button_3)
	
	# Set initial selection
	_update_button_states()


func _create_zoom_button(label: String, level: int) -> Button:
	"""Create a styled zoom level button"""
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(60, 60)
	
	# Style the button
	button.add_theme_font_size_override("font_size", 32)
	
	# Connect the pressed signal
	button.pressed.connect(_on_button_pressed.bind(level))
	
	return button


func _on_button_pressed(level: int) -> void:
	"""Handle button press - update selection and emit signal"""
	if current_level == level:
		return  # Already selected
	
	current_level = level
	_update_button_states()
	zoom_level_changed.emit(level)
	print("[ZoomLevelButtons] Zoom level changed to: ", level)


func _update_button_states() -> void:
	"""Update button visual states based on current selection"""
	_set_button_selected(button_1, current_level == 1)
	_set_button_selected(button_2, current_level == 2)
	_set_button_selected(button_3, current_level == 3)


func _set_button_selected(button: Button, selected: bool) -> void:
	"""Apply visual styling to show selected/unselected state"""
	if selected:
		# Selected state - bright gold color
		button.add_theme_color_override("font_color", Color(1.0, 0.7, 0.1, 1.0))
		button.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		button.add_theme_constant_override("outline_size", 4)
	else:
		# Unselected state - dimmed white
		button.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1.0))
		button.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		button.add_theme_constant_override("outline_size", 2)

