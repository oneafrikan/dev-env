#!/usr/bin/env bash
# ─────────────────────────────────────────────
# llm/run.sh — central LLM wrapper
# All scripts must call this; never call `llm` directly
#
# Usage: llm-run [OPTIONS] "prompt"
#        echo "content" | llm-run [OPTIONS] "prompt"
#
# Options:
#   -m, --model MODEL    Override model (ignores config)
#   -s, --system PROMPT  System prompt (or path to .txt file)
#   -t, --template NAME  Use a named template from llm/templates/
#   -p, --provider NAME  Force provider: anthropic|openai|ollama|gemini
#   --local              Force local Ollama model
#   --raw                Pass remaining args directly to llm unchanged
# ─────────────────────────────────────────────
set -euo pipefail

DEV_ENV="${DEV_ENV:-$HOME/.dev-env}"
TEMPLATES_DIR="$DEV_ENV/llm/templates"

log()  { echo "  [llm/run.sh] $1"; }
warn() { echo "  ⚠ $1"; }
err()  { echo "  ✗ $1" >&2; }

# ── Load config ───────────────────────────────
# shellcheck source=llm/config.sh
source "$DEV_ENV/llm/config.sh"

# ── Check llm is installed ────────────────────
if ! command -v llm &>/dev/null; then
  err "llm is not installed. Run: uv tool install llm"
  exit 1
fi

# ── Parse args ────────────────────────────────
MODEL=""
SYSTEM_PROMPT=""
TEMPLATE=""
PROVIDER=""
LOCAL_MODE=false
RAW_MODE=false
POSITIONAL=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -m|--model)    MODEL="$2";         shift 2 ;;
    -s|--system)   SYSTEM_PROMPT="$2"; shift 2 ;;
    -t|--template) TEMPLATE="$2";      shift 2 ;;
    -p|--provider) PROVIDER="$2";      shift 2 ;;
    --local)       LOCAL_MODE=true;    shift   ;;
    --raw)         RAW_MODE=true;      shift   ;;
    *)             POSITIONAL+=("$1"); shift   ;;
  esac
done

# ── Raw passthrough ───────────────────────────
if [[ "$RAW_MODE" == true ]]; then
  exec llm "${POSITIONAL[@]}"
fi

# ── Resolve model ─────────────────────────────
# Priority: -m flag > LLM_MODEL env > config DEFAULT_MODEL > hardcoded fallback
if [[ "$LOCAL_MODE" == true ]]; then
  RESOLVED_MODEL="${OLLAMA_DEFAULT_MODEL:-llama3.2}"
  PROVIDER="ollama"
elif [[ -n "$MODEL" ]]; then
  RESOLVED_MODEL="$MODEL"
elif [[ -n "${LLM_MODEL:-}" ]]; then
  RESOLVED_MODEL="$LLM_MODEL"
elif [[ -n "${LLM_DEFAULT_MODEL:-}" ]]; then
  RESOLVED_MODEL="$LLM_DEFAULT_MODEL"
else
  RESOLVED_MODEL="claude-sonnet-4-6"
fi

# ── Provider checks ───────────────────────────
if [[ "$LOCAL_MODE" == true ]] || [[ "${PROVIDER:-}" == "ollama" ]]; then
  if ! curl -sf "$OLLAMA_HOST/api/tags" &>/dev/null; then
    warn "Ollama is not reachable at $OLLAMA_HOST — is it running?"
    warn "Start with: ollama serve"
    exit 1
  fi
fi

# ── Check provider plugin installed ──────────
case "${PROVIDER:-}" in
  anthropic)
    if ! llm plugins 2>/dev/null | grep -q "llm-anthropic"; then
      err "llm-anthropic plugin not installed. Run: llm install llm-anthropic"
      exit 1
    fi
    ;;
  openai)
    if ! llm plugins 2>/dev/null | grep -q "llm-openai\|openai"; then
      err "llm-openai plugin not installed. Run: llm install llm-openai"
      exit 1
    fi
    ;;
  gemini)
    if ! llm plugins 2>/dev/null | grep -q "llm-gemini"; then
      err "llm-gemini plugin not installed. Run: llm install llm-gemini"
      exit 1
    fi
    ;;
esac

# ── Resolve system prompt ─────────────────────
SYSTEM_ARGS=()

if [[ -n "$TEMPLATE" ]]; then
  TEMPLATE_FILE="$TEMPLATES_DIR/${TEMPLATE}.txt"
  if [[ ! -f "$TEMPLATE_FILE" ]]; then
    err "Template not found: $TEMPLATE_FILE"
    err "Available templates: $(ls "$TEMPLATES_DIR"/*.txt 2>/dev/null | xargs -I{} basename {} .txt | tr '\n' ' ')"
    exit 1
  fi
  SYSTEM_ARGS=("--system" "$(cat "$TEMPLATE_FILE")")
elif [[ -n "$SYSTEM_PROMPT" ]]; then
  if [[ -f "$SYSTEM_PROMPT" ]]; then
    SYSTEM_ARGS=("--system" "$(cat "$SYSTEM_PROMPT")")
  else
    SYSTEM_ARGS=("--system" "$SYSTEM_PROMPT")
  fi
fi

# ── Build prompt from positional args ─────────
PROMPT="${POSITIONAL[*]:-}"

# ── Token warning (best-effort, ttok optional) ─
if command -v ttok &>/dev/null && [[ -n "$PROMPT" ]]; then
  TOKEN_COUNT=$(echo "$PROMPT" | ttok 2>/dev/null || echo 0)
  if [[ "$TOKEN_COUNT" -gt "$LLM_TOKEN_WARN_THRESHOLD" ]]; then
    warn "Prompt is ~${TOKEN_COUNT} tokens (threshold: ${LLM_TOKEN_WARN_THRESHOLD})"
  fi
fi

# ── Execute ───────────────────────────────────
CMD=(llm -m "$RESOLVED_MODEL" "${SYSTEM_ARGS[@]}")

if [[ -n "$PROMPT" ]]; then
  exec "${CMD[@]}" "$PROMPT"
else
  # Piped stdin — pass through
  exec "${CMD[@]}"
fi
