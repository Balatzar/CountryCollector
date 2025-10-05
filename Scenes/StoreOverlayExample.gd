extends Node2D

## Example scene demonstrating how to use the StoreOverlay
## This shows how to integrate the store into your game

@onready var store_overlay: CanvasLayer = $StoreOverlay
@onready var open_store_button: Button = $UI/OpenStoreButton
@onready var info_label: Label = $UI/InfoLabel


func _ready() -> void:
	# Connect button to open store
	open_store_button.pressed.connect(_on_open_store_pressed)
	
	# Connect to GameState signals
	GameState.store_opened.connect(_on_store_opened)
	GameState.card_acquired.connect(_on_card_acquired)
	
	# Connect to store overlay signals
	store_overlay.card_selected.connect(_on_card_selected_from_store)
	store_overlay.store_closed.connect(_on_store_closed)
	
	_update_info_label()


func _on_open_store_pressed() -> void:
	"""Open the store when button is pressed"""
	# You can either call the store directly or use GameState signal
	store_overlay.show_store()
	# Or: GameState.open_store()


func _on_store_opened() -> void:
	"""Handle store opened signal from GameState"""
	print("[Example] Store opened via GameState signal")
	store_overlay.show_store()


func _on_card_selected_from_store(card_data: Dictionary) -> void:
	"""Handle card selection from the store overlay"""
	print("[Example] Card selected from store: ", card_data.name)
	
	# Acquire the card through GameState
	GameState.acquire_card(card_data)


func _on_card_acquired(card_data: Dictionary) -> void:
	"""Handle card acquisition from GameState"""
	print("[Example] Card acquired: ", card_data.name)
	_update_info_label()
	
	# Here you would apply the card's effects
	# For example:
	# - Increase darts
	# - Modify accuracy
	# - Add time
	# etc.


func _on_store_closed() -> void:
	"""Handle store closing"""
	print("[Example] Store closed")


func _update_info_label() -> void:
	"""Update the info label with current card count"""
	var card_count := GameState.acquired_cards.size()
	info_label.text = "Cards Acquired: %d\nPress button to open store" % card_count

