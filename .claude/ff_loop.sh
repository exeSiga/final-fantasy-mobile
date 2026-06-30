#!/bin/bash
# Boucle autonome FF Mobile — tourne en continu, pause 5h entre sessions
REPO="/home/siga/final-fantasy-mobile"
LOG="$REPO/.claude/loop.log"
INTERVAL=18000  # 5 heures

cd "$REPO"

while true; do
  echo "" | tee -a "$LOG"
  echo "=== $(date '+%Y-%m-%d %H:%M') === Démarrage session ===" | tee -a "$LOG"

  claude --dangerously-skip-permissions \
    -p "Lis SESSION_LOG.md et TASKS.md. Implémente tous les sprints STATUS: TODO en suivant exactement les instructions de CLAUDE.md (4 phases par sprint : lecture, implémentation, contrôle, clôture). Enchaîne sprint après sprint. Si plus aucun sprint TODO, génère 3 à 5 nouveaux sprints FF7 dans TASKS.md avant de continuer." \
    2>&1 | tee -a "$LOG"

  echo "=== $(date '+%Y-%m-%d %H:%M') === Session terminée. Prochaine dans 5h ===" | tee -a "$LOG"
  sleep $INTERVAL
done
