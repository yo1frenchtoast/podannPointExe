class_name DepthLayer
extends Node2D
## Calque de profondeur : donne l'effet de parallaxe de la caméra perspective Unity.
##
## Dans Unity, les objets étaient posés à différentes profondeurs devant le fond et la
## caméra était en perspective : quand elle bougeait (glissement entre salles, léger
## suivi de la souris), les objets proches défilaient plus vite que le fond.
##
## Ici tout est en 2D : un [DepthLayer] se décale en fonction de l'écart entre le centre
## de la vue et sa position d'origine, multiplié par [member depth].
## - [code]depth = 0[/code] : bouge avec le fond (aucun effet) ;
## - [code]depth > 0[/code] : plus proche que le fond, défile plus vite ;
## - [code]depth < 0[/code] : plus loin que le fond, défile moins vite.
##
## Le décalage est nul quand la vue est centrée sur la position d'origine du calque :
## on place donc le calque au centre de sa salle (position 0 sous le nœud `Room`),
## et ses enfants à leur place « vue de face ».
##
## Correspondance avec Unity : un objet à la profondeur locale z (négative = vers la
## caméra) a [code]depth = D / (D + z) - 1[/code] avec D ≈ 27,13 (distance caméra-fond).

## Profondeur relative au fond. Voir la description de la classe.
@export var depth: float = 0.0

var _base_position: Vector2


func _ready() -> void:
	_base_position = position


func _process(_delta: float) -> void:
	if is_zero_approx(depth):
		return
	# Centre de la vue en coordonnées du monde (fonctionne avec ou sans Camera2D).
	var view_center := get_canvas_transform().affine_inverse() * (get_viewport_rect().size / 2.0)
	var parent_xform := Transform2D.IDENTITY
	var parent_item := get_parent() as CanvasItem
	if parent_item != null:
		parent_xform = parent_item.get_global_transform()
	var anchor := parent_xform * _base_position
	var shift := (view_center - anchor) * depth
	position = _base_position - parent_xform.affine_inverse().basis_xform(shift)
