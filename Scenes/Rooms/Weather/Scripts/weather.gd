extends PuzzleRoom
## Salle du Temps : la météo change à chaque visite (soleil → nuages → pluie → soleil…),
## comme `ScreenControl.CycleWeatherScreen` côté Unity.
##
## Chaque météo a son fond ([member backgrounds], même ordre que [constant WEATHER_NAMES])
## et son calque d'objets sous `Room` : `Sunny`, `Cloudy`, `Rainy`. Seuls les objets de la
## météo courante sont visibles, donc cliquables. Les objets placés sous `Room/Sunny/AfterRain`
## n'apparaissent au soleil qu'une fois qu'il a plu (« Après la pluie, vient le beau temps ! »).
##
## La météo courante est gardée dans [GameState] (drapeau [code]weather_index[/code]).

## Noms des météos, dans l'ordre du cycle.
const WEATHER_NAMES: Array[String] = ["Soleil", "Nuages", "Pluie"]
const SUNNY := 0
const RAINY := 2

## Fond de chaque météo, dans l'ordre de [constant WEATHER_NAMES].
@export var backgrounds: Array[Texture2D] = []

@onready var _background: Sprite2D = $Room/Background
@onready var _layers: Array[Node2D] = [$Room/Sunny, $Room/Cloudy, $Room/Rainy]
@onready var _after_rain: Node2D = $Room/Sunny/AfterRain


func _ready() -> void:
	_apply_weather(maxi(0, GameState.get_flag(&"weather_index", -1)))
	super._ready()


## Passe à la météo suivante à chaque fois que la caméra part vers la salle.
func on_enter() -> void:
	var index: int = (GameState.get_flag(&"weather_index", -1) + 1) % WEATHER_NAMES.size()
	GameState.set_flag(&"weather_index", index)
	if index == RAINY:
		GameState.set_flag(&"weather_has_rained", true)
	_apply_weather(index)


func _apply_weather(index: int) -> void:
	if index < backgrounds.size():
		_background.texture = backgrounds[index]
	for i in _layers.size():
		_layers[i].visible = i == index
	_after_rain.visible = GameState.get_flag(&"weather_has_rained", false)
