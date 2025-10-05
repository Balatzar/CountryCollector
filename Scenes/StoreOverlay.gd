extends CanvasLayer

## Store overlay for displaying and selecting bonus cards
## Generates random power-up cards with bonuses and maluses

# Signals
signal card_selected(card_data: Dictionary)
signal store_closed()

# Card scene reference
const CARD_SCENE := preload("res://Scenes/Card.tscn")

# Node references
@onready var dimmer: ColorRect = $Dimmer
@onready var level_up_label: Label = $CenterContainer/VBox/LevelUpLabel
@onready var cards_container: HBoxContainer = $CenterContainer/VBox/CardsContainer

# Card instances
var card_instances: Array[Node] = []

# Current card choices generated for this store view
var current_choices: Array[Dictionary] = []


func _ready() -> void:
	# Initially hide the overlay
	hide()

	# Setup dimmer click to close (optional)
	dimmer.gui_input.connect(_on_dimmer_input)


func show_store() -> void:
	"""Display the store with randomly generated power-up cards"""
	# Clear existing cards
	_clear_cards()

	# Generate card choices from GameState
	current_choices = GameState.generate_card_choices(2)

	# Create card instances for each choice
	for i in range(current_choices.size()):
		var card_choice = current_choices[i]
		var card_instance := CARD_SCENE.instantiate()
		cards_container.add_child(card_instance)

		# Convert the card format to match what Card expects
		var card_data = _format_card_for_display(card_choice)
		# Store the original choice in the display data for later retrieval
		card_data["_original_choice"] = card_choice
		card_instance.set_card_data(card_data)
		card_instance.card_selected.connect(_on_card_selected)
		card_instances.append(card_instance)

	# Show overlay with animation
	show()
	_animate_entrance()


func _format_card_for_display(card_choice: Dictionary) -> Dictionary:
	"""Convert power-up card format to display format"""
	var bonuses: Array = []
	var maluses: Array = []

	# Extract bonus dictionary (with name and description)
	if card_choice.has("bonus") and not card_choice["bonus"].is_empty():
		bonuses.append(card_choice["bonus"])

	# Extract malus dictionary (with name and description)
	if card_choice.has("malus") and not card_choice["malus"].is_empty():
		maluses.append(card_choice["malus"])

	return {
		"name": "Power-Up Card",
		"bonuses": bonuses,
		"maluses": maluses
	}


func hide_store() -> void:
	"""Hide the store overlay"""
	_animate_exit()


func _clear_cards() -> void:
	"""Remove all card instances"""
	for card in card_instances:
		if is_instance_valid(card):
			card.queue_free()
	card_instances.clear()

	# Also clear any remaining children in container
	for child in cards_container.get_children():
		child.queue_free()


func _on_card_selected(display_data: Dictionary) -> void:
	"""Handle card selection - retrieve the original power-up data from display data"""
	print("[StoreOverlay] Card selected")

	# Retrieve the original card choice from the display data
	if not display_data.has("_original_choice"):
		push_error("[StoreOverlay] Card data missing original choice!")
		return

	var card_choice: Dictionary = display_data["_original_choice"]

	# Store both the bonus and malus in GameState
	if card_choice.has("bonus") and not card_choice["bonus"].is_empty():
		GameState.acquire_card(card_choice["bonus"])
		print("[StoreOverlay] Acquired bonus: ", card_choice["bonus"].get("name", "Unknown"))

	if card_choice.has("malus") and not card_choice["malus"].is_empty():
		GameState.acquire_card(card_choice["malus"])
		print("[StoreOverlay] Acquired malus: ", card_choice["malus"].get("name", "Unknown"))

	# Emit signal with the full card choice
	card_selected.emit(card_choice)

	# Close the store
	hide_store()


func _on_dimmer_input(event: InputEvent) -> void:
	"""Handle clicks on the dimmer background"""
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# Optional: close store when clicking outside cards
			# Uncomment the line below to enable this behavior
			# hide_store()
			pass


func _animate_entrance() -> void:
	"""Animate the store entrance"""
	# Start with dimmer transparent and cards scaled down
	dimmer.modulate.a = 0.0
	level_up_label.modulate.a = 0.0
	card_instances[0].modulate.a = 0.0
	card_instances[0].scale = Vector2(0.5, 0.5)
	card_instances[1].modulate.a = 0.0
	card_instances[1].scale = Vector2(0.5, 0.5)

	# Animate dimmer fade in
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(dimmer, "modulate:a", 1.0, 0.3)

	# Animate LEVEL UP label - simple fade in
	tween.tween_property(level_up_label, "modulate:a", 1.0, 0.3)

	# Animate first card
	tween.tween_property(card_instances[0], "modulate:a", 1.0, 0.4).set_delay(0.3)
	tween.tween_property(card_instances[0], "scale", Vector2.ONE, 0.4).set_delay(0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Animate second card
	tween.tween_property(card_instances[1], "modulate:a", 1.0, 0.4).set_delay(0.4)
	tween.tween_property(card_instances[1], "scale", Vector2.ONE, 0.4).set_delay(0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Start subtle border animation
	_animate_level_up_border()


func _animate_exit() -> void:
	"""Animate the store exit"""
	var tween := create_tween()
	tween.set_parallel(true)

	# Fade out dimmer
	tween.tween_property(dimmer, "modulate:a", 0.0, 0.2)

	# Fade out level up label
	tween.tween_property(level_up_label, "modulate:a", 0.0, 0.2)

	# Fade out and scale down first card
	tween.tween_property(card_instances[0], "modulate:a", 0.0, 0.2)
	tween.tween_property(card_instances[0], "scale", Vector2(0.8, 0.8), 0.2)

	# Fade out and scale down second card
	tween.tween_property(card_instances[1], "modulate:a", 0.0, 0.2)
	tween.tween_property(card_instances[1], "scale", Vector2(0.8, 0.8), 0.2)

	# Hide after animation completes
	tween.tween_callback(func():
		hide()
		store_closed.emit()
	).set_delay(0.2)



func _animate_level_up_border() -> void:
	"""Simple border color animation from orange to dark orange"""
	var border_tween := create_tween()
	border_tween.set_loops()

	# Subtle outline color shift: orange to dark orange
	border_tween.tween_property(level_up_label, "theme_override_colors/font_outline_color", Color(1.0, 0.5, 0.0, 1.0), 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	border_tween.tween_property(level_up_label, "theme_override_colors/font_outline_color", Color(0.6, 0.3, 0.0, 1.0), 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
