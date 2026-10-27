# podannPointExe

Point & click réalisé pendant une game jam sous Unity, en cours de finition et de portage
vers **Godot 4.7** (version Steam).

## Organisation

| Dossier | Contenu |
|---|---|
| `Scenes/Rooms/` | Les salles (intro, sorcière, soleil, outro) |
| `Scenes/Items/` | Sprites des objets (icônes, sprites recadrés) |
| `Scenes/UI/` | Interface : dialogue, inventaire, curseur (`hud.tscn`) |
| `Scripts/Puzzle/` | Moteur de puzzle générique |
| `Scripts/Autoload/` | État global de la partie (`GameState`) |
| `Data/Puzzles/<Salle>/` | Données des énigmes (`.tres`) |
| `unity_assets/` | Projet Unity d'origine (référence : scripts, textes, sprites, sons) |
| `docs/` | Documentation |

## Documentation

- [Moteur de puzzle](docs/moteur-de-puzzle.md) : fonctionnement, création d'énigmes et de
  salles, état de la salle Witch.

## Lancer le jeu

Ouvrir le dossier dans Godot 4.7+ puis F5. Clic gauche pour interagir, clic droit pour
lâcher l'objet en main. En debug, F9 donne les objets des salles pas encore portées.
