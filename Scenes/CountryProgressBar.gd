extends Control

@onready var label: Label = $CenterContainer/VBoxContainer/Label
@onready var progress_bar: ProgressBar = $CenterContainer/VBoxContainer/ProgressBar

func _ready() -> void:
	# Connect to GameState signals
	GameState.loading_started.connect(_on_loading_started)
	GameState.country_loading_progress.connect(_on_loading_progress)

func _on_loading_started(total: int) -> void:
	progress_bar.max_value = total
	progress_bar.value = 0
	label.text = "Loading countries... 0/%d" % total

func _on_loading_progress(loaded: int, total: int) -> void:
	progress_bar.value = loaded
	label.text = "Loading countries... %d/%d" % [loaded, total]
