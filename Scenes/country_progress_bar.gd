extends Control

@onready var label: Label = $Label
@onready var progress_bar: ProgressBar = $ProgressBar

func _ready() -> void:
	print("[CountryProgressBar] Ready")

	# Set up UI layout
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	progress_bar.custom_minimum_size = Vector2(400, 30)

	# Connect to GameState signals
	GameState.loading_started.connect(_on_loading_started)
	GameState.country_loading_progress.connect(_on_loading_progress)

	# Use anchors to center elements
	_setup_centering()

func _setup_centering() -> void:
	# Center label
	label.anchor_left = 0.5
	label.anchor_right = 0.5
	label.anchor_top = 0.5
	label.anchor_bottom = 0.5
	label.offset_left = -200
	label.offset_right = 200
	label.offset_top = -60
	label.offset_bottom = -30
	label.grow_horizontal = GROW_DIRECTION_BOTH
	label.grow_vertical = GROW_DIRECTION_BOTH

	# Center progress bar
	progress_bar.anchor_left = 0.5
	progress_bar.anchor_right = 0.5
	progress_bar.anchor_top = 0.5
	progress_bar.anchor_bottom = 0.5
	progress_bar.offset_left = -200
	progress_bar.offset_right = 200
	progress_bar.offset_top = -15
	progress_bar.offset_bottom = 15
	progress_bar.grow_horizontal = GROW_DIRECTION_BOTH
	progress_bar.grow_vertical = GROW_DIRECTION_BOTH

func _on_loading_started(total: int) -> void:
	print("[CountryProgressBar] Loading started: ", total)
	progress_bar.max_value = 100
	progress_bar.value = 0
	label.text = "Loading countries... 0/%d" % total

func _on_loading_progress(loaded: int, total: int) -> void:
	var percentage = int((float(loaded) / float(total)) * 100.0)
	print("[CountryProgressBar] Progress: %d/%d (%d%%)" % [loaded, total, percentage])
	progress_bar.value = percentage
	label.text = "Loading countries... %d/%d" % [loaded, total]
