#!/bin/bash
# test_visual.sh — Lance le jeu dans un écran virtuel et prend des captures d'écran
# Usage: bash test_visual.sh [scene_path]
#   scene_path: optionnel, ex: "res://scenes/combat/Battle.tscn"
#               sans argument: lance la scene principale (MainMenu)

set -e
GAME_DIR="/home/siga/final-fantasy-mobile"
GODOT="/home/siga/godot4"
DISPLAY_NUM=":98"
SHOTS_DIR="/tmp/game_screenshots"
SCENE="${1:-}"

mkdir -p "$SHOTS_DIR"
rm -f "$SHOTS_DIR"/*.png

echo "=== Visual Test ==="

# Arrêter tout Xvfb existant sur :98
pkill -f "Xvfb $DISPLAY_NUM" 2>/dev/null || true
sleep 0.3

# Démarrer Xvfb 1080x1920
Xvfb $DISPLAY_NUM -screen 0 1080x1920x24 -ac &
XVFB_PID=$!
sleep 0.8

echo "Xvfb démarré (PID $XVFB_PID)"

# Lancer Godot
if [ -n "$SCENE" ]; then
    DISPLAY=$DISPLAY_NUM "$GODOT" --path "$GAME_DIR" --scene "$SCENE" &
else
    DISPLAY=$DISPLAY_NUM "$GODOT" --path "$GAME_DIR" &
fi
GODOT_PID=$!
echo "Godot lancé (PID $GODOT_PID)"

# Captures d'écran à intervalles
take_shot() {
    local label="$1"
    local delay="$2"
    sleep "$delay"
    DISPLAY=$DISPLAY_NUM import -window root -resize 540x960 "$SHOTS_DIR/${label}.png" 2>/dev/null \
        && echo "  📸 $label" \
        || echo "  ⚠️  échec capture $label"
}

take_shot "01_startup_2s"  2
take_shot "02_scene_5s"    3
take_shot "03_scene_9s"    4
take_shot "04_scene_14s"   5

# Nettoyage
kill $GODOT_PID 2>/dev/null || true
sleep 0.2
kill $XVFB_PID  2>/dev/null || true

echo ""
echo "Screenshots dans $SHOTS_DIR :"
ls -lh "$SHOTS_DIR"/*.png 2>/dev/null || echo "(aucun)"
echo ""
echo "Pour voir une image : convert $SHOTS_DIR/04_scene_14s.png -display :0 x: 2>/dev/null"
echo "Ou : cat $SHOTS_DIR/04_scene_14s.png | base64 | head -5  (debug)"
