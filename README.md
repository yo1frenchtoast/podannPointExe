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
- [Utilisation de l'IA](docs/utilisation-ia.md) : ce qui a été fait avec une IA, et ce qui vient de la jam.

## Utilisation de l'IA

Le jeu d'origine (concept, dessins, textes, code Unity, choix des musiques) vient de la
game jam. Le portage et la finition sous Godot ont été réalisés en 2026 avec **Claude**
(IA d'Anthropic, via Claude Code), sous la direction et avec les tests de l'auteur :
tout le code GDScript, les énigmes des salles Soleil, Temps et Âne, une quinzaine de
répliques, la répartition des musiques et la documentation. Aucune image, musique ni son
n'a été créé par IA générative ; seules deux icônes provisoires de bourse ont été
dessinées par un script.

Le détail est dans [docs/utilisation-ia.md](docs/utilisation-ia.md).

## Lancer le jeu

Ouvrir le dossier dans Godot 4.7+ puis F5. Clic gauche pour interagir, clic droit pour
lâcher l'objet en main, flèches sur les côtés (ou ←/→, Q/D au clavier) pour changer de
salle, Entrée ou Espace pour passer l'intro, M pour couper le son. En debug, F6 lance
la salle ouverte seule et F9 y donne les objets venant des autres salles.
