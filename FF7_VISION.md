# FF7_VISION.md — Génération Autonome de Sprints
> Ce fichier est lu UNIQUEMENT quand il n'y a plus de sprint STATUS: TODO dans TASKS.md.

## Règle de génération
- Génère 3 à 5 sprints d'un coup, numérotés à la suite du dernier sprint existant
- Chaque sprint doit faire avancer le jeu vers l'expérience Final Fantasy 7
- Priorise les features qui ont le plus d'impact gameplay visible en premier
- Chaque sprint doit être faisable en une session (scope raisonnable)
- Utilise le format complet avec Acceptance Criteria + Verification Notes vides

## Règles de priorisation
1. **Ne génère jamais deux fois la même feature** — consulte TASKS_ARCHIVE.md + TASKS.md
2. **Commence par les features les plus visibles** — un joueur doit voir la différence immédiatement
3. **Évite les features trop dépendantes d'assets** — tout doit rester procédural
4. **Un sprint = une feature cohérente** — pas de mélanges de systèmes non liés
5. **Scope réaliste** — si une feature est trop grande, la découper en 2 sprints

## Vision FF7 — Features restantes (par priorité décroissante)

**Système de Combat Avancé :**
- Limit Breaks tier 2 : chaque personnage a 2 niveaux de Limit
- New Game+ : difficulté augmentée, ennemis avec stats ×1.5
- Barret (Gunner AoE), Red XIII (Beastmaster) comme membres de party

**Monde & Exploration :**
- Districts de Midgar : Secteur 1 (Réacteur), Secteur 5 (Slums), Sector 7 (Bar Seventh Heaven)
- Choix de dialogues avec conséquences (flags booléens simples)
- Récompenses de donjon uniques (équipements introuvables en shop)

**Boss & Contenu Endgame :**
- Jenova améliorée avec phases supplémentaires
- Ruby/Emerald Weapon (boss optionnels ultra-difficiles)

**Polish & Immersion :**
- Notifications de lore (pop-up "Fichier Shinra" débloqué après certains combats)
- Écran de Game Over amélioré (citation Sephiroth + option retry)
- Scènes narratives clés : Réacteur Mako, Rencontre avec Sephiroth

## Format sprint à ajouter dans TASKS.md
```
## Sprint N — [Nom feature FF7] [STATUS: TODO]
**Goal:** Description une ligne

**Acceptance Criteria:**
- [ ] AC1: (observable, testable)
- [ ] AC2:
- [ ] AC3:

**Tasks:**
- [ ] Tâche 1
- [ ] Tâche 2

**Verification Notes:**
- Contrôle A (static):
- Contrôle B (godot parse):
- Contrôle C (logic trace):
- Contrôle D (regression):
- Déferments:
```
