# podannPointExe

Point & click réalisé pendant une game jam sous Unity, en cours de finition et de portage
vers **Godot 4.7** (version Steam).

## Organisation

| Dossier | Contenu |
|---|---|
| `Scenes/World/` | Le monde : salles côte à côte, caméra, navigation (scène principale) |
| `Scenes/Rooms/` | Les salles (intro, sorcière, soleil, temps, âne, outro) |
| `Scenes/Items/` | Sprites des objets (icônes, sprites recadrés) |
| `Scenes/UI/` | Interface : dialogue, inventaire, curseur (`hud.tscn`) |
| `Scripts/Puzzle/` | Moteur de puzzle générique |
| `Scripts/Autoload/` | État global de la partie (`GameState`) |
| `Data/Puzzles/<Salle>/` | Données des énigmes (`.tres`) |
| `unity_assets/` | Projet Unity d'origine (référence : scripts, textes, sprites, sons) |
| `docs/` | Documentation |

## Documentation

- [Moteur de puzzle](docs/moteur-de-puzzle.md) : fonctionnement, création d'énigmes et de
  salles, navigation entre les salles, parallaxe.
- [Salles et énigmes](docs/salles-et-enigmes.md) : contenu de chaque salle et solution complète.

## Lancer le jeu

Ouvrir le dossier dans Godot 4.7+ puis F5. Clic gauche pour interagir, clic droit pour
lâcher l'objet en main, flèches sur les côtés (ou ←/→, Q/D au clavier) pour changer de
salle, Entrée ou Espace pour passer l'intro. En debug, F6 lance
la salle ouverte seule et F9 y donne les objets venant des autres salles.
