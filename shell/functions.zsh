# ─────────────────────────────────────────────
# shell/functions.zsh
# Source from .zshrc:
#   source "$HOME/.dev-env/shell/functions.zsh"
# ─────────────────────────────────────────────

# DEV_ENV = repo root (parent of shell/), so the clone can live anywhere. Falls back to
# ~/.dev-env if this file's location can't be resolved (e.g. sourced via a symlink).
if [[ -n "${ZSH_VERSION:-}" ]]; then
  eval '_de_src="${(%):-%x}"'  # eval: the (%) flag is a bash bad-substitution
else
  _de_src="${BASH_SOURCE[0]:-}"
fi
DEV_ENV=""
if [[ -n "$_de_src" ]]; then DEV_ENV="$(CDPATH= cd "$(dirname "$_de_src")/.." 2>/dev/null && pwd)" || DEV_ENV=""; fi
[[ -f "$DEV_ENV/shell/functions.zsh" ]] || DEV_ENV="$HOME/.dev-env"
export DEV_ENV
unset _de_src

# ── ctx: switch context from anywhere ─────────
# Drop your own contexts/<name>.sh scripts in — this repo ships the mechanism,
# not any specific contexts. See contexts/CLAUDE.md for the expected shape.
ctx() {
  local name="${1:-}"
  if [[ -z "$name" ]]; then
    echo "Usage: ctx <context>"
    local available  # `command ls`: a user alias (e.g. Omarchy's eza) would otherwise garble this list
    available=$(command ls "$DEV_ENV/contexts/"*.sh 2>/dev/null | xargs -n1 basename 2>/dev/null | sed 's/\.sh$//' | tr '\n' ' ')
    echo "Available: ${available:-none found — add scripts under $DEV_ENV/contexts/}"
    return 1
  fi

  local script="$DEV_ENV/contexts/${name}.sh"
  if [[ ! -f "$script" ]]; then
    echo "No context script found for '$name' (looked in $script)"
    return 1
  fi

  chmod +x "$script"
  bash "$script"  # subprocess so the terminal stays alive when the context script returns
}

# zsh tab completion for ctx — discovers whatever's in contexts/
if [[ -n "${ZSH_VERSION:-}" ]]; then
  _ctx_complete() {
    local -a contexts
    eval 'contexts=("$DEV_ENV"/contexts/*.sh(:t:r N))'  # eval: glob qualifier is a bash parse error
    _describe 'context' contexts
  }
  compdef _ctx_complete ctx
fi

# ── supacode helpers ──────────────────────────
# Optional — only useful if you use supacode (https://supacode.dev). Safe to
# ignore/delete if you don't.

# URL-encode a path as a supacode worktree ID (trailing slash required)
# Usage: _sc_wt "/path/to/repo"
_sc_wt() {
  python3 -c "
import urllib.parse, sys
p = sys.argv[1].rstrip('/') + '/'
print(urllib.parse.quote(p, safe=''))
" "$1"
}

# Open a repo in supacode with tabs on first open (idempotent: skips tab creation if >1 tab exists)
# Usage: sc_open /path/to/repo "cmd1" "cmd2" ...
sc_open() {
  local path="${1:-}"
  if [[ -z "$path" ]]; then
    echo "Usage: sc_open <path> [tab-cmd ...]"
    return 1
  fi
  shift

  supacode repo open "$path"
  local wid
  wid="$(_sc_wt "$path")"

  if [[ $# -gt 0 ]]; then
    # Only create tabs if this is a fresh open (0 or 1 tab = just the default)
    local tab_count
    tab_count=$(supacode tab list --worktree "$wid" 2>/dev/null | grep -c . || true)
    if [[ "$tab_count" -le 1 ]]; then
      for cmd in "$@"; do
        supacode tab new --worktree "$wid" --input "$cmd"
      done
    fi
  fi

  supacode worktree focus --worktree "$wid"
}

# ── tmux helpers ───────────────────────────────

# List all active tmux sessions
tls() {
  tmux list-sessions 2>/dev/null || echo "No tmux sessions running"
}

# Attach to a named session
ta() {
  local session="${1:-}"
  if [[ -z "$session" ]]; then
    tmux list-sessions
    return 0
  fi
  tmux attach-session -t "$session"
}

# Kill a named session
tk() {
  local session="${1:-}"
  if [[ -z "$session" ]]; then
    tmux list-sessions
    echo "\nUsage: tk <session-name>"
    return 1
  fi
  tmux kill-session -t "$session" && echo "Killed session: $session"
}

# ── Python venv helpers ───────────────────────

# Create a venv in current dir using uv and install base requirements
mkvenv() {
  uv venv .venv
  source .venv/bin/activate
  if [[ -f "$DEV_ENV/python/base-requirements.txt" ]]; then
    uv pip install -r "$DEV_ENV/python/base-requirements.txt"
    echo "✓ Base requirements installed"
  fi
  echo "✓ venv created and activated at $(pwd)/.venv"
}

# Activate venv by walking up the directory tree
va() {
  local dir="$PWD"
  while [[ "$dir" != "/" ]]; do
    if [[ -f "$dir/.venv/bin/activate" ]]; then
      source "$dir/.venv/bin/activate"
      echo "✓ Activated: $dir/.venv"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  echo "No .venv found in $PWD or any parent directory"
  return 1
}

# ── LLM shortcuts ─────────────────────────────

# Central LLM wrapper
llm-run() {
  "$DEV_ENV/llm/run.sh" "$@"
}

# Pipe-friendly shorthand: echo "..." | ai "summarise this"
ai() {
  "$DEV_ENV/llm/run.sh" "$@"
}

# ── Obsidian vault shortcuts ──────────────────

vsearch() {
  "$DEV_ENV/obsidian-vault-utils/search.sh" "$@"
}

capture() {
  "$DEV_ENV/obsidian-vault-utils/capture.sh" "$@"
}

# ── Git shortcuts ─────────────────────────────

standup() {
  "$DEV_ENV/git/standup.sh" "$@"
}

# ── Service shortcuts ─────────────────────────

killport() {
  "$DEV_ENV/services/killport.sh" "$@"
}

# ── Data shortcuts ────────────────────────────

inspect() {
  "$DEV_ENV/data/inspect.sh" "$@"
}
