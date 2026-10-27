extends CanvasLayer
## Autoload `Hud` (scène `Scenes/UI/hud.tscn`) : l'interface par-dessus les salles.
##
## - boîte de dialogue : affiche les répliques de [signal GameState.message_requested]
##   pendant un temps proportionnel à leur longueur ;
## - barre d'inventaire : un bouton par objet de [member GameState.inventory].
##   Clic sur un objet = le prendre en main (ou le lâcher). Clic avec un autre objet
##   en main = essayer de les combiner ([method GameState.combine_items]) ;
## - objet en main : son icône suit le curseur (remplace le sprite de `CustomCursor`) ;
## - infobulle : nom de l'objet survolé, ou « Utiliser X sur Y » avec un objet en main.
##
## Le HUD n'est visible que dans une [PuzzleRoom] (voir [method set_room_active]).
## La mise en page et le thème (police alagard, panneaux) se règlent dans la scène.

## Taille d'une case d'inventaire.
const SLOT_SIZE := Vector2(96, 96)
## Décalage de l'icône de l'objet en main par rapport au curseur.
const HELD_ITEM_OFFSET := Vector2(18, 18)
## Décalage de l'infobulle par rapport au curseur.
const HOVER_LABEL_OFFSET := Vector2(28, -56)
## Durée d'affichage minimale d'une réplique, en secondes.
const MIN_MESSAGE_DURATION := 2.5
## Durée ajoutée par caractère de la réplique, en secondes.
const SECONDS_PER_CHARACTER := 0.06

var _hover_target: PuzzleObject = null

@onready var _root: Control = $Root
@onready var _dialogue: PanelContainer = $Root/Dialogue
@onready var _dialogue_label: Label = $Root/Dialogue/Text
@onready var _dialogue_timer: Timer = $DialogueTimer
@onready var _inventory_bar: PanelContainer = $Root/InventoryBar
@onready var _slots: HBoxContainer = $Root/InventoryBar/Slots
@onready var _hover_label: Label = $Root/HoverLabel
@onready var _held_item: TextureRect = $Root/HeldItem


func _ready() -> void:
	visible = false
	_dialogue.hide()
	_hover_label.hide()
	GameState.inventory_changed.connect(_rebuild_slots)
	GameState.selected_item_changed.connect(_on_selected_item_changed)
	GameState.message_requested.connect(show_message)
	_dialogue_timer.timeout.connect(_dialogue.hide)
	_rebuild_slots()
	_on_selected_item_changed(GameState.selected_item)


func _process(_delta: float) -> void:
	var mouse := _root.get_local_mouse_position()
	_held_item.position = mouse + HELD_ITEM_OFFSET
	_hover_label.position = mouse + HOVER_LABEL_OFFSET


## Affiche ou cache le HUD. Appelé par [PuzzleRoom] à l'entrée et à la sortie d'une salle.
func set_room_active(active: bool) -> void:
	visible = active
	if not active:
		_dialogue.hide()
		set_hover_target(null)


## Objet survolé dans la salle ([code]null[/code] = aucun), pour l'infobulle.
func set_hover_target(target: PuzzleObject) -> void:
	if target == _hover_target:
		return
	_hover_target = target
	_update_hover_label()


## Affiche [param text] dans la boîte de dialogue.
func show_message(text: String) -> void:
	_dialogue_label.text = text
	_dialogue.show()
	_dialogue_timer.start(maxf(MIN_MESSAGE_DURATION, text.length() * SECONDS_PER_CHARACTER))


## Vrai si la souris est sur un élément d'interface qui doit bloquer le survol de la salle.
func is_mouse_over_ui() -> bool:
	return visible and _inventory_bar.visible \
		and _inventory_bar.get_global_rect().has_point(_root.get_global_mouse_position())


func _update_hover_label() -> void:
	if _hover_target == null:
		_hover_label.hide()
		return
	var held := GameState.selected_item
	if held != null:
		_hover_label.text = "Utiliser %s sur %s" % [held.display_name, _hover_target.display_name]
	else:
		_hover_label.text = _hover_target.display_name
	_hover_label.show()


func _rebuild_slots() -> void:
	for child in _slots.get_children():
		child.queue_free()
	for item in GameState.inventory:
		var slot := Button.new()
		slot.custom_minimum_size = SLOT_SIZE
		slot.icon = item.icon
		slot.expand_icon = true
		slot.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot.toggle_mode = true
		slot.focus_mode = Control.FOCUS_NONE
		slot.tooltip_text = item.display_name
		slot.set_meta(&"item", item)
		slot.pressed.connect(_on_slot_pressed.bind(item))
		_slots.add_child(slot)
	_inventory_bar.visible = not GameState.inventory.is_empty()
	_sync_slot_states()


func _sync_slot_states() -> void:
	for slot in _slots.get_children():
		if slot is Button and not slot.is_queued_for_deletion():
			slot.set_pressed_no_signal(slot.get_meta(&"item") == GameState.selected_item)


func _on_slot_pressed(item: PuzzleObject) -> void:
	var held := GameState.selected_item
	if held == null:
		GameState.select_item(item)
	elif held == item:
		GameState.select_item(null)
	else:
		GameState.combine_items(held, item)
	# Le bouton a basculé tout seul : on réaligne tous les boutons sur l'objet en main.
	_sync_slot_states()


func _on_selected_item_changed(item: PuzzleObject) -> void:
	_held_item.texture = item.icon if item != null else null
	_held_item.visible = item != null
	_sync_slot_states()
	_update_hover_label()
