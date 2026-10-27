# Salles et énigmes

Contenu des salles et solution complète du jeu. Le fonctionnement du moteur est décrit
dans [moteur-de-puzzle.md](moteur-de-puzzle.md).

## D'où viennent les énigmes

Dans le projet Unity, seuls quelques enchaînements de la salle Lune étaient branchés.
Les salles Soleil, Temps et Âne n'avaient que des **répliques**, sans aucune transition.
Les énigmes ci-dessous ont été **reconstruites** à partir :

- des répliques Unity (`unity_assets/Features/<Salle>/*.asset`), reprises telles quelles ;
- des noms et du contenu des images (`PONEY_GERBE`, `çake+arç en çiel+partition`,
  `Weather_key_glow`, `Stick+line_icon`…) ;
- des positions des prefabs dans `Main.unity`.

Tout est dans `Data/Puzzles/` : on peut changer l'ordre, les objets ou les répliques
sans toucher au code.

## Ordre des salles

```
Intro → Lune (sorcière) ⇄ Soleil ⇄ Temps ⇄ Âne → Outro
```

- **Intro** : un clic pour commencer.
- **Âne** : fermée par trois serrures, il faut les trois clés (Lune, Soleil, Temps).
- **Outro** : atteinte automatiquement quand on a rempli la bourse.

## Lune (sorcière) — `Scenes/Rooms/Witch/`

| Objet | Ce qui se passe |
|---|---|
| Bougie | clic → ramassée |
| Encens | + bougie (gardée) → encens allumé |
| Fiole | clic → fiole vide ramassée |
| Tapis | clic → **morceau de tissu** (le tapis reste) |
| Plante | + flacon de pluie → arrosée → + rayon de soleil → la clé apparaît → clic → **clé de la Lune** |
| Rouet | + roue → + coton → **bobine de fil** |

## Soleil — `Scenes/Rooms/Sun/`

| Objet | Ce qui se passe |
|---|---|
| Soleil | clic → **rayon de soleil** ; le soleil reste croqué |
| Cupcake | clic → ramassé |
| Poney | + cupcake → il vomit un arc-en-ciel → clic → **arc-en-ciel** |
| Partition | + note de musique → partition complète → clic → ramassée |
| Pâte à gâteau | + arc-en-ciel → + partition → clic : le gâteau se fait en chanson → clic → **clé du Soleil** |

## Temps — `Scenes/Rooms/Weather/`

**La météo change à chaque fois qu'on entre** : soleil → nuages → pluie → soleil…
(comme dans Unity). Seuls les objets de la météo courante sont visibles.

| Objet | Météo | Ce qui se passe |
|---|---|---|
| Charrette | toutes | clic → **roue** (la charrette se casse) → clic → **bâton** |
| Puits | toutes | + fiole vide → **flacon de pluie** ; + canne à pêche → **clé du Temps** |
| Oiseaux | soleil, nuages | réplique seulement |
| Nuage | nuages | clic → **coton** |
| Chant des oiseaux | soleil, **après avoir vu la pluie** | clic → **note de musique** |

La pluie n'a pas d'objet cliquable. Elle sert à faire chanter les oiseaux (il faut l'avoir
vue une fois).

**Effet de pluie** (calque `Room/Rainy` de `weather.tscn`) : deux `CPUParticles2D` qui
partagent une goutte dessinée par un dégradé (`GradientTexture2D`, rien à importer) :

- `FarRain` : pluie de fond, fine et transparente, derrière la charrette ;
- `NearRain` : pluie de premier plan, plus grosse et plus rapide, dans un `DepthLayer`
  (`depth` 0,4, `z_index` 5) pour passer devant le décor et bouger en parallaxe.

Réglages utiles dans l'inspecteur : `amount` (densité), `initial_velocity_*` (vitesse),
`direction` (inclinaison), `color` (opacité), `scale_amount_*` (taille des gouttes).

Combinaison dans l'inventaire : **bâton + bobine de fil → canne à pêche** (la bobine est gardée).

## Âne — `Scenes/Rooms/Donkey/`

Entrée : les trois clés (consommées).

| Objet | Ce qui se passe |
|---|---|
| Peau d'âne | réplique seulement |
| Tas d'or | + bourse → **bourse pleine** → fin du jeu |

Combinaison dans l'inventaire : **tissu + bobine de fil → bourse** (la bobine est gardée).

## Solution complète

1. **Lune** : prendre la bougie, la fiole, le tissu (tapis). Allumer l'encens avec la bougie (facultatif).
2. **Soleil** : cliquer le soleil (rayon), prendre le cupcake, le donner au poney, cliquer le poney (arc-en-ciel), mettre l'arc-en-ciel dans la pâte.
3. **Temps** (soleil) : cliquer la charrette (roue) puis encore (bâton).
4. Ressortir et revenir jusqu'aux **nuages** : cliquer le nuage (coton).
5. **Lune** : roue puis coton sur le rouet (bobine). Bâton + bobine (canne à pêche), tissu + bobine (bourse).
6. **Temps** : fiole sur le puits (flacon de pluie), canne à pêche sur le puits (clé du Temps).
   Ressortir et revenir jusqu'à la **pluie** (pour débloquer le chant des oiseaux).
7. **Temps** jusqu'au **soleil** : cliquer le chant des oiseaux (note).
8. **Soleil** : note sur la partition, cliquer la partition, la mettre dans la pâte, cliquer deux fois le gâteau (clé du Soleil).
9. **Lune** : flacon de pluie puis rayon de soleil sur la plante, cliquer la plante (clé de la Lune).
10. **Âne** : entrer avec les trois clés, bourse sur le tas d'or → outro.

## Répliques ajoutées

Unity n'en avait pas pour ces moments, elles sont nouvelles (à réécrire librement) :

- Soleil : « Il a une bonne tête, ce soleil. », « Il en manque un morceau... ça repoussera. »
- Cupcake : « Un cupcake à la fraise. Pas pour moi. »
- Poney : « Beurk. Mais c'est joli. », « Il a l'air soulagé. »
- Partition (inventaire) : « Une partition complète, prête à être chantée. »
- Gâteau : « Il manque encore un peu de couleur. », « Il n'en reste plus une miette. »
- Nuage : « Il est un peu moins dodu qu'avant. » ; charrette : « Il n'y a plus rien à en tirer. »
- Puits : « La pêche a été bonne ! Voilà, la clé du Temps ! » (deux répliques Unity réunies),
  « Un peu de l'eau de pluie du puits... Une pluie salvatrice ! »
- Tapis : « Il lui manque un bout. Ça ne se verra pas. »
- Tissu + bobine : « Un peu de couture... et voilà une bourse ! »
- Plante : « Elle a surtout soif, là. » ; rouet : « Sans roue, ce rouet ne filera rien du tout. »
- Porte de l'âne : « Une porte à trois serrures… », « Les trois clés tournent... la porte s'ouvre ! »
- Clé de la Lune : « La clé de la Lune ! » ; bobine : « Une bobine de fil. »

## Différences avec Unity et points ouverts

- La fiole se remplit au **puits** et non sous la pluie (Unity : `rain` + fiole), car
  aucune pluie n'est dessinée et le puits est l'endroit qui attire l'œil.
- La plante n'est plus ramassable (Unity : `plant-neutre` → inventaire, ce qui bloquait l'arrosage).
- L'emplacement de l'encens reprend celui de la fumée (`Encent.prefab`).
- **Bourses** : aucun dessin dans le projet Unity. Les icônes
  (`Scenes/Items/Donkey/Purse/Sprites/`) sont des placeholders dessinés par script (sac
  en tissu à lunes, vide / débordant de pièces), à remplacer par un vrai dessin.
  La bourse prend la place du tissu dans l'inventaire.
- **Non utilisés** : lavande (`lavander`, pas de position connue), lune en métal
  (`lune-metal`), musiques et sons de `unity_assets/Audio/` (aucun n'était branché),
  `Scenes/Items/Witch/Candle/Candle.tscn`, `Scenes/Items/Witch/Lavanda/`.
- **Outro** : simple image, pas de crédits ni de retour au menu.
