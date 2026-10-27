# Utilisation de l'IA

Ce document précise ce qui, dans ce projet, a été produit avec une IA et ce qui vient
des humains, pour que chacun sache d'où vient chaque partie.

## En bref

- **Le jeu d'origine est humain** : le concept, les dessins, les textes et le code Unity
  viennent de la game jam (`unity_assets/`), tout comme l'ébauche de portage Godot de 2023
  (salles Intro, Sorcière, Soleil, Outro sans mécanique).
- **Le portage et la finition sous Godot (octobre 2026) ont été faits avec une IA** :
  Claude (modèle Claude Opus 5.5, via Claude Code), à la demande et sous la direction de
  Yoan Tanguy, qui a testé le jeu, fait les retours et validé chaque étape.
- **Aucune image, musique ni son n'a été généré par une IA générative.** L'IA a seulement
  recadré, redimensionné et renommé les images existantes, et dessiné par programme deux
  icônes provisoires (voir plus bas).

## Détail par partie

### Code — écrit par l'IA

Tout le code GDScript actuel a été écrit par l'IA, d'après le code Unity de la jam
(`unity_assets/Scripts/`) et les demandes de l'auteur :

- `Scripts/Puzzle/` : moteur de puzzle (`PuzzleObject`, `PuzzleInteraction`,
  `PuzzleInstance`, `PuzzleRoom`), parallaxe (`DepthLayer`) ;
- `Scripts/Autoload/` : état de la partie (`GameState`), son (`Audio`) ;
- `Scenes/UI/`, `Scenes/World/`, `Scenes/Rooms/*/Scripts/` : interface, navigation entre
  les salles, météo.

Les scènes `.tscn` ont été réécrites ou créées par l'IA (salles, monde, HUD, audio). Les
positions des objets des salles Soleil et Temps sont calculées depuis les prefabs Unity.
`Scenes/Items/Witch/Candle/Candle.tscn` est une scène de 2023, non modifiée (inutilisée).

### Énigmes — en partie conçues par l'IA

| Partie | Origine |
|---|---|
| Salle Lune (sorcière) | Enchaînements repris de Unity : ramasser la bougie et la fiole, allumer l'encens. Chaînes de la plante, du rouet et du tapis **reconstruites par l'IA** à partir des états et images existants |
| Salle Temps | Repris de Unity : le nuage donne du coton, la fiole se remplit de pluie (déplacé ensuite au puits). Le reste (charrette, chant des oiseaux, canne à pêche, puits) **conçu par l'IA** |
| Salles Soleil, Âne | **Conçues par l'IA** : dans Unity, ces salles n'avaient que des répliques, sans aucun enchaînement |

L'IA a déduit les énigmes manquantes des répliques et des noms et contenus des images
(`PONEY_GERBE`, `çake+arç en çiel+partition`, `Weather_key_glow`…). La météo qui change à
chaque visite vient du code Unity (`ScreenControl.cs`).
| Porte à trois clés, fin du jeu | Proposées par l'IA |
| Fiole remplie au puits | Demande de l'auteur après test (au lieu de la pluie) |

Les données des énigmes (`Data/Puzzles/*.tres`) ont été générées par des scripts écrits
par l'IA, à partir des fichiers Unity.

### Textes

- **Répliques** : reprises telles quelles des fichiers Unity de la jam.
- **Une quinzaine de répliques ajoutées par l'IA** là où Unity n'avait rien (ex.
  « Beurk. Mais c'est joli. », porte de l'âne). Elles sont toutes listées dans
  [salles-et-enigmes.md](salles-et-enigmes.md#répliques-ajoutées).
- **Documentation** (`README.md`, `docs/`) : rédigée par l'IA.

### Images

- **Dessins et photos** : ceux de la jam, non modifiés sur le fond.
- **Traitements faits par l'IA (par script, sans IA générative)** : copie sous des noms
  sans accents, recadrage des overlays sur leur dessin, réduction des icônes
  d'inventaire à 256 px.
- **Dessiné par l'IA** : les deux icônes de **bourse**
  (`Scenes/Items/Donkey/Purse/Sprites/`), tracées par un script Python (formes simples),
  faute de dessin dans le projet. Ce sont des placeholders à remplacer.
- **Effet de pluie** : particules Godot avec une goutte en dégradé, réglées par l'IA.

### Musiques et sons

- **Fichiers** : ceux de la jam (`unity_assets/Audio/`), non modifiés. Aucun n'était
  branché dans le jeu Unity.
- **Choix faits par l'IA** : répartition des musiques par salle (selon leur dossier) et
  choix des effets pour chaque action (ramassage, échec, porte…). Le tableau est dans
  [salles-et-enigmes.md](salles-et-enigmes.md#musiques).

### Vérifications

L'IA a vérifié son travail avec Godot en mode console (import du projet, scripts de test
des énigmes, de la navigation et du son, captures d'écran). L'auteur a joué le jeu en
entier dans l'éditeur et signalé les problèmes (énigme de la pluie peu claire, bourse
invisible dans l'inventaire), corrigés ensuite.

## Historique

| Commit | Contenu | IA |
|---|---|---|
| `8990681`, `972ce16` (2023) | Projet Unity de la jam, ébauche Godot | non |
| `49830fb` | Moteur de puzzle, salle Sorcière | oui |
| `7aad062` | Toutes les salles, navigation, parallaxe, pluie | oui |
| `bc35236` | Musiques et effets sonores | oui |

Les commits faits avec l'IA portent la mention
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
