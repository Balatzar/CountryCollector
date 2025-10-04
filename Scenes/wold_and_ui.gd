extends Node2D

@onready var collected_countries_list: ItemList = $CollectedCountries
@onready var to_find_countries_list: ItemList = $ToFindCountries


func _ready() -> void:
	GameState.countries_loaded.connect(_on_countries_loaded)
	GameState.country_collected.connect(_on_country_collected)

	# If countries are already loaded, refresh immediately
	if GameState.all_countries.size() > 0:
		refresh_country_lists()


func _on_countries_loaded() -> void:
	refresh_country_lists()


func _on_country_collected(_country_id: String) -> void:
	refresh_country_lists()


func refresh_country_lists() -> void:

	# Collected countries
	collected_countries_list.clear()
	for country in GameState.collected_countries:
		collected_countries_list.add_item(country)

	# Countries to find (all - collected)
	to_find_countries_list.clear()
	for country in GameState.all_countries:
		if country not in GameState.collected_countries:
			to_find_countries_list.add_item(country)
