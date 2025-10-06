extends Node

## Centralized audio manager for all game sound effects
## Handles playback of UI sounds and game event sounds

# Audio stream players for different sound effects
var click_player: AudioStreamPlayer
var country_collected_player: AudioStreamPlayer
var level_up_player: AudioStreamPlayer
var select_player: AudioStreamPlayer
var throw_player: AudioStreamPlayer
var miss_player: AudioStreamPlayer
var bg_player: AudioStreamPlayer

# Audio streams (preloaded)
var click_sound: AudioStream
var country_collected_sound: AudioStream
var level_up_sound: AudioStream
var select_sound: AudioStream
var throw_sound: AudioStream
var miss_sound: AudioStream
var bg_music: AudioStream

# Volume settings (in dB, 0 = full volume, -80 = silent)
const CLICK_VOLUME: float = -5.0
const COUNTRY_COLLECTED_VOLUME: float = 0.0
const LEVEL_UP_VOLUME: float = 0.0
const SELECT_VOLUME: float = -3.0
const THROW_VOLUME: float = -2.0
const MISS_VOLUME: float = -1.0
const BG_VOLUME: float = -18.0


func _ready() -> void:
	# Load audio streams
	click_sound = load("res://Assets/click.mp3")
	country_collected_sound = load("res://Assets/country_collected.mp3")
	level_up_sound = load("res://Assets/level_up.mp3")
	select_sound = load("res://Assets/select.mp3")
	throw_sound = load("res://Assets/throw.mp3")
	miss_sound = load("res://Assets/miss.mp3")
	bg_music = load("res://Assets/bg-music.mp3")
	# Ensure background music loops
	var mp3 := bg_music as AudioStreamMP3
	if mp3:
		mp3.loop = true

	# Create audio stream players
	click_player = _create_audio_player("ClickPlayer", click_sound, CLICK_VOLUME)
	country_collected_player = _create_audio_player("CountryCollectedPlayer", country_collected_sound, COUNTRY_COLLECTED_VOLUME)
	level_up_player = _create_audio_player("LevelUpPlayer", level_up_sound, LEVEL_UP_VOLUME)
	select_player = _create_audio_player("SelectPlayer", select_sound, SELECT_VOLUME)
	throw_player = _create_audio_player("ThrowPlayer", throw_sound, THROW_VOLUME)
	miss_player = _create_audio_player("MissPlayer", miss_sound, MISS_VOLUME)
	bg_player = _create_audio_player("BackgroundMusic", bg_music, BG_VOLUME)
	if bg_player and not bg_player.playing:
		bg_player.play()

	# Connect to GameState signals for game events
	GameState.country_collected.connect(_on_country_collected)
	GameState.dart_thrown.connect(_on_dart_thrown)

	print("[AudioManager] Audio system initialized")


func _create_audio_player(player_name: String, stream: AudioStream, volume_db: float) -> AudioStreamPlayer:
	"""Create and configure an AudioStreamPlayer"""
	var player := AudioStreamPlayer.new()
	player.name = player_name
	player.stream = stream
	player.volume_db = volume_db
	player.bus = "Master"
	add_child(player)
	return player


# --- Public API for playing sounds ---

func play_click() -> void:
	"""Play UI click sound (for buttons and general UI interactions)"""
	if click_player and not click_player.playing:
		click_player.play()


func play_country_collected() -> void:
	"""Play country collected sound"""
	if country_collected_player:
		country_collected_player.play()


func play_level_up() -> void:
	"""Play level up / store opening sound"""
	if level_up_player:
		level_up_player.play()


func play_select() -> void:
	"""Play select sound (for ability card selection)"""
	if select_player:
		select_player.play()


func play_throw() -> void:
	"""Play dart throw sound"""
	if throw_player:
		throw_player.play()


func play_miss() -> void:
	"""Play dart miss sound"""
	if miss_player:
		miss_player.play()


# --- Signal handlers ---

func _on_country_collected(_country_id: String) -> void:
	"""Handle country collected event from GameState"""
	play_country_collected()


func _on_dart_thrown() -> void:
	"""Handle dart thrown event from GameState"""
	play_throw()

