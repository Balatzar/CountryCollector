extends Node2D

## Test scene for demonstrating the bonus/malus display feature in GameOverlay

# Node references
@onready var store_overlay: CanvasLayer = $StoreOverlay
@onready var open_store_button: Button = $UI/OpenStoreButton
@onready var info_label: Label = $UI/InfoLabel

# Test cards with various bonus/malus combinations
var test_cards: Array[Dictionary] = [
	{
		"name": "Eagle Eye",
		"bonuses": ["Increased accuracy", "Larger hit radius"],
		"maluses": ["Slower throw speed"]
	},
	{
		"name": "Extra Darts",
		"bonuses": ["+3 darts"],
		"maluses": ["Reduced accuracy"]
	},
	{
		"name": "Time Freeze",
		"bonuses": ["+30 seconds"],
		"maluses": ["-2 darts"]
	}
]

var current_card_index: int = 0


func _ready() -> void:
	# Connect button to open store
	open_store_button.pressed.connect(_on_open_store_pressed)
	
	# Connect to GameState signals
	GameState.card_acquired.connect(_on_card_acquired)
	
	# Connect to store overlay signals
	store_overlay.card_selected.connect(_on_card_selected_from_store)
	
	_update_info_label()


func _on_open_store_pressed() -> void:
	"""Open the store when button is pressed"""
	store_overlay.show_store()


func _on_card_selected_from_store(card_data: Dictionary) -> void:
	"""Handle card selection from the store overlay"""
	print("[BonusMalusTest] Card selected from store: ", card_data.name)
	
	# Acquire the card through GameState
	GameState.acquire_card(card_data)


func _on_card_acquired(card_data: Dictionary) -> void:
	"""Handle card acquisition from GameState"""
	print("[BonusMalusTest] Card acquired: ", card_data.name)
	_update_info_label()


func _update_info_label() -> void:
	"""Update the info label with current card count"""
	var acquired_count := GameState.get_acquired_cards().size()
	info_label.text = "Cards Acquired: %d\nPress button to open store\n\nCheck left side for bonus/malus display!" % acquired_count

