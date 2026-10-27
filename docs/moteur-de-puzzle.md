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
├── puzzle_room.gd         PuzzleRoom         (Node2D)    une salle jouable
└── depth_layer.gd         DepthLayer         (Node2D)    un calque de parallaxe

Scenes/World/world.tscn       le monde : salles côte à côte, caméra, flèches (scène principale)
Scenes/Rooms/<Salle>/         une scène par salle
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
texture : l'objet est cliquable exactement là où il est dessiné, sans forme de collision à
tracer. Un `hit_rect` est nécessaire pour un état sans texture (l'encens éteint, le puits
vide, le tas d'or dessiné dans le fond) ou pour agrandir une zone trop fine.

Quand plusieurs objets se chevauchent, celui qui est **le plus bas dans l'arbre de scène**
(donc dessiné par-dessus) gagne.

L'état de chaque instance est sauvegardé dans `GameState` à chaque changement (clé :
chemin de la scène + chemin du nœud) et restauré si la salle est rechargée.

### `PuzzleRoom` : une salle

La racine d'une salle jouable utilise `puzzle_room.gd` (ou un script qui en hérite, comme
`witch.gd` ou `weather.gd`). Quand elle est **active** :

- elle détermine l'objet survolé (surbrillance, curseur main, infobulle) ;
- clic gauche : utilise l'objet en main sur l'objet survolé (ou clic à main vide) ;
- clic droit : lâche l'objet en main.

C'est le monde (voir plus bas) qui active la salle à l'arrivée de la caméra. Une salle
lancée seule avec **F6** s'active d'elle-même, pratique pour la tester.

Autres réglages :

| Propriété | Rôle |
|---|---|
| `debug_items` | Objets donnés par **F9** (build de debug). |
| `required_items` | Objets nécessaires pour entrer la première fois (consommés). |
| `locked_message` / `unlock_message` | Répliques quand c'est fermé / quand on ouvre. |

`on_enter()` est appelée quand la caméra part vers la salle : à surcharger pour la préparer
(c'est là que la salle du Temps change de météo).

Structure type (cf. `Scenes/Rooms/Sun/sun.tscn`) :

```
Sun (Node2D, puzzle_room.gd)
└── Room (Node2D, position 960×540, échelle 0.413)
    ├── Background      (Sprite2D, fond 4777×2792)
    ├── GateauLayer     (DepthLayer, depth 0.038)
    │   └── Gateau      (PuzzleInstance)
    └── CupcakeLayer    (DepthLayer, depth 1.236)
        └── Cupcake     (PuzzleInstance)
```

`Room` centre et met à l'échelle les images 4777×2792 sur l'écran 1920×1080. Les
coordonnées sous `Room` (positions, `hit_rect`, `texture_offset`) sont donc en
**pixels de l'image de fond, origine au centre de l'image**.
Pour convertir un pixel `(x, y)` de l'image : `(x - 2388.5, y - 1396)`.

### Créer une nouvelle salle

1. Dupliquer une salle existante, changer le fond et, si besoin, le script racine.
2. Créer `Data/Puzzles/<Salle>/` et un `.tres` par état (clic droit > Nouvelle ressource >
   `PuzzleObject`).
3. Ajouter un `Sprite2D` par objet, lui mettre `puzzle_instance.gd` et son `initial_state`
   (dans un `DepthLayer` s'il doit avoir de la profondeur).
4. L'instancier sous `Rooms` dans `Scenes/World/world.tscn`, à sa place dans l'ordre.

## Le monde : navigation en diaporama

`Scenes/World/world.tscn` (scène principale) reprend la scène `Main.unity` : toutes les
salles sont **côte à côte** et une caméra glisse de l'une à l'autre.

```
World (world.gd)
├── Rooms          les salles, dans l'ordre : Intro, Witch, Sun, Weather, Donkey, Outro
├── Camera         Camera2D déplacée par un tween
├── Wall0..4       murs noirs entre les salles (créés par le script)
└── Navigation     flèches gauche/droite + « Cliquez pour commencer »
```

- Le script place la salle *i* à `x = i × room_stride` (1973 px, la largeur d'un fond à l'échelle 0,413).
- **Intro** : un clic n'importe où, **Entrée** ou **Espace** lance le glissement vers la
  première salle. On ne peut plus y revenir (comme dans Unity).
- **Flèches** : passent à la salle voisine en `slide_duration` secondes, avec une courbe
  « ease in-out » (Unity : fondu Cinemachine de 2 s). Pendant le glissement, rien n'est cliquable.
- **Clavier** : **←/→**, **Q/A** et **D** font la même chose que les flèches à l'écran
  (Q/A et D par position de touche, donc en AZERTY comme en QWERTY). ←/→ passent par les
  actions `ui_left`/`ui_right` : la croix d'une manette marche aussi.
- **Salle verrouillée** : si la salle visée a des `required_items`, on n'y va que si on les a.
- **Outro** : pas de flèche pour y aller. Quand le joueur obtient `ending_item` (la bourse
  pleine), le monde attend `ending_delay` secondes puis glisse vers l'outro.
- **Suivi de la souris** : la caméra se décale doucement vers le curseur (`look_amount`,
  `look_smoothing`), comme `CameraControl.cs`. Le débattement reste dans la marge du fond.

## La parallaxe : `DepthLayer`

Dans Unity, la caméra était en **perspective** et les objets posés à différentes
profondeurs devant le fond : en glissant d'une salle à l'autre ou en suivant la souris,
les objets proches défilaient plus vite que le fond.

En 2D, un `DepthLayer` (`Scripts/Puzzle/depth_layer.gd`) recrée cet effet : il se décale de
`(centre de la vue - sa position d'origine) × depth`.

| `depth` | Effet |
|---|---|
| 0 | Bouge avec le fond (aucun effet). |
| > 0 | Plus proche : défile plus vite que le fond. |
| < 0 | Plus loin : défile moins vite. |

Le décalage est nul quand la vue est centrée sur la position d'origine du calque : on le
place donc à la position 0 sous `Room`, et ses enfants à leur place « vue de face ».

Les positions, échelles et profondeurs des objets des salles Soleil et Temps sont calculées
depuis les prefabs Unity : pour une profondeur locale `z` (négative = vers la caméra),
`depth = 27,13 / (27,13 + z) - 1`, et la position et l'échelle sont multipliées par
`depth + 1` (projection perspective). Exemple : le cupcake est à `z = -15`, d'où
`depth ≈ 1,24`. Les murs noirs ont `depth = 0,18` (5 unités devant les fonds dans Unity).

Les objets de la salle Witch sont dessinés sur des overlays calés au pixel sur le fond :
ils restent à `depth = 0`.

## Interface (`Hud`)

`Scenes/UI/hud.tscn`, autoload, au-dessus de tout (CanvasLayer 10) :

- **Dialogue** : en bas, affiche les répliques ; disparaît après 2,5 s minimum
  (+ 0,06 s par caractère) ;
- **Inventaire** : barre en bas, cachée tant qu'elle est vide. Clic = prendre en main /
  lâcher ; clic avec un autre objet en main = combiner ;
- **Objet en main** : son icône suit le curseur ;
- **Infobulle** : nom de l'objet survolé, ou « Utiliser X sur Y ».

Le HUD est caché sur l'intro et l'outro. Police : `unity_assets/Art/alagard.ttf` (celle de
la version Unity). Le thème est une sous-ressource de la scène, modifiable dans l'éditeur.

## `GameState`

Autoload qui garde tout ce qui doit survivre aux changements de salle :
inventaire, objet en main, état des instances, compteurs de clics, et des **drapeaux**
libres (`get_flag` / `set_flag`) : météo courante, salles déverrouillées…
`GameState.reset()` remet la partie à zéro.

Signaux : `inventory_changed`, `selected_item_changed(item)`, `message_requested(text)`.

## Images

Les images viennent de `unity_assets/Art/`, copiées sous `Scenes/Rooms/<Salle>/Sprites/`
(décors) et `Scenes/Items/<Salle>/<Objet>/Sprites/` (icônes), avec des noms sans accents.

- Les overlays « plein cadre » (même taille que le fond, presque entièrement transparents)
  sont **recadrés** sur leur dessin, et leur position reportée dans `texture_offset` :
  une image 4777×2792 occupe ≈ 53 Mo de mémoire vidéo, même pour une bougie.
- Les icônes d'inventaire sont réduites à 256 px maximum (elles s'affichent en 96 px).
- Les fonds restent en pleine résolution ; toutes les salles étant chargées en même temps
  (≈ 8 fonds), le jeu utilise quelques centaines de Mo de mémoire vidéo.

## Outils de debug (build de debug uniquement)

| Touche | Effet |
|---|---|
| F1 | Liste l'inventaire dans la console. |
| F6 (éditeur) | Lance la salle ouverte seule, sans le monde. |
| F9 | Ajoute à l'inventaire les `debug_items` de la salle (objets venant d'autres salles). |

Le contenu des salles et la solution du jeu sont décrits dans
[salles-et-enigmes.md](salles-et-enigmes.md).
