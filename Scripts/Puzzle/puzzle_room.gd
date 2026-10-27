class_name PuzzleRoom
extends Node2D
## Script de base d'une salle jouable (remplace le raycast de `CustomCursor` côté Unity).
##
## - cherche, parmi les [PuzzleInstance] de la salle, celui qui est sous la souris
##   (le plus haut dans l'ordre d'affichage gagne) et le met en surbrillance ;
## - clic gauche : [method PuzzleInstance.interact] avec l'objet en main ;
## - clic droit : lâche l'objet en main ;
## - affiche le HUD (inventaire, dialogue, curseur) tant que la salle est ouverte.
##
## Pour créer une salle : une scène dont la racine utilise ce script (ou un script qui en
## hérite, comme `witch.gd`), avec les [PuzzleInstance] n'importe où en dessous.
##
## En build de debug, [kbd]F9[/kbd] ajoute [member debug_items] à l'inventaire pour tester
## les énigmes dont les objets viennent de salles pas encore portées.

## Objets donnés par [kbd]F9[/kbd] en build de debug (des [PuzzleObject]).
@export var debug_items: Array[Resource] = []

var _hovered: PuzzleInstance = null


func _ready() -> void:
	Hud.set_room_active(true)


func _exit_tree() -> void:
	Hud.set_room_active(false)
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)


func _process(_delta: float) -> void:
	# Fait à chaque image (et pas seulement quand la souris bouge) pour suivre
	# les objets qui apparaissent ou disparaissent sous un curseur immobile.
	# Rien n'est survolé quand la souris est sur l'interface (barre d'inventaire).
	_set_hovered(null if Hud.is_mouse_over_ui() else _pick(get_global_mouse_position()))
	# L'état de l'objet survolé peut changer après un clic : on rafraîchit l'infobulle.
	Hud.set_hover_target(_hovered.state if _hovered != null else null)


func _unhandled_input(event: InputEvent) -> void:
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
