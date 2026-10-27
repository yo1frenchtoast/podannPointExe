# Moteur de puzzle (point & click)

Ce document décrit le moteur générique porté depuis la version Unity de la game jam
(`unity_assets/Scripts/`) et explique comment créer de nouvelles énigmes et de nouvelles salles.

## Vue d'ensemble

```
project.godot
├── autoload GameState  ─ Scripts/Autoload/game_state.gd   état de la partie
└── autoload Hud        ─ Scenes/UI/hud.tscn               dialogue, inventaire, curseur

Scripts/Puzzle/
├── puzzle_object.gd       PuzzleObject       (Resource)  un état d'objet
├── puzzle_interaction.gd  PuzzleInteraction  (Resource)  une réaction à un clic
├── puzzle_instance.gd     PuzzleInstance     (Sprite2D)  un objet posé dans une salle
└── puzzle_room.gd         PuzzleRoom         (Node2D)    une salle jouable

Data/Puzzles/<Salle>/*.tres   les données des énigmes (un fichier par état)
```

Le principe est le même que dans Unity : **tout est dans les données**. Le code ne connaît
aucune énigme ; une énigme est une suite d'états (`PuzzleObject`) reliés par des
interactions (`PuzzleInteraction`).

| Unity                                   | Godot                                         |
|-----------------------------------------|-----------------------------------------------|
| `PuzzleObject` (ScriptableObject)       | `PuzzleObject` (Resource, fichier `.tres`)    |
| `PuzzleItemCombination`                 | `PuzzleInteraction` avec un `item`            |
| `succeedsAutomatically` + `succeedPuzzleObject` | `PuzzleInteraction` sans `item`       |
| `objectType` (SCENEOBJECT / INVENTORYOBJECT) | supprimé : `texture` pour la salle, `icon` pour l'inventaire |
| `PuzzleInstance` (MonoBehaviour + Collider) | `PuzzleInstance` (Sprite2D, zone cliquable au pixel près) |
| `CustomCursor` (raycast, inventaire, clic) | `PuzzleRoom` (survol, clic) + `GameState` (inventaire) + `Hud` (curseur) |
| `Inventory` / `InventorySlot` (jamais branchés) | barre d'inventaire du `Hud` |

## Les données

### `PuzzleObject` : un état

Un objet du décor change d'état au fil des énigmes ; chaque état est un `.tres`.
Exemple de la plante de la salle Witch :

```
plante_neutre ──(flacon_pluie)──▶ plante_eau ──(rayon_soleil)──▶ plante_cle ──(clic)──▶ plante_soleil
                                                                                   └─ donne cle_lune
```

| Propriété | Rôle |
|---|---|
| `id` | Identifiant unique (sert au compteur de clics). Même nom que le fichier. |
| `display_name` | Nom affiché au survol et dans l'inventaire. |
| `messages` | Répliques au clic, parcourues en boucle (une par clic). |
| `sounds` | Sons au clic, parcourus avec le même compteur. |
| `texture` | Sprite dans la salle. Vide = objet invisible (il faut alors un `hit_rect` sur l'instance). |
| `texture_offset` | Décalage du centre du sprite par rapport au centre du fond, en pixels de l'image de fond. Zéro pour les overlays plein cadre. |
| `icon` | Icône dans l'inventaire et sous le curseur. |
| `interactions` | Liste de `PuzzleInteraction` (voir plus bas). |
| `wrong_item_message` | Réplique quand on utilise un objet qui n'a aucune interaction prévue (vide = « Ça ne donne rien. »). |

Un même `.tres` peut servir d'état de décor **et** d'objet d'inventaire, mais par clarté
on sépare les deux : `bougie` (dans la salle) et `bougie_inv` (dans l'inventaire).

> `interactions` est typé `Array[Resource]` et non `Array[PuzzleInteraction]` :
> Godot 4.1 sérialise mal les tableaux typés de classes scriptées. Dans l'inspecteur,
> choisir « New PuzzleInteraction » (ou « New Resource » puis lui assigner le script).

### `PuzzleInteraction` : une réaction

Une interaction est choisie selon l'objet que le joueur a **en main** au moment du clic
(`item`). Une interaction sans `item` est celle du clic **à main vide**.

| Propriété | Rôle |
|---|---|
| `item` | Objet d'inventaire à utiliser. Vide = clic à main vide. |
| `accepted` | Décocher pour une mauvaise combinaison qui a sa propre réplique. Rien ne change. |
| `message` | Réplique. Vide = message de l'objet reçu, sinon du nouvel état, sinon de l'état actuel. |
| `next_state` | Nouvel état de l'objet cliqué. |
| `remove_instance` | L'objet disparaît de la salle (on l'a ramassé). |
| `give_item` | Objet ajouté à l'inventaire. |
| `consume_item` | L'objet en main est retiré de l'inventaire (coché par défaut). |

Quand on clique sur un objet de la salle :

1. on cherche l'interaction dont `item` est l'objet en main ;
2. aucune ? → à main vide : on affiche le message suivant de l'objet ;
   avec un objet en main : `wrong_item_message` ;
3. `accepted` décoché → on affiche `message`, rien d'autre ;
4. sinon : l'objet en main est consommé (`consume_item`), `give_item` arrive dans
   l'inventaire, l'objet passe à `next_state` ou disparaît (`remove_instance`),
   l'objet en main est lâché, et on affiche la réplique.

**Recettes courantes**

| Je veux… | Interaction |
|---|---|
| ramasser un objet | sans `item`, `remove_instance`, `give_item` = version inventaire |
| qu'un objet change quand on clique | sans `item`, `next_state` |
| utiliser un objet sur le décor | `item`, `next_state` (+ `consume_item` décoché s'il est réutilisable, comme la bougie) |
| récupérer quelque chose dans le décor | sans `item`, `next_state` = décor vide, `give_item` (cf. `plante_cle`) |
| une réplique drôle pour un mauvais objet | `item`, `accepted` décoché, `message` |

### Combiner deux objets de l'inventaire

Avec un objet en main, cliquer sur un autre objet de l'inventaire appelle
`GameState.combine_items()`. On cherche l'interaction sur la cible puis sur l'objet en
main (l'ordre n'a pas d'importance pour le joueur). Ici `next_state` **remplace** dans
l'inventaire l'objet qui porte l'interaction, `consume_item` retire l'autre, et
`give_item` ajoute un nouvel objet. `remove_instance` est ignoré.

## Les salles

### `PuzzleInstance` : un objet dans la salle

Un `Sprite2D` avec le script `puzzle_instance.gd`. On règle :

- `initial_state` : l'état en début de partie (affiché dans l'éditeur, le script est `@tool`) ;
- `hit_rect` (optionnel) : zone cliquable en coordonnées locales.

Sans `hit_rect`, la zone cliquable est **l'ensemble des pixels non transparents** de la
texture. Comme les overlays des salles sont des images plein cadre (même taille que le
fond, 4777×2792), l'objet est cliquable exactement là où il est dessiné, sans forme de
collision à tracer. Un `hit_rect` est nécessaire pour un état sans texture (l'encens
éteint, le rouet sans roue) ou pour agrandir une zone trop fine.

Quand plusieurs objets se chevauchent, celui qui est **le plus bas dans l'arbre de scène**
(donc dessiné par-dessus) gagne.

L'état de chaque instance est sauvegardé dans `GameState` à chaque changement (clé :
chemin de la scène + chemin du nœud) et restauré quand on revient dans la salle.

### `PuzzleRoom` : une salle

La racine d'une salle jouable utilise `puzzle_room.gd` (ou un script qui en hérite, comme
`witch.gd`). Elle :

- détermine l'objet survolé (surbrillance, curseur main, infobulle) ;
- clic gauche : utilise l'objet en main sur l'objet survolé (ou clic à main vide) ;
- clic droit : lâche l'objet en main ;
- affiche le HUD tant qu'elle est ouverte.

Structure type (cf. `Scenes/Rooms/Witch/witch.tscn`) :

```
Witch (Node2D, witch.gd)
└── Room (Node2D, position 960×540, échelle 0.413)
    ├── Background (Sprite2D, fond plein cadre)
    ├── Rouet   (PuzzleInstance)
    ├── Encens  (PuzzleInstance)
    └── ...
```

Toutes les instances sont enfants de `Room`, qui centre et met à l'échelle les images
4777×2792 sur l'écran 1920×1080. Les coordonnées locales (`hit_rect`, `texture_offset`)
sont donc en **pixels de l'image de fond, origine au centre de l'image**.
Pour convertir un pixel `(x, y)` de l'image : `(x - 2388.5, y - 1396)`.

### Créer une nouvelle salle

1. Dupliquer `witch.tscn`, changer le fond et le script racine.
2. Créer `Data/Puzzles/<Salle>/` et un `.tres` par état (clic droit > Nouvelle ressource >
   `PuzzleObject`).
3. Ajouter un `Sprite2D` par objet, lui mettre `puzzle_instance.gd` et son `initial_state`.

## Interface (`Hud`)

`Scenes/UI/hud.tscn`, autoload, au-dessus de tout (CanvasLayer 10) :

- **Dialogue** : en bas, affiche les répliques ; disparaît après 2,5 s minimum
  (+ 0,06 s par caractère) ;
- **Inventaire** : barre en bas, cachée tant qu'elle est vide. Clic = prendre en main /
  lâcher ; clic avec un autre objet en main = combiner ;
- **Objet en main** : son icône suit le curseur ;
- **Infobulle** : nom de l'objet survolé, ou « Utiliser X sur Y ».

Police : `unity_assets/Art/alagard.ttf` (celle de la version Unity). Le thème est une
sous-ressource de la scène, modifiable dans l'éditeur.

## `GameState`

Autoload qui garde tout ce qui doit survivre aux changements de salle :
inventaire, objet en main, état des instances, compteurs de clics.
`GameState.reset()` remet la partie à zéro.

Signaux : `inventory_changed`, `selected_item_changed(item)`, `message_requested(text)`.

## Outils de debug (build de debug uniquement)

| Touche | Effet |
|---|---|
| F1 | Liste l'inventaire dans la console. |
| F9 | Ajoute à l'inventaire les `debug_items` de la salle (objets venant de salles pas encore portées). |

## Salle Witch : état actuel

Énigmes branchées (textes repris des assets Unity `unity_assets/Features/Moon/`) :

| Objet | Chaîne |
|---|---|
| Bougie | clic → ramassée (`bougie_inv`) |
| Encens | `bougie_inv` (non consommée) → encens allumé (fumée) |
| Fiole | clic → ramassée (`fiole_vide_inv`), à remplir de pluie dans la salle Météo |
| Plante | `flacon_pluie` → arrosée → `rayon_soleil` → clé visible → clic → **clé de la Lune** |
| Rouet | `roue` → rouet avec roue → `coton` → donne une **bobine de fil** |

`flacon_pluie`, `roue`, `coton` (salle Météo) et `rayon_soleil` (salle Soleil) sont dans
`Data/Puzzles/Weather/` et `Data/Puzzles/Sun/` ; tant que ces salles ne sont pas portées,
on les obtient avec **F9**.

Différences assumées avec la version Unity :

- la plante n'est plus ramassable (`plant-neutre` → `plant-neutre_inv` côté Unity, ce qui
  rendait la chaîne d'arrosage impossible) ;
- la chaîne de la plante (eau puis soleil) et celle du rouet (roue puis coton) n'étaient
  pas reliées dans Unity : elles sont reconstruites à partir des états et des sprites existants ;
- deux répliques de refus ont été ajoutées (soleil sur la plante sèche, coton sur le rouet sans roue).

Reste à faire / à vérifier :

- la **lavande** (`lavander`), la **lune en métal** et le **tapis** (`tapis-lune`, `tissu-tapis`)
  existent côté Unity mais n'ont pas de position connue dans le décor : non placés ;
- l'emplacement de l'encens reprend celui de la fumée dans l'ancienne scène Godot ; à
  ajuster si l'encens doit être ailleurs ;
- la clé de la Lune et la bobine de fil ne servent encore à rien (dépendent des autres salles) ;
- `Scenes/Items/Witch/Candle/Candle.tscn` n'est plus utilisé (remplacé par les
  `PuzzleInstance`).
