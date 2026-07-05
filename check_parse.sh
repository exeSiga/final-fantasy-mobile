#!/bin/bash
# check_parse.sh — Contrôle B : validation statique réelle de tous les scripts GDScript.
#
# Remplace `godot4 --headless --check-only .` : ce flag est réservé aux builds "editor" de
# Godot (voir `godot4 --help`, --check-only est marqué [X]) et ne rend jamais la main sur le
# binaire export/release installé ici — un `timeout` sur cette commande tue le process sans
# qu'il ait rien vérifié, et un `grep "SCRIPT ERROR"` sur une sortie vide affiche donc toujours
# "aucune erreur" à tort. Constaté après 60+ sprints où ce contrôle était un no-op silencieux.
#
# Cette version charge chaque script .gd du projet (tools/validate_scripts.gd), ce qui déclenche
# la même compilation statique GDScript et fait remonter les mêmes erreurs de parse — mais avec
# une commande qui se termine réellement.
#
# Doit afficher "✅ All clear" avec exit code 0. Si ❌ : corriger avant de continuer.

cd "$(dirname "$0")"
GODOT="/home/siga/godot4"

echo "=== Contrôle B — Parse GDScript (validate_scripts.gd) ==="

OUTPUT=$(timeout -s KILL 60 "$GODOT" --headless --path . --script res://tools/validate_scripts.gd 2>&1)
EXIT_CODE=$?

if [ $EXIT_CODE -eq 137 ] || [ $EXIT_CODE -eq 124 ]; then
  echo "$OUTPUT"
  echo ""
  echo "❌ La commande a été tuée par le timeout — le contrôle lui-même n'a rien vérifié."
  echo "   Ne PAS considérer ça comme un succès. Corriger le script ou le binaire Godot avant de continuer."
  exit 1
fi

echo "$OUTPUT"
echo ""

FOUND=$(echo "$OUTPUT" | grep -E "SCRIPT ERROR|Failed to load script")
if [ -n "$FOUND" ]; then
  echo "❌ Erreurs de parse détectées — corriger avant de committer."
  exit 1
fi

echo "✅ All clear — safe to commit"
exit 0
