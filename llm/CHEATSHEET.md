# llm cheatsheet

## Basic usage

```bash
llm "your prompt"                          # one-shot prompt
echo "some text" | llm "summarise this"   # pipe content in
ls -la | llm "tell me about this folder"  # pipe command output
cat file.py | llm "review this code"      # pipe a file
```

## Model selection

```bash
llm -m claude-sonnet-4.6 "prompt"         # explicit model
llm -m claude-haiku-4.5 "prompt"          # faster/cheaper
llm -m claude-opus-4.7 "prompt"           # most capable
llm models list                            # all available models
llm models default claude-sonnet-4.6      # change default
```

## Keys & plugins

```bash
llm keys list                              # show stored keys
llm keys set anthropic                     # set Anthropic key
llm plugins list                           # installed plugins
llm install llm-anthropic                  # install plugin
```

## Conversations

```bash
llm -c "follow-up question"               # continue last conversation
llm logs                                   # show conversation history
llm logs --json | head -20                # raw log output
```

## System prompts

```bash
llm -s "you are a bash expert" "explain this"
llm --system "$(cat prompt.txt)" "question"
```

## Useful pipes

```bash
# Explain an error
<error output> | llm "explain this error and suggest a fix"

# Summarise git log
git log --oneline -20 | llm "summarise what changed"

# Review a diff
git diff | llm "review this diff for bugs or issues"

# Count tokens first (requires ttok)
cat file.py | ttok
```

## run.sh wrapper (use in scripts)

```bash
# Never call llm directly in scripts — use run.sh
source ~/.dev-env/llm/run.sh

llm/run.sh "prompt"                        # uses config default
llm/run.sh -m claude-haiku-4.5 "prompt"   # override model
llm/run.sh -t commit-message "prompt"     # use a template
llm/run.sh --local "prompt"               # force Ollama
llm/run.sh --raw models list              # passthrough to llm
```

## Templates (system prompts in llm/templates/)

```bash
llm/run.sh -t commit-message "$(git diff --staged)"
llm/run.sh -t error-explain "$(cat error.log)"
llm/run.sh -t standup "$(git log --oneline --since=yesterday)"
llm/run.sh -t code-review "$(cat file.py)"
llm/run.sh -t data-summary "$(head -50 data.csv)"
llm/run.sh -t security-audit "$(cat script.sh)"
```

## Config

Edit `llm/config.sh` to change defaults globally:
- `LLM_DEFAULT_MODEL` — model used when no `-m` flag
- `LLM_TOKEN_WARN_THRESHOLD` — warn if prompt exceeds this token count
