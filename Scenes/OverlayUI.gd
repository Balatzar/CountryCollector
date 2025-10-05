extends Control

# -- VARIABLES --
# On définit les variables qui contiendront nos données.
# Le mot-clé 'export' les rend modifiables depuis l'Inspecteur.
@export var remaining_darts: int = 10
@export var collected_countries: int = 0
@export var countdown_time: int = 60

# -- RÉFÉRENCES AUX NŒUDS --
# On crée des références à nos Labels pour y accéder plus facilement.
# Le signe '$' est un raccourci pour get_node().
@onready var darts_label: Label = $VBoxContainer/DartsLabel
@onready var countries_label: Label = $VBoxContainer/CountriesLabel
@onready var timer_label: Label = $VBoxContainer/TimerLabel
@onready var countdown_timer: Timer = $CountdownTimer

# Reference to CountryNames for displaying full country names
const CountryNames = preload("res://CountryNames.gd")

# -- FONCTION D'INITIALISATION --
# Cette fonction est appelée une seule fois lorsque le nœud entre dans la scène.
func _ready():
	# On met à jour l'affichage initial avec les valeurs par défaut.
	update_darts_display()
	update_countries_display()
	update_timer_display()

	# On connecte le signal 'timeout' du Timer à notre fonction de mise à jour.
	countdown_timer.timeout.connect(_on_countdown_timer_timeout)

	# Connect to GameState signals to display country names when collected
	GameState.country_collected.connect(_on_country_collected)


# -- FONCTIONS DE MISE À JOUR DE L'AFFICHAGE --

# Met à jour le texte du label des fléchettes.
func update_darts_display():
	darts_label.text = "Fléchettes restantes : %s" % remaining_darts

# Met à jour le texte du label des pays.
func update_countries_display():
	countries_label.text = "Pays collectés : %s" % collected_countries

# Met à jour le texte du label du timer.
func update_timer_display():
	timer_label.text = "Temps restant : %s" % countdown_time


# -- GESTION DU TIMER --

# Cette fonction est appelée à chaque fois que le Timer atteint 0 (toutes les secondes).
func _on_countdown_timer_timeout():
	# On décrémente le temps.
	countdown_time -= 1

	# On met à jour l'affichage.
	update_timer_display()

	# Si le temps est écoulé...
	if countdown_time <= 0:
		# On arrête le timer pour qu'il ne devienne pas négatif.
		countdown_timer.stop()
		print("Le temps est écoulé !")
		# Ici, vous pourriez ajouter la logique de fin de partie.
		# Par exemple : get_tree().change_scene_to_file("res://game_over_screen.tscn")

# -- GESTION DES PAYS COLLECTÉS --

# Called when a country is collected to display its full name
func _on_country_collected(country_id: String):
	var country_name = CountryNames.get_country_name(country_id)
	print("Pays collecté : %s (%s)" % [country_name, country_id])
