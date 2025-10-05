extends Control


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		# Cmd+; for XP (semicolon key)
		if event.keycode == KEY_SEMICOLON and event.meta_pressed:
			GameState.add_xp(50)
			get_viewport().set_input_as_handled()

		# Cmd+' for level (apostrophe key)
		elif event.keycode == KEY_APOSTROPHE and event.meta_pressed:
			GameState.add_xp(GameState.XP_PER_LEVEL)
			get_viewport().set_input_as_handled()
