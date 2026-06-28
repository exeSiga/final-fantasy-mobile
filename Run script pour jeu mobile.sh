#!/bin/bash
# run.sh — Lance la boucle de développement autonome
# Usage: bash run.sh
# Relance simplement ce script après chaque limite de tokens

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

# ─── Pre-flight ───────────────────────────────────────────────────────────────
if ! command -v claude &>/dev/null; then
  echo "❌ claude CLI non trouvé. Installe avec: npm install -g @anthropic-ai/claude-code"
  exit 1
fi

if [[ ! -f TASKS.md ]]; then
  echo "❌ TASKS.md introuvable. Lance ce script depuis la racine du projet."
  exit 1
fi

# ─── Vérifier s'il reste des sprints ─────────────────────────────────────────
NEXT=$(grep -m1 "STATUS: TODO\|STATUS: IN_PROGRESS" TASKS.md 2>/dev/null || true)
if [[ -z "$NEXT" ]]; then
  echo "🎉 Tous les sprints sont terminés ! Voir DONE.md"
  exit 0
fi

# ─── Résumé de session ────────────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║     🎮 Final Fantasy Mobile — Dev Loop               ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""
echo "▶ Prochain sprint: $NEXT"
echo ""

if [[ -f SESSION_LOG.md ]]; then
  echo "📋 Sessions précédentes:"
  tail -3 SESSION_LOG.md | sed 's/^/   /'
  echo ""
fi

echo "🚀 Lancement de Claude Code..."
echo "   Ctrl+C pour mettre en pause proprement."
echo ""

# ─── Lancement ────────────────────────────────────────────────────────────────
claude \
  "MODE AUTONOME — Final Fantasy Mobile (Godot 4)

ACTIONS AU DÉMARRAGE:
1. Lis SESSION_LOG.md (dernières 3 lignes) pour savoir où tu en es
2. Lis TASKS.md — trouve le premier sprint STATUS: TODO ou IN_PROGRESS
3. Lis CLAUDE.md une seule fois pour les règles du projet
4. Travaille sur le sprint. N'ouvre que les fichiers nécessaires.
5. Code review (checklist dans CLAUDE.md)
6. Marque le sprint DONE dans TASKS.md, remplis les review notes
7. git add -A && git commit -m 'feat(sprint-N): nom du sprint'
8. Ajoute UNE ligne à SESSION_LOG.md: [date] Sprint N — DONE — ~XXXX tokens
9. Enchaîne avec le sprint suivant sans pause
10. Si plus de sprint TODO: écris DONE.md et arrête-toi proprement

RÈGLES TOKEN:
- Utilise grep/find pour localiser du code, pas cat sur tout le projet
- Lance /compact quand le contexte est à 60% (vérifie avec /cost)
- Avant /compact: mets à jour TASKS.md et commite

IMPORTANT: Ne t'arrête pas entre les sprints. Boucle jusqu'aux tokens."
