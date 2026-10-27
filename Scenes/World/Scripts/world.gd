extends Node2D
## Le monde : toutes les salles côte à côte, parcourues comme un diaporama.
##
## Reprend la scène `Main.unity` : les tableaux étaient alignés horizontalement
## (Intro, Lune, Soleil, Temps, Âne, Outro), séparés par des murs noirs, et une caméra
## Cinemachine glissait de l'un à l'autre (fondu « ease in-out » de 2 s) quand on
## cliquait sur les flèches (`ScreenControl.cs`). La caméra suivait aussi légèrement
## la souris (`CameraControl.cs`). Comme elle était en perspective, les objets posés
## devant le fond défilaient plus vite : c'est l'effet parallaxe, rendu ici par les
## [DepthLayer] des salles et des murs.
##
## Les salles sont les enfants de `Rooms`, dans l'ordre. La première est l'intro
## (un clic pour commencer, on ne peut plus y revenir), la dernière l'outro (atteinte
## seulement quand le joueur obtient [member ending_item]). Entre les deux, les flèches
## gauche/droite passent d'une salle à l'autre. Une salle peut exiger des objets pour
## y entrer (voir [member PuzzleRoom.required_items]).

## Centre d'une salle par rapport à sa racine (le nœud `Room` de chaque scène de salle).
const ROOM_CENTER := Vector2(960, 540)

## Écart horizontal entre deux salles : largeur du fond (4777 px × 0,413).
@export var room_stride: float = 1973.0
## Durée du glissement d'une salle à la voisine, en secondes (2 s dans Unity).
@export var slide_duration: float = 1.6
## Débattement maximal de la caméra qui suit la souris, en pixels écran.
## Reste sous la marge du fond (≈ 26 px à gauche/droite, 36 px en haut/bas).
@export var look_amount: Vector2 = Vector2(22, 30)
## Réactivité du suivi de la souris (plus grand = plus nerveux).
@export var look_smoothing: float = 3.0
@export_group("Murs")
## Largeur des murs noirs entre les salles, en pixels écran. Au-delà de ≈ 360 px,
## le bord du mur devient visible quand la caméra suit la souris vers le côté.
@export var wall_width: float = 360.0
## Profondeur des murs (voir [member DepthLayer.depth]). Dans Unity, les murs étaient
## 5 unités devant les fonds, d'où ≈ 0,18.
@export var wall_depth: float = 0.18
@export_group("Musique")
## Musiques de l'intro et de l'outro (qui ne sont pas des [PuzzleRoom]). Les autres salles
## ont la leur dans [member PuzzleRoom.music].
@export var intro_music: Array[AudioStream] = []
@export var outro_music: Array[AudioStream] = []
@export_group("Fin")
## Objet dont l'obtention déclenche le passage à l'outro.
@export var ending_item: PuzzleObject
## Délai avant de partir vers l'outro, pour laisser lire la dernière réplique.
@export var ending_delay: float = 3.5

## Index de la salle affichée (0 = intro).
var current_index: int = 0

var _rooms: Array[Node2D] = []
var _sliding: bool = false
var _ending_started: bool = false

@onready var _rooms_root: Node2D = $Rooms
@onready var _camera: Camera2D = $Camera
@onready var _left_button: Button = $Navigation/Left
@onready var _right_button: Button = $Navigation/Right
@onready var _start_label: Label = $Navigation/StartLabel


func _ready() -> void:
	for child in _rooms_root.get_children():
		_rooms.append(child as Node2D)
	for i in _rooms.size():
		_rooms[i].position = Vector2(i * room_stride, 0)
	_build_walls()
	_camera.position = _room_center(current_index)
	_left_button.pressed.connect(func() -> void: go_to(current_index - 1))
	_right_button.pressed.connect(func() -> void: go_to(current_index + 1))
	GameState.inventory_changed.connect(_check_ending)
	Audio.play_music(_music_for(current_index))
	_enter_room(current_index)


func _process(delta: float) -> void:
	# Suivi de la souris : la caméra se décale un peu vers le curseur.
	var viewport_size := get_viewport_rect().size
	var mouse := get_viewport().get_mouse_position()
	var normalized := ((mouse / viewport_size) * 2.0 - Vector2.ONE).clamp(-Vector2.ONE, Vector2.ONE)
	_camera.offset = _camera.offset.lerp(normalized * look_amount, 1.0 - exp(-look_smoothing * delta))


func _unhandled_input(event: InputEvent) -> void:
	# Intro : un clic, Entrée ou Espace pour commencer.
	var mouse_event := event as InputEventMouseButton
	var start_click := mouse_event != null and mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT
	if current_index == 0 and not _sliding and (start_click or event.is_action_pressed(&"ui_accept")):
		get_viewport().set_input_as_handled()
		go_to(1)
		return

	# Navigation au clavier : flèches (ui_left / ui_right, aussi la croix d'une manette),
	# Q/A et D (AZERTY et QWERTY), comme les flèches à l'écran.
	if event.is_action_pressed(&"ui_left") or _is_key(event, [KEY_Q, KEY_A]):
		get_viewport().set_input_as_handled()
		go_to(current_index - 1)
	elif event.is_action_pressed(&"ui_right") or _is_key(event, [KEY_D]):
		get_viewport().set_input_as_handled()
		go_to(current_index + 1)


## Glisse vers la salle [param index] si c'est permis (pas de retour à l'intro,
## pas d'accès à l'outro par les flèches, salle verrouillée...).
func go_to(index: int) -> void:
	if _sliding or index == current_index or index < 1 or index > _last_playable_index():
		return
	# Une fois sur l'outro, la partie est finie : on n'en repart pas.
	if current_index > _last_playable_index():
		return
	var room := _rooms[index] as PuzzleRoom
	if room != null and not room.try_unlock():
		return
	_slide_to(index)


func _slide_to(index: int) -> void:
	var previous := _rooms[current_index] as PuzzleRoom
	if previous != null:
		previous.active = false
	var next := _rooms[index] as PuzzleRoom
	if next != null:
		next.on_enter()
	Hud.set_room_active(next != null)
	# Fondu enchaîné de la musique pendant le glissement.
	Audio.play_music(_music_for(index))
	_sliding = true
	_update_navigation()

	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_camera, "position", _room_center(index), slide_duration)
	await tween.finished

	current_index = index
	_sliding = false
	_enter_room(index)


func _enter_room(index: int) -> void:
	var room := _rooms[index] as PuzzleRoom
	Hud.set_room_active(room != null)
	if room != null:
		room.active = true
	_update_navigation()


func _update_navigation() -> void:
	var playable := current_index >= 1 and current_index <= _last_playable_index()
	_left_button.visible = not _sliding and playable and current_index > 1
	_right_button.visible = not _sliding and playable and current_index < _last_playable_index()
	_start_label.visible = not _sliding and current_index == 0


func _check_ending() -> void:
	if _ending_started or ending_item == null or not GameState.has_item(ending_item):
		return
	_ending_started = true
	await get_tree().create_timer(ending_delay).timeout
	while _sliding:
		await get_tree().process_frame
	_slide_to(_rooms.size() - 1)


## Murs noirs entre les salles, sur un calque de profondeur pour qu'ils défilent
## plus vite que les fonds pendant le glissement.
func _build_walls() -> void:
	for i in _rooms.size() - 1:
		var layer := DepthLayer.new()
		layer.name = "Wall%d" % i
		layer.depth = wall_depth
		layer.position = _room_center(i) + Vector2(room_stride / 2.0, 0)
		layer.z_index = 10
		var wall := ColorRect.new()
		wall.color = Color.BLACK
		wall.mouse_filter = Control.MOUSE_FILTER_IGNORE
		wall.size = Vector2(wall_width, 1600)
		wall.position = -wall.size / 2.0
		layer.add_child(wall)
		add_child(layer)


## Vrai si [param event] est l'appui (sans répétition) d'une des [param keycodes].
## Compare la touche physique pour que Q/A désignent la même touche en AZERTY et QWERTY.
func _is_key(event: InputEvent, keycodes: Array) -> bool:
	var key_event := event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return false
	return keycodes.has(key_event.keycode) or keycodes.has(key_event.physical_keycode)


func _music_for(index: int) -> Array:
	if index == 0:
		return intro_music
	if index == _rooms.size() - 1:
		return outro_music
	var room := _rooms[index] as PuzzleRoom
	return room.music if room != null else []


func _room_center(index: int) -> Vector2:
	return Vector2(index * room_stride, 0) + ROOM_CENTER


func _last_playable_index() -> int:
	return _rooms.size() - 2
