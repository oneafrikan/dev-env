#!/usr/bin/env bash
# ─────────────────────────────────────────────
# llm/config.sh — LLM model configuration
# Edit here to change defaults across all scripts
# Source this file; do not execute it directly
# ─────────────────────────────────────────────

# Primary model — used by default across all scripts
export LLM_DEFAULT_MODEL="claude-sonnet-4-6"

# Fallback models per provider
export LLM_ANTHROPIC_MODEL="claude-sonnet-4-6"
export LLM_OPENAI_MODEL="gpt-4.1-mini"
export LLM_GEMINI_MODEL="gemini-2.0-flash"
export LLM_OLLAMA_MODEL="llama3.2"          # must match what's pulled in Ollama

# Local model config
export OLLAMA_HOST="http://localhost:11434"
export OLLAMA_DEFAULT_MODEL="llama3.2"

# Token/cost guard — warn if prompt exceeds this token count
export LLM_TOKEN_WARN_THRESHOLD=50000
