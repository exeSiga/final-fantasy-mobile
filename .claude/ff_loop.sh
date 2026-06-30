#!/bin/bash
# Boucle autonome FF Mobile — tourne en continu, pause 5h entre sessions
REPO="/home/siga/final-fantasy-mobile"
LOG="$REPO/.claude/loop.log"
INTERVAL=18000  # 5 heures

# PATH complet pour systemd (ne charge pas .bashrc/.nvm)
export NVM_DIR="/home/siga/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
export PATH="/home/siga/.nvm/versions/node/v23.11.0/bin:$PATH"

cd "$REPO"

while true; do
  echo "" | tee -a "$LOG"
  echo "=== $(date '+%Y-%m-%d %H:%M') === Démarrage session ===" | tee -a "$LOG"

  claude --dangerously-skip-permissions \
    --model claude-sonnet-4-6 \
    -p "Lis SESSION_LOG.md et TASKS.md. Implémente tous les sprints STATUS: TODO en suivant exactement les instructions de CLAUDE.md (4 phases par sprint : lecture, implémentation, contrôle, clôture). Enchaîne sprint après sprint. Si plus aucun sprint TODO, génère 3 à 5 nouveaux sprints FF7 dans TASKS.md avant de continuer." \
    2>&1 | tee -a "$LOG"

  echo "=== $(date '+%Y-%m-%d %H:%M') === Session terminée. Prochaine dans 5h ===" | tee -a "$LOG"

  # Garder SESSION_LOG.md léger (10 dernières lignes)
  if [ -f "$REPO/SESSION_LOG.md" ]; then
    tail -10 "$REPO/SESSION_LOG.md" > "$REPO/SESSION_LOG.tmp" && mv "$REPO/SESSION_LOG.tmp" "$REPO/SESSION_LOG.md"
  fi

  # Archiver les nouveaux sprints DONE dans TASKS.md (garder 2 DONE + tous les TODO)
  sleep $INTERVAL
done
