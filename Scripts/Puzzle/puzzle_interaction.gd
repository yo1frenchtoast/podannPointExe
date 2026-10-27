class_name PuzzleInteraction
extends Resource
## Ce qui se passe quand on clique sur un [PuzzleObject], avec ou sans objet d'inventaire en main.
##
## Remplace à la fois `PuzzleItemCombination` et le couple
## `succeedsAutomatically` / `succeedPuzzleObject` de la version Unity :
## une interaction sans [member item] est simplement celle du clic à main vide.
##
## Ordre d'application (voir [method PuzzleInstance.interact]) :
## [br]1. si [member accepted] est faux : on affiche [member message] et rien ne change ;
## [br]2. l'objet en main est retiré de l'inventaire si [member consume_item] ;
## [br]3. [member give_item] est ajouté à l'inventaire ;
## [br]4. l'objet du décor passe à [member next_state], ou disparaît si [member remove_instance] ;
## [br]5. on affiche [member message], ou à défaut le message de l'objet reçu,
##    sinon celui du nouvel état, sinon celui de l'état actuel.
##
## Entre deux objets d'inventaire (voir [method GameState.combine_items]), [member next_state]
## remplace l'objet cible dans l'inventaire.

## Objet d'inventaire à utiliser. [code]null[/code] = clic à main vide.
@export var item: PuzzleObject
## Faux pour une mauvaise combinaison « prévue » qui a sa propre réplique
## (ex. « Ça ne rentre pas dans le rouet. »).
@export var accepted: bool = true
## Réplique affichée. Vide = message du nouvel état / de l'objet reçu.
@export_multiline var message: String = ""
## Nouvel état de l'objet cliqué. [code]null[/code] = l'état ne change pas.
@export var next_state: PuzzleObject
## L'objet cliqué disparaît de la salle (typiquement quand on le ramasse).
@export var remove_instance: bool = false
## Objet ajouté à l'inventaire.
@export var give_item: PuzzleObject
## L'objet en main est retiré de l'inventaire. Ignoré pour un clic à main vide.
@export var consume_item: bool = true
