@tool
class_name PuzzleInstance
extends Sprite2D
## Un objet cliquable posé dans une salle (équivalent du MonoBehaviour Unity `PuzzleInstance`).
##
## Le nœud affiche la [member PuzzleObject.texture] de son état courant et applique les
## [PuzzleInteraction] quand on clique dessus. Il ne lit pas la souris lui-même :
## c'est [PuzzleRoom] qui détermine l'objet survolé et appelle [method interact].
##
## Zone cliquable :
## - si [member hit_rect] est défini, c'est ce rectangle (coordonnées locales du nœud) ;
## - sinon, les pixels non transparents de la texture. Comme les overlays sont plein cadre,
##   la zone épouse exactement le dessin, sans forme de collision à tracer.
##
## L'état est enregistré dans [GameState] à chaque changement et restauré au chargement
## de la salle. Le nœud est [code]@tool[/code] pour afficher l'état initial dans l'éditeur.

## Émis après chaque changement d'état (pas lors de la restauration au chargement).
signal state_changed(new_state: PuzzleObject)
## Émis quand l'objet disparaît de la salle.
signal removed

## Groupe dans lequel [PuzzleRoom] cherche les objets cliquables.
const GROUP := &"puzzle_instances"
## Teinte appliquée au survol.
const HOVER_MODULATE := Color(1.25, 1.2, 1.0)

## État au début de la partie.
@export var initial_state: PuzzleObject:
	set(value):
		initial_state = value
		if Engine.is_editor_hint():
			_refresh_visual(value)
## Zone cliquable en coordonnées locales. Laisser vide (taille 0) pour utiliser
## les pixels opaques de la texture. Obligatoire pour un état sans texture.
@export var hit_rect: Rect2 = Rect2()

## État courant.
var state: PuzzleObject
## Vrai quand la souris est sur l'objet (géré par [PuzzleRoom]).
var hovered: bool = false:
	set(value):
		hovered = value
		modulate = HOVER_MODULATE if value else Color.WHITE

var _removed: bool = false


func _ready() -> void:
	if Engine.is_editor_hint():
		_refresh_visual(initial_state)
		return
	add_to_group(GROUP)
	var saved := GameState.get_instance_state(get_state_key())
	if saved.is_empty():
		state = initial_state
	else:
		state = saved.state
		_removed = saved.removed
	visible = not _removed
	_refresh_visual(state)


## Applique l'interaction correspondant à [param held] (objet en main, ou [code]null[/code]).
## Voir [PuzzleInteraction] pour le détail des étapes.
func interact(held: PuzzleObject) -> void:
	if state == null:
		return
	var interaction := state.find_interaction(held)
	if interaction == null:
		if held == null:
			GameState.play_feedback(state)
		else:
			var text := state.wrong_item_message
			GameState.fail(text if not text.is_empty() else GameState.DEFAULT_WRONG_ITEM_MESSAGE)
		return
	if not interaction.accepted:
		var text := interaction.message
		GameState.fail(text if not text.is_empty() else GameState.DEFAULT_REFUSED_MESSAGE)
		return

	# Objet dont on affiche le message : l'objet reçu, sinon le nouvel état, sinon l'état actuel.
	var feedback_object := state
	if interaction.next_state != null and not interaction.remove_instance:
		feedback_object = interaction.next_state
	if interaction.give_item != null:
		feedback_object = interaction.give_item

	if held != null and interaction.consume_item:
		GameState.remove_item(held)
	if interaction.give_item != null:
		GameState.add_item(interaction.give_item)
	if interaction.remove_instance:
		remove()
	elif interaction.next_state != null:
		set_state(interaction.next_state)
	GameState.select_item(null)
	var result := &"pickup" if interaction.give_item != null else &"success"
	GameState.play_feedback(feedback_object, interaction.message, result)


## Passe à [param new_state] et l'enregistre dans [GameState].
func set_state(new_state: PuzzleObject) -> void:
	state = new_state
	_refresh_visual(state)
	GameState.store_instance_state(get_state_key(), state, _removed)
	state_changed.emit(state)


## Fait disparaître l'objet de la salle (définitivement pour cette partie).
func remove() -> void:
	_removed = true
	hovered = false
	visible = false
	GameState.store_instance_state(get_state_key(), state, true)
	removed.emit()


## Vrai si [param global_point] tombe dans la zone cliquable.
func contains_global_point(global_point: Vector2) -> bool:
	if _removed or not is_visible_in_tree() or state == null:
		return false
	var local_point := to_local(global_point)
	if hit_rect.has_area():
		return hit_rect.has_point(local_point)
	return texture != null and is_pixel_opaque(local_point)


## Clé unique de l'instance pour [GameState] : chemin de la scène + chemin du nœud.
func get_state_key() -> String:
	if owner != null:
		return "%s::%s" % [owner.scene_file_path, owner.get_path_to(self)]
	return String(get_path())


func _refresh_visual(for_state: PuzzleObject) -> void:
	if for_state == null:
		texture = null
		offset = Vector2.ZERO
		return
	texture = for_state.texture
	offset = for_state.texture_offset
