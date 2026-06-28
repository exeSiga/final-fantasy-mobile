#!/bin/bash
# Godot 4.6+ static compatibility check
# Detects patterns that break at runtime in Godot 4.6+ but compile fine in 4.3.
# Run before every sprint commit. Must output "✅ All clear" with exit code 0.

cd "$(dirname "$0")"
FAIL=0

echo "=== Godot 4.6+ Compatibility Check ==="

# Build list of user-defined class_names (these are the dangerous ones)
USER_CLASSES=$(grep -rh "^class_name " --include="*.gd" . 2>/dev/null | awk '{print $2}' | sort -u | tr '\n' '|' | sed 's/|$//')
if [ -z "$USER_CLASSES" ]; then
  USER_CLASSES="NOCLASSES"
fi

# ── Check 1: Array[UserClass] ────────────────────────────────────────────────
FOUND=$(grep -rn "Array\[" --include="*.gd" . | grep -E "Array\[($USER_CLASSES)\]")
if [ -n "$FOUND" ]; then
  echo "❌ Array[UserClass] (use plain Array instead):"
  echo "$FOUND"
  FAIL=1
fi

# ── Check 2: Typed signal params with user class_names ───────────────────────
FOUND=$(grep -rn "^signal " --include="*.gd" . | grep -E ": ($USER_CLASSES)[,)]")
if [ -n "$FOUND" ]; then
  echo "❌ Typed signal params with user class_names:"
  echo "$FOUND"
  FAIL=1
fi

# ── Check 3: Walrus + as-cast to user class_name ────────────────────────────
FOUND=$(grep -rn ":= .* as [A-Z]" --include="*.gd" . | grep -E " as ($USER_CLASSES)")
if [ -n "$FOUND" ]; then
  echo "❌ Walrus+cast to user class_name (Variant inference error in autoloads):"
  echo "$FOUND"
  FAIL=1
fi

# ── Check 4: Typed for-loop with user class_name ────────────────────────────
FOUND=$(grep -rn "for [a-z_]*: [A-Z]" --include="*.gd" . | grep -E "for [a-z_]*: ($USER_CLASSES)")
if [ -n "$FOUND" ]; then
  echo "❌ Typed for-loop (for e: UserClass in ...):"
  echo "$FOUND"
  FAIL=1
fi

# ── Check 5: class_name + typed signal in same file ─────────────────────────
while IFS= read -r gd_file; do
  if grep -q "^class_name " "$gd_file" && grep -qE "^signal .*: [A-Z]" "$gd_file"; then
    echo "❌ class_name + typed signal in same file: $gd_file"
    FAIL=1
  fi
done < <(find . -name "*.gd" -not -path "./.git/*")

# ── Result ───────────────────────────────────────────────────────────────────
echo ""
if [ $FAIL -eq 0 ]; then
  echo "✅ All clear — safe to commit"
else
  echo "⚠️  Fix the patterns above before committing."
fi

exit $FAIL
