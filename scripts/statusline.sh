#!/bin/bash
# Statusline for Claude Code -- config-driven.
#
# Reads .claude/statusline.conf (KEY=true/false per option) and renders only
# the sections set to true. If the conf file is missing, falls back to a
# minimal default (project + branch + model). Each section keeps its original
# colour / emoji / formatting -- the conf only toggles which sections render.
#
# Available toggles (defaults shown for the no-conf fallback):
#   show_project=true
#   show_branch=true
#   show_vim=false
#   show_model=true
#   show_context=false
#   show_cost=false
#   show_duration=false
#   show_lines=false
#   show_output_tokens=false
#   show_cache=false
#   show_rate_limits=false

INPUT=$(cat)

# --- Load conf (or apply minimal defaults) -------------------------------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
CONF="$REPO_DIR/.claude/statusline.conf"

# Defaults (used when conf file is missing OR a toggle is absent)
show_project=true
show_branch=true
show_vim=false
show_model=true
show_context=false
show_cost=false
show_duration=false
show_lines=false
show_output_tokens=false
show_cache=false
show_rate_limits=false

if [ -f "$CONF" ]; then
  # shellcheck disable=SC1090
  . "$CONF"
fi

extract() {
  echo "$INPUT" | python3 -c "
import json, sys
d = json.load(sys.stdin)
keys = '$1'.split('.')
v = d
for k in keys:
    if isinstance(v, dict): v = v.get(k)
    else: v = None
print('' if v is None else v)
" 2>/dev/null
}

# --- Project & git ---
PROJECT_DIR=$(extract workspace.project_dir)
PROJECT_NAME=$(extract workspace.project_name)
NAME="${PROJECT_NAME:-$(basename "$PROJECT_DIR")}"
BRANCH=$(git -C "$PROJECT_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null)

# --- Model ---
MODEL=$(echo "$INPUT" | python3 -c "
import json, sys
d = json.load(sys.stdin)
m = d.get('model', 'unknown')
print(m.get('display_name', m.get('id', 'unknown')) if isinstance(m, dict) else m)
" 2>/dev/null)

# --- Context window ---
CTX_PCT=$(extract context_window.used_percentage)
CTX_SIZE=$(extract context_window.context_window_size)

# --- Cost & duration ---
COST=$(extract cost.total_cost_usd)
DURATION_MS=$(extract cost.total_duration_ms)
LINES_ADDED=$(extract cost.total_lines_added)
LINES_REMOVED=$(extract cost.total_lines_removed)

# --- Output tokens & cache ---
OUT_TOKENS=$(extract context_window.total_output_tokens)
CACHE_READ=$(extract context_window.current_usage.cache_read_input_tokens)

# --- Rate limits (Pro/Max only) ---
RATE_5H=$(extract rate_limits.five_hour.used_percentage)
RATE_7D=$(extract rate_limits.seven_day.used_percentage)
RATE_5H_RESETS=$(extract rate_limits.five_hour.resets_at)
RATE_7D_RESETS=$(extract rate_limits.seven_day.resets_at)

# --- Vim mode ---
VIM_MODE=$(extract vim.mode)

# --- Helpers ---
progress_bar() {
  local pct="${1:-0}"
  local pct_int=${pct%.*}
  local filled=$(( pct_int / 10 ))
  local empty=$(( 10 - filled ))
  # Color: green < 60, yellow < 80, red >= 80
  local color
  if   [ "$pct_int" -ge 80 ]; then color="\033[38;5;196m"
  elif [ "$pct_int" -ge 60 ]; then color="\033[38;5;226m"
  else color="\033[38;5;82m"
  fi
  local bar=""
  for ((i=0; i<filled; i++)); do bar+="█"; done
  for ((i=0; i<empty;  i++)); do bar+="░"; done
  printf "${color}%s %s%%\033[0m" "$bar" "$pct_int"
}

fmt_duration() {
  local ms="${1:-0}"
  local ms_int=${ms%.*}
  local s=$(( ms_int / 1000 ))
  if   [ "$s" -ge 3600 ]; then printf "%dh%02dm" $(( s/3600 )) $(( (s%3600)/60 ))
  elif [ "$s" -ge 60   ]; then printf "%dm%02ds" $(( s/60 )) $(( s%60 ))
  else printf "%ds" "$s"
  fi
}

fmt_tokens() {
  python3 -c "
v='$1'.strip()
try:
  n=int(float(v))
  print('%dk' % (n//1000) if n>=1000 else str(n))
except: print('')
" 2>/dev/null
}

fmt_countdown() {
  local ts="${1:-0}"
  python3 -c "
import time
resets=int('$ts')
now=int(time.time())
diff=resets-now
if diff<=0: print('now')
elif diff<3600: print('%dm' % (diff//60))
else: print('%dh%02dm' % (diff//3600, (diff%3600)//60))
" 2>/dev/null
}

fmt_cost() {
  echo "$1" | python3 -c "
import sys
v = sys.stdin.read().strip()
try: print('\$%.3f' % float(v))
except: print('')
" 2>/dev/null
}

# ── Build the line ──────────────────────────────────────────────

# Project
[ "$show_project" = "true" ] && [ -n "$NAME" ]   && printf "\033[38;5;214m⚡ %s\033[0m " "$NAME"

# Git branch
[ "$show_branch" = "true" ] && [ -n "$BRANCH" ] && printf "\033[38;5;117m🌿 %s\033[0m " "$BRANCH"

# Vim mode
[ "$show_vim" = "true" ] && [ -n "$VIM_MODE" ] && printf "\033[38;5;229m✎ %s\033[0m " "$VIM_MODE"

# Model
[ "$show_model" = "true" ] && printf "\033[38;5;141m🤖 %s\033[0m" "${MODEL:-unknown}"

# Context window bar
if [ "$show_context" = "true" ] && [ -n "$CTX_PCT" ] && [ "$CTX_PCT" != "0" ]; then
  printf "  🧠 "
  progress_bar "$CTX_PCT"
  if [ -n "$CTX_SIZE" ]; then
    CTX_USED_CALC=$(python3 -c "pct=${CTX_PCT}; sz=${CTX_SIZE}; used=round(pct*sz/100); print('%dk' % (used//1000) if used>=1000 else str(used))" 2>/dev/null)
    CTX_SIZE_FMT=$(python3 -c "sz=${CTX_SIZE}; print('%dk' % (sz//1000) if sz>=1000 else str(sz))" 2>/dev/null)
    [ -n "$CTX_USED_CALC" ] && printf " \033[38;5;245m(%s/%s tok)\033[0m" "$CTX_USED_CALC" "$CTX_SIZE_FMT"
  fi
fi

# Cost
if [ "$show_cost" = "true" ]; then
  COST_FMT=$(fmt_cost "$COST")
  [ -n "$COST_FMT" ] && printf "  \033[38;5;208m💰 %s\033[0m" "$COST_FMT"
fi

# Duration
if [ "$show_duration" = "true" ] && [ -n "$DURATION_MS" ] && [ "$DURATION_MS" != "0" ]; then
  DUR=$(fmt_duration "$DURATION_MS")
  printf "  \033[38;5;244m⏱ %s\033[0m" "$DUR"
fi

# Lines changed
if [ "$show_lines" = "true" ] && { [ -n "$LINES_ADDED" ] || [ -n "$LINES_REMOVED" ]; }; then
  [ "${LINES_ADDED:-0}" != "0" ]   && printf "  \033[38;5;82m+%s\033[0m" "$LINES_ADDED"
  [ "${LINES_REMOVED:-0}" != "0" ] && printf " \033[38;5;196m-%s\033[0m" "$LINES_REMOVED"
fi

# Output tokens
if [ "$show_output_tokens" = "true" ]; then
  OUT_FMT=$(fmt_tokens "$OUT_TOKENS")
  [ -n "$OUT_FMT" ] && [ "$OUT_FMT" != "0" ] && printf "  \033[38;5;75m✍ %s\033[0m" "$OUT_FMT"
fi

# Cache hits
if [ "$show_cache" = "true" ]; then
  CACHE_FMT=$(fmt_tokens "$CACHE_READ")
  [ -n "$CACHE_FMT" ] && [ "$CACHE_FMT" != "0" ] && printf "  \033[38;5;43m⚡cache %s\033[0m" "$CACHE_FMT"
fi

# Rate limits (only shown if present)
if [ "$show_rate_limits" = "true" ]; then
  if [ -n "$RATE_5H" ]; then
    COUNTDOWN_5H=$(fmt_countdown "$RATE_5H_RESETS")
    printf "  \033[38;5;245m5h: "
    progress_bar "$RATE_5H"
    [ -n "$COUNTDOWN_5H" ] && printf " \033[38;5;245m↺%s\033[0m" "$COUNTDOWN_5H"
    printf "\033[0m"
  fi
  if [ -n "$RATE_7D" ]; then
    COUNTDOWN_7D=$(fmt_countdown "$RATE_7D_RESETS")
    printf "  \033[38;5;245m7d: "
    progress_bar "$RATE_7D"
    [ -n "$COUNTDOWN_7D" ] && printf " \033[38;5;245m↺%s\033[0m" "$COUNTDOWN_7D"
    printf "\033[0m"
  fi
fi

printf "\n"
