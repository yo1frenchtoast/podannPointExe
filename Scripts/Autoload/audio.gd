extends Node
## Autoload `Audio` (scène `Scenes/Audio/audio.tscn`) : musiques et effets sonores.
##
## [b]Musique[/b] : chaque salle a sa liste de morceaux ([member PuzzleRoom.music]).
## [method play_music] passe d'une liste à l'autre en fondu enchaîné (le temps du
## glissement de caméra), puis enchaîne les morceaux de la liste en boucle. En revenant
## dans une salle, on reprend au morceau suivant de sa liste.
##
## [b]Effets[/b] : joués selon le résultat des interactions, signalé par
## [signal GameState.interaction_result] :
## - [code]&"pickup"[/code] : un objet arrive dans l'inventaire ;
## - [code]&"success"[/code] : un objet change d'état (combinaison réussie...) ;
## - [code]&"fail"[/code] : mauvais objet, combinaison refusée, porte fermée ;
## - [code]&"unlock"[/code] : une porte s'ouvre.
## Prendre un objet en main joue [member sfx_select]. Un [PuzzleObject] qui a ses propres
## [member PuzzleObject.sounds] les joue à la place de l'effet générique (ex. les clés).
##
## [kbd]M[/kbd] coupe ou rétablit tout le son.

@export_group("Musique")
## Volume des musiques, en dB.
@export var music_volume_db: float = -10.0
## Durée du fondu enchaîné entre deux salles, en secondes.
@export var crossfade_duration: float = 1.6

@export_group("Effets")
## Volume des effets, en dB.
@export var sfx_volume_db: float = -4.0
@export var sfx_pickup: AudioStream
@export var sfx_success: AudioStream
@export var sfx_fail: AudioStream
@export var sfx_unlock: AudioStream
@export var sfx_select: AudioStream

const SILENT_DB := -60.0

var _music_players: Array[AudioStreamPlayer] = []
var _active: int = 0
var _playlist: Array = []
var _track_index: int = 0
# Clé de liste (chemin du 1er morceau) -> index du prochain morceau à jouer.
var _resume_index: Dictionary = {}
var _sfx: AudioStreamPlayer
var _object_sfx: AudioStreamPlayer
var _fade: Tween


func _ready() -> void:
	for i in 2:
		var player := AudioStreamPlayer.new()
		player.name = "Music%d" % i
		player.volume_db = SILENT_DB
		player.finished.connect(_on_music_finished.bind(player))
		add_child(player)
		_music_players.append(player)
	_sfx = _make_player("Sfx")
	_object_sfx = _make_player("ObjectSfx")
	GameState.interaction_result.connect(_on_interaction_result)
	GameState.selected_item_changed.connect(_on_selected_item_changed)


func _unhandled_input(event: InputEvent) -> void:
	var key_event := event as InputEventKey
	if key_event != null and key_event.pressed and not key_event.echo and key_event.keycode == KEY_M:
		AudioServer.set_bus_mute(0, not AudioServer.is_bus_mute(0))


## Joue la liste de morceaux [param playlist] (des [AudioStream]) en fondu enchaîné.
## Ne fait rien si c'est déjà la liste en cours ; une liste vide coupe la musique.
func play_music(playlist: Array) -> void:
	if _same_playlist(playlist, _playlist):
		return
	if not _playlist.is_empty():
		_resume_index[_playlist_key(_playlist)] = (_track_index + 1) % _playlist.size()
	_playlist = playlist.duplicate()
	var outgoing := _music_players[_active]
	_active = 1 - _active
	var incoming := _music_players[_active]

	if _fade != null:
		_fade.kill()
	# Les deux fondus en parallèle, puis arrêt du lecteur sortant.
	_fade = create_tween().set_parallel(true)
	_fade.tween_property(outgoing, "volume_db", SILENT_DB, crossfade_duration)
	if not _playlist.is_empty():
		_track_index = _resume_index.get(_playlist_key(_playlist), 0)
		incoming.stream = _playlist[_track_index]
		incoming.volume_db = SILENT_DB
		incoming.play()
		_fade.tween_property(incoming, "volume_db", music_volume_db, crossfade_duration)
	_fade.chain().tween_callback(outgoing.stop)


## Joue un effet sonore (coupe l'effet précédent).
func play_sfx(stream: AudioStream) -> void:
	if stream == null:
		return
	_sfx.stream = stream
	_sfx.play()


## Joue le son propre à un objet, sur un canal à part pour ne pas couper l'effet générique.
func play_object_sound(stream: AudioStream) -> void:
	if stream == null:
		return
	_object_sfx.stream = stream
	_object_sfx.play()


func _on_interaction_result(kind: StringName) -> void:
	match kind:
		&"pickup":
			play_sfx(sfx_pickup)
		&"success":
			play_sfx(sfx_success)
		&"fail":
			play_sfx(sfx_fail)
		&"unlock":
			play_sfx(sfx_unlock)


func _on_selected_item_changed(item: PuzzleObject) -> void:
	if item != null:
		play_sfx(sfx_select)


func _on_music_finished(player: AudioStreamPlayer) -> void:
	# Seul le lecteur actif enchaîne ; l'autre vient d'être coupé par un fondu.
	if player != _music_players[_active] or _playlist.is_empty():
		return
	_track_index = (_track_index + 1) % _playlist.size()
	player.stream = _playlist[_track_index]
	player.play()


func _make_player(player_name: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = player_name
	player.volume_db = sfx_volume_db
	add_child(player)
	return player


func _same_playlist(a: Array, b: Array) -> bool:
	return a.size() == b.size() and (a.is_empty() or _playlist_key(a) == _playlist_key(b))


func _playlist_key(playlist: Array) -> String:
	return (playlist[0] as Resource).resource_path if not playlist.is_empty() and playlist[0] != null else ""
