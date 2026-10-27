class_name PuzzleRoom
extends Node2D
## Script de base d'une salle jouable (remplace le raycast de `CustomCursor` côté Unity).
##
## Tant que la salle est [member active] :
## - elle cherche, parmi ses [PuzzleInstance], celui qui est sous la souris
##   (le plus haut dans l'ordre d'affichage gagne) et le met en surbrillance ;
## - clic gauche : [method PuzzleInstance.interact] avec l'objet en main ;
## - clic droit : lâche l'objet en main.
##
## Dans le jeu, les salles sont des enfants du monde (`Scenes/World/world.tscn`), qui les
## active à l'arrivée de la caméra et appelle [method on_enter]. Lancée seule ([kbd]F6[/kbd]),
## une salle s'active d'elle-même pour pouvoir la tester sans passer par le monde.
##
## Pour créer une salle : une scène dont la racine utilise ce script (ou un script qui en
## hérite, comme `weather.gd`), avec les [PuzzleInstance] n'importe où en dessous.
##
## En build de debug, [kbd]F9[/kbd] ajoute [member debug_items] à l'inventaire pour tester
## une énigme sans refaire toutes les précédentes.

## Musiques de la salle (des [AudioStream]), jouées en boucle dans l'ordre. Voir `Audio`.
@export var music: Array[AudioStream] = []
## Objets donnés par [kbd]F9[/kbd] en build de debug (des [PuzzleObject]).
@export var debug_items: Array[Resource] = []

@export_group("Accès")
## Objets (des [PuzzleObject]) nécessaires pour entrer la première fois dans la salle.
## Ils sont retirés de l'inventaire au déverrouillage. Vide = salle libre.
@export var required_items: Array[Resource] = []
## Réplique quand il manque un des [member required_items].
@export_multiline var locked_message: String = "C'est fermé."
## Réplique au déverrouillage.
@export_multiline var unlock_message: String = ""

## Vrai quand le joueur peut interagir avec la salle.
var active: bool = false:
	set(value):
		active = value
		if not value:
			_set_hovered(null)
			Hud.set_hover_target(null)

var _hovered: PuzzleInstance = null


func _ready() -> void:
	# Salle lancée seule (F6) : pas de monde pour l'activer.
	if get_parent() == get_tree().root:
		Hud.set_room_active(true)
		Audio.play_music(music)
		active = true
		on_enter()


func _exit_tree() -> void:
	if active:
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)


## Appelé par le monde quand la caméra part vers cette salle (avant qu'elle soit active).
## À surcharger pour préparer la salle (ex. changer la météo).
func on_enter() -> void:
	pass


## Vrai si on peut entrer. Au premier passage avec tous les [member required_items],
## les consomme, mémorise l'ouverture et affiche [member unlock_message].
## Sinon affiche [member locked_message].
func try_unlock() -> bool:
	if required_items.is_empty() or GameState.get_flag(_unlock_flag(), false):
		return true
	for item in required_items:
		if not GameState.has_item(item as PuzzleObject):
			GameState.fail(locked_message)
			return false
	for item in required_items:
		GameState.remove_item(item as PuzzleObject)
	GameState.set_flag(_unlock_flag(), true)
	if not unlock_message.is_empty():
		GameState.show_message(unlock_message)
	GameState.interaction_result.emit(&"unlock")
	return true


func _process(_delta: float) -> void:
	if not active:
		return
	# Fait à chaque image (et pas seulement quand la souris bouge) pour suivre
	# les objets qui apparaissent ou disparaissent sous un curseur immobile.
	# Rien n'est survolé quand la souris est sur l'interface (barre d'inventaire).
	_set_hovered(null if Hud.is_mouse_over_ui() else _pick(get_global_mouse_position()))
	# L'état de l'objet survolé peut changer après un clic : on rafraîchit l'infobulle.
	Hud.set_hover_target(_hovered.state if _hovered != null else null)


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	var mouse_event := event as InputEventMouseButton
	var key_event := event as InputEventKey
	if mouse_event != null and mouse_event.pressed:
		match mouse_event.button_index:
			MOUSE_BUTTON_LEFT:
				if _hovered != null:
					_hovered.interact(GameState.selected_item)
					get_viewport().set_input_as_handled()
			MOUSE_BUTTON_RIGHT:
				GameState.select_item(null)
				get_viewport().set_input_as_handled()
	elif OS.is_debug_build() and key_event != null and key_event.pressed and key_event.keycode == KEY_F9:
		for item in debug_items:
			if item is PuzzleObject:
				GameState.add_item(item)
		GameState.show_message("[debug] %d objet(s) ajouté(s)." % debug_items.size())


## Renvoie l'objet cliquable sous [param global_point], ou [code]null[/code].
func _pick(global_point: Vector2) -> PuzzleInstance:
	# get_nodes_in_group renvoie les nœuds dans l'ordre de l'arbre, donc du plus
	# en arrière au plus en avant : on parcourt à l'envers.
	var instances := get_tree().get_nodes_in_group(PuzzleInstance.GROUP)
	for i in range(instances.size() - 1, -1, -1):
		var instance := instances[i] as PuzzleInstance
		if instance != null and is_ancestor_of(instance) and instance.contains_global_point(global_point):
			return instance
	return null


func _set_hovered(instance: PuzzleInstance) -> void:
	if instance == _hovered:
		return
	if _hovered != null and is_instance_valid(_hovered):
		_hovered.hovered = false
	_hovered = instance
	if _hovered != null:
		_hovered.hovered = true
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if _hovered != null else Input.CURSOR_ARROW)


func _unlock_flag() -> StringName:
	return StringName("unlocked:" + scene_file_path)
