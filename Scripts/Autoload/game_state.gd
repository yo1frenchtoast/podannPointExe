extends Node
## Autoload `GameState` : tout l'état de la partie qui doit survivre aux changements de salle.
##
## - l'inventaire et l'objet actuellement en main (sélectionné) ;
## - l'état courant de chaque [PuzzleInstance] (pour qu'une bougie ramassée ne
##   réapparaisse pas quand on revient dans la salle) ;
## - le compteur de clics de chaque [PuzzleObject], qui fait tourner les messages et les sons.
##
## Côté Unity, l'inventaire vivait dans `CustomCursor` et le compteur de clics dans la
## ScriptableObject elle-même (donc partagé entre instances et conservé d'une partie à l'autre).
##
## L'interface (dialogue, inventaire, curseur) n'est pas gérée ici : elle écoute
## les signaux ci-dessous (voir `Scenes/UI/hud.tscn`).

## L'inventaire a changé (ajout, retrait ou remplacement d'un objet).
signal inventory_changed
## L'objet en main a changé. [param item] vaut [code]null[/code] quand on lâche l'objet.
signal selected_item_changed(item: PuzzleObject)
## Une réplique doit être affichée dans la boîte de dialogue.
signal message_requested(text: String)

## Réplique quand on utilise un objet qui n'a aucune interaction prévue.
const DEFAULT_WRONG_ITEM_MESSAGE := "Ça ne donne rien."
## Réplique d'une interaction refusée qui n'a pas de message propre.
const DEFAULT_REFUSED_MESSAGE := "Non, ça ne va pas."

## Objets d'inventaire, dans l'ordre d'obtention.
var inventory: Array[PuzzleObject] = []
## Objet en main, ou [code]null[/code].
var selected_item: PuzzleObject = null

# id d'objet -> nombre de clics (pour faire tourner messages et sons).
var _click_counts: Dictionary = {}
# clé d'instance (voir PuzzleInstance.get_state_key) -> {"state": PuzzleObject, "removed": bool}
var _instance_states: Dictionary = {}
# Valeurs libres propres aux salles (météo courante, salle déverrouillée...). Voir get_flag.
var _flags: Dictionary = {}
var _audio: AudioStreamPlayer


func _ready() -> void:
	_audio = AudioStreamPlayer.new()
	_audio.name = "FeedbackAudio"
	add_child(_audio)


func _unhandled_input(event: InputEvent) -> void:
	# Équivalent de la touche « / » de CustomCursor.cs : liste l'inventaire dans la console.
	var key_event := event as InputEventKey
	if OS.is_debug_build() and key_event != null and key_event.pressed and key_event.keycode == KEY_F1:
		print("Inventaire : ", inventory)


## Remet la partie à zéro (nouvelle partie).
func reset() -> void:
	inventory.clear()
	_click_counts.clear()
	_instance_states.clear()
	_flags.clear()
	selected_item = null
	inventory_changed.emit()
	selected_item_changed.emit(null)


#region Inventaire

func add_item(item: PuzzleObject) -> void:
	if item == null or inventory.has(item):
		return
	inventory.append(item)
	inventory_changed.emit()


func remove_item(item: PuzzleObject) -> void:
	if not inventory.has(item):
		return
	inventory.erase(item)
	if selected_item == item:
		select_item(null)
	inventory_changed.emit()


## Remplace [param old_item] par [param new_item] à la même place dans l'inventaire.
func replace_item(old_item: PuzzleObject, new_item: PuzzleObject) -> void:
	var index := inventory.find(old_item)
	if index == -1:
		add_item(new_item)
		return
	inventory[index] = new_item
	if selected_item == old_item:
		select_item(null)
	inventory_changed.emit()


func has_item(item: PuzzleObject) -> bool:
	return inventory.has(item)


## Prend [param item] en main ([code]null[/code] pour lâcher).
func select_item(item: PuzzleObject) -> void:
	if item == selected_item:
		return
	selected_item = item
	selected_item_changed.emit(item)


## Utilise [param held] (en main) sur [param target] (dans l'inventaire).
##
## On cherche d'abord une interaction déclarée sur la cible, puis sur l'objet en main :
## l'ordre de la combinaison n'a donc pas d'importance pour le joueur.
## [member PuzzleInteraction.next_state] remplace l'objet qui porte l'interaction,
## [member PuzzleInteraction.consume_item] retire l'autre.
## Renvoie [code]true[/code] si la combinaison a réussi.
func combine_items(held: PuzzleObject, target: PuzzleObject) -> bool:
	var host := target
	var other := held
	var interaction := target.find_interaction(held)
	if interaction == null:
		host = held
		other = target
		interaction = held.find_interaction(target)
	if interaction == null:
		var text := target.wrong_item_message
		show_message(text if not text.is_empty() else DEFAULT_WRONG_ITEM_MESSAGE)
		return false
	if not interaction.accepted:
		show_message(interaction.message if not interaction.message.is_empty() else DEFAULT_REFUSED_MESSAGE)
		return false

	if interaction.consume_item:
		remove_item(other)
	if interaction.next_state != null:
		replace_item(host, interaction.next_state)
	if interaction.give_item != null:
		add_item(interaction.give_item)
	select_item(null)

	# Même priorité que PuzzleInstance.interact : objet reçu > nouvel état > objet d'origine.
	var feedback_object := host
	if interaction.next_state != null:
		feedback_object = interaction.next_state
	if interaction.give_item != null:
		feedback_object = interaction.give_item
	play_feedback(feedback_object, interaction.message)
	return true

#endregion


#region Retours (messages et sons)

## Affiche le message et joue le son suivants de [param object], puis avance son compteur.
## [param override_message] remplace le message s'il n'est pas vide (le son reste joué).
func play_feedback(object: PuzzleObject, override_message: String = "") -> void:
	var key := _object_key(object)
	var count: int = _click_counts.get(key, 0)
	_click_counts[key] = count + 1

	var text := override_message
	if text.is_empty() and not object.messages.is_empty():
		text = object.messages[count % object.messages.size()]
	if not text.is_empty():
		show_message(text)

	if not object.sounds.is_empty():
		var sound := object.sounds[count % object.sounds.size()]
		if sound != null:
			_audio.stream = sound
			_audio.play()


func show_message(text: String) -> void:
	message_requested.emit(text)


func _object_key(object: PuzzleObject) -> String:
	return String(object.id) if object.id != &"" else object.resource_path

#endregion


#region État des objets dans les salles

## Mémorise l'état d'une instance (appelé par [PuzzleInstance] à chaque changement).
func store_instance_state(key: String, state: PuzzleObject, removed: bool) -> void:
	_instance_states[key] = {"state": state, "removed": removed}


## Renvoie [code]{"state": PuzzleObject, "removed": bool}[/code],
## ou un dictionnaire vide si l'instance n'a jamais changé.
func get_instance_state(key: String) -> Dictionary:
	return _instance_states.get(key, {})

#endregion


#region Drapeaux

## Valeur libre mémorisée pour la partie (ex. [code]&"weather_index"[/code] pour la météo,
## [code]"unlocked:<scène>"[/code] pour une salle ouverte). [param default] si absente.
func get_flag(key: StringName, default: Variant = null) -> Variant:
	return _flags.get(key, default)


func set_flag(key: StringName, value: Variant) -> void:
	_flags[key] = value

#endregion
