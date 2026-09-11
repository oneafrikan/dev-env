#!/usr/bin/env bash
# ─────────────────────────────────────────────
# secrets/secret-scan.sh — scan repos for leaked secrets
# Uses gitleaks if available, falls back to regex scan
# ─────────────────────────────────────────────
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'

SCAN_ROOTS=(
  "$HOME/project-a"
  "$HOME/project-b"
  "$HOME/project-c"
  "$HOME/.dev-env"
)

# Pattern: never print matched value — only file and line
SECRET_PATTERN='(api_key|secret|password|token|private_key|AKIA|BEGIN RSA|BEGIN EC)["\s=:]+[A-Za-z0-9/+=_-]{16,}'

HITS=0

echo ""
echo "  Secret scan:"
echo ""

for ROOT in "${SCAN_ROOTS[@]}"; do
  [[ ! -d "$ROOT" ]] && continue
  REPO_NAME=$(basename "$ROOT")
  echo "  Scanning $REPO_NAME..."

  if command -v gitleaks &>/dev/null; then
    # Use gitleaks — it never prints the secret value
    GITLEAKS_OUT=$(gitleaks detect --source="$ROOT" --no-git --exit-code 1 2>&1 || true)
    LEAK_COUNT=$(echo "$GITLEAKS_OUT" | grep -c "^MSG\|leaks found\|Finding:" 2>/dev/null || echo 0)
    if [[ "$LEAK_COUNT" -gt 0 ]]; then
      printf "  ${RED}✗${NC} $REPO_NAME — gitleaks found issues:\n"
      echo "$GITLEAKS_OUT" | grep -v "secret\|Secret\|value\|Value" | head -20 | sed 's/^/    /'
      HITS=$((HITS + LEAK_COUNT))
    else
      printf "  ${GREEN}✓${NC} $REPO_NAME — gitleaks clean\n"
    fi
  else
    # Fallback: regex scan — never print the matched value
    while IFS= read -r line; do
      FILE=$(echo "$line" | cut -d: -f1)
      LINENO=$(echo "$line" | cut -d: -f2)
      printf "  ${RED}✗${NC} Potential secret at %s:%s\n" "$FILE" "$LINENO"
      HITS=$((HITS + 1))
    done < <(grep -rnE "$SECRET_PATTERN" "$ROOT" \
      --include="*.py" --include="*.sh" --include="*.env" --include="*.yaml" \
      --include="*.yml" --include="*.json" --include="*.toml" \
      --exclude-dir=".git" --exclude-dir=".venv" \
      -l 2>/dev/null | xargs -I{} grep -nE "$SECRET_PATTERN" {} | \
      awk -F: '{print $1":"$2}' 2>/dev/null || true)

    if [[ "$HITS" -eq 0 ]]; then
      printf "  ${GREEN}✓${NC} $REPO_NAME — no patterns matched\n"
    fi
  fi
done

echo ""
if [[ "$HITS" -gt 0 ]]; then
  printf "  ${RED}✗${NC} %s potential secret(s) found — review immediately\n" "$HITS"
  exit 1
else
  printf "  ${GREEN}✓${NC} No secrets detected\n"
fi
echo ""
