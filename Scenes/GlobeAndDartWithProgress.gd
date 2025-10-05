extends Node2D

@onready var progress_bar: Control = $CountryProgressBar
@onready var globe_with_dart: Node2D = $GlobeWithDart

func _ready() -> void:
	# Initially hide the globe and show the progress bar
	globe_with_dart.visible = false
	progress_bar.visible = true

	# Connect to GameState signal for when loading completes
	GameState.countries_loaded.connect(_on_countries_loaded)

func _on_countries_loaded() -> void:
	# Hide progress bar and show the game
	progress_bar.visible = false
	globe_with_dart.visible = true
