extends Node

# Signals
signal countries_loaded()
signal country_collected(country_id: String)

# List of all countries in the game
var all_countries: Array[String] = []

# List of countries the player has collected
var collected_countries: Array[String] = []


func _ready() -> void:
	pass


# Add a country to the list of all countries
func add_country(country_id: String) -> void:
	if country_id not in all_countries:
		all_countries.append(country_id)


# Mark a country as collected
func collect_country(country_id: String) -> void:
	if country_id not in collected_countries:
		collected_countries.append(country_id)
		country_collected.emit(country_id)


# Notify that all countries have been loaded
func notify_countries_loaded() -> void:
	countries_loaded.emit()


# Check if a country has been collected
func is_collected(country_id: String) -> bool:
	return country_id in collected_countries


# Get the number of collected countries
func get_collected_count() -> int:
	return collected_countries.size()


# Get the total number of countries
func get_total_countries() -> int:
	return all_countries.size()


# Reset the game state
func reset() -> void:
	collected_countries.clear()
