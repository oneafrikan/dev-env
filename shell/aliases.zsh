# ─────────────────────────────────────────────
# shell/aliases.zsh
# Source from .zshrc:
#   source "$HOME/.dev-env/shell/aliases.zsh"
# ─────────────────────────────────────────────

# ── Navigation ────────────────────────────────
alias ..='cd ..'
alias ~='cd ~'

# ── Modern CLI replacements ───────────────────
alias ls='eza --icons --group-directories-first'
alias ll='eza -la --icons --group-directories-first'
alias lt='eza --tree --level=2 --icons'
alias cat='bat --style=plain'
alias grep='rg'
alias find='fd'
alias top='btop'

# ── Git ───────────────────────────────────────
alias gs='git status -sb'
alias gl='git log --oneline --graph --decorate -20'
alias gd='git diff'
alias gp='git push'
alias gpl='git pull'
alias gwip='git add -A && git commit -m "wip: $(date +%Y-%m-%d\ %H:%M)"'

# ── Python ────────────────────────────────────
alias py='python3'
alias pip='uv pip'
alias activate='source .venv/bin/activate'

# ── tmux ─────────────────────────────────────
alias tls='tmux list-sessions'
alias tat='tmux attach-session -t'
alias tkill='tmux kill-session -t'

# ── Just ──────────────────────────────────────
alias j='just'
alias jl='just --list'

# ── fzf ──────────────────────────────────────
alias fz='fzf --preview "bat --style=numbers --color=always {}"'

# ── Context roots (quick cd) ──────────────────
# Add one alias per project you use `ctx` with — example:
# alias myproject='cd ~/my-project'
alias devenv='cd ~/.dev-env'
