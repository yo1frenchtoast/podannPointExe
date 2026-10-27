class_name PuzzleObject
extends Resource
## Un état d'un objet de puzzle (équivalent de la ScriptableObject Unity `PuzzleObject`).
##
## Un même objet du décor passe par plusieurs états au fil des puzzles
## (ex. « plante neutre » -> « plante arrosée » -> « plante avec clé »).
## Chaque état est un fichier `.tres` à part, rangé dans `res://Data/Puzzles/<Salle>/`.
##
## Une ressource sert à deux choses :
## - comme état d'un [PuzzleInstance] posé dans une salle (on utilise alors [member texture]) ;
## - comme objet d'inventaire (on utilise alors [member icon]).
## Rien n'empêche un même état d'être les deux, mais en pratique on crée un état
## « décor » et un état « inventaire » distincts (ex. `bougie` / `bougie_inv`).
##
## Les réactions aux clics sont décrites par [member interactions] : voir [PuzzleInteraction].

## Identifiant unique et stable. Sert de clé au compteur de clics de [GameState].
@export var id: StringName
## Nom affiché dans l'infobulle au survol et dans l'inventaire.
@export var display_name: String
## Messages affichés quand on clique dessus. On les parcourt en boucle,
## un par clic (comme `messageFeedbacks` côté Unity).
@export var messages: Array[String] = []
## Sons joués au clic, parcourus en boucle avec le même compteur que [member messages].
@export var sounds: Array[AudioStream] = []

@export_group("Apparence")
## Sprite dans la salle. Les overlays de décor sont des images plein cadre
## (même taille que le fond), donc [member texture_offset] reste à zéro.
## Laisser vide pour un objet invisible (zone cliquable via [member PuzzleInstance.hit_rect]).
@export var texture: Texture2D
## Décalage du centre de [member texture], en pixels de l'image de fond, par rapport
## au centre du fond. Utile seulement pour les sprites recadrés (pas plein cadre).
@export var texture_offset: Vector2 = Vector2.ZERO
## Icône affichée dans la barre d'inventaire et sous le curseur quand l'objet est sélectionné.
@export var icon: Texture2D

@export_group("Interactions")
## Liste de [PuzzleInteraction]. Typée `Array[Resource]` et non `Array[PuzzleInteraction]`
## car Godot 4.1 sérialise mal les tableaux typés de classes scriptées ;
## seules les entrées qui sont des [PuzzleInteraction] sont prises en compte.
@export var interactions: Array[Resource] = []
## Message quand on utilise un objet d'inventaire qui n'a aucune interaction prévue.
## Vide = message générique de [GameState].
@export_multiline var wrong_item_message: String = ""


## Renvoie l'interaction déclenchée par [param item] ([code]null[/code] = clic à main vide),
## ou [code]null[/code] si aucune n'est prévue.
func find_interaction(item: PuzzleObject) -> PuzzleInteraction:
	for entry in interactions:
		var interaction := entry as PuzzleInteraction
		if interaction != null and interaction.item == item:
			return interaction
	return null


func _to_string() -> String:
	return "PuzzleObject(%s)" % id
