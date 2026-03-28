#!/usr/bin/env bash

input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // ""')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
tokens=$(echo "$input" | jq -r '
  if .context_window.current_usage != null then
    (
      (.context_window.current_usage.input_tokens // 0) +
      (.context_window.current_usage.output_tokens // 0) +
      (.context_window.current_usage.cache_read_input_tokens // 0) +
      (.context_window.current_usage.cache_creation_input_tokens // 0)
    ) | tostring
  else "" end
')
window=$(echo "$input" | jq -r '.context_window.context_window_size // empty')
dir=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
project=$(basename "$dir")

# Git branch (skip optional locks)
branch=$(GIT_OPTIONAL_LOCKS=0 git -C "$dir" symbolic-ref --short HEAD 2>/dev/null)

# Build progress bar (10 chars wide)
bar=""
if [ -n "$used" ]; then
    filled=$(printf '%.0f' "$(echo "$used / 10" | bc -l)")
    empty=$((10 - filled))
    for i in $(seq 1 "$filled"); do bar="${bar}▓"; done
    for i in $(seq 1 "$empty");  do bar="${bar}░"; done
fi

# Model
printf "\033[0;33m%s\033[0m" "$model"

# Progress bar + percentage
if [ -n "$used" ]; then
    pct=$(printf '%.0f' "$used")
    printf " \033[0;36m%s\033[0m \033[0;36m%s%%\033[0m" "$bar" "$pct"
fi

# Token count
if [ -n "$tokens" ] && [ -n "$window" ]; then
    used_k=$(printf '%.0f' "$(echo "$tokens / 1000" | bc -l)")
    window_k=$(printf '%.0f' "$(echo "$window / 1000" | bc -l)")
    printf " \033[2m%sk/%sk\033[0m" "$used_k" "$window_k"
fi

# Git branch
if [ -n "$branch" ]; then
    printf " \033[0;35m%s\033[0m" "$branch"
fi

# Project name
if [ -n "$project" ]; then
    printf " \033[0;34m%s\033[0m" "$project"
fi

printf "\n"
