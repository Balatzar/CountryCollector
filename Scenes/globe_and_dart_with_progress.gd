extends Node2D

@onready var progress_bar: Control = $CountryProgressBar
@onready var globe_with_dart: Node2D = $GlobeWithDart

var canvas_layer: CanvasLayer

func _ready() -> void:
	print("[GlobeAndDartWithProgress] Starting")

	# Move progress bar to a CanvasLayer so it renders on top
	canvas_layer = CanvasLayer.new()
	add_child(canvas_layer)
	progress_bar.reparent(canvas_layer)

	# Initially hide the globe and show the progress bar
	globe_with_dart.visible = false
	progress_bar.visible = true

	print("[GlobeAndDartWithProgress] Globe hidden, progress visible")

	# Connect to GameState signal for when loading completes
	GameState.countries_loaded.connect(_on_countries_loaded)

func _on_countries_loaded() -> void:
	print("[GlobeAndDartWithProgress] Countries loaded")

	# Wait a few frames to ensure all sprites are fully ready
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	# Start the rotating map (this will copy sprites and begin rotation)
	var rotating_map = globe_with_dart.get_node("RotatingStaticMap")
	if rotating_map and rotating_map.has_method("start_rotation"):
		rotating_map.start_rotation()

	# Hide progress bar and show the game
	progress_bar.visible = false
	globe_with_dart.visible = true

	print("[GlobeAndDartWithProgress] Globe visible, rotation started")

	# Clean up canvas layer after a brief delay
	await get_tree().create_timer(0.1).timeout
	if canvas_layer:
		canvas_layer.queue_free()
