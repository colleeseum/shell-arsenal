#!/usr/bin/env zsh

prepend_path_if_dir() {
  local dir
  dir="$1"

  [[ -d "$dir" ]] || return

  case ":$PATH:" in
    *":$dir:"*) ;;
    *) PATH="$dir${PATH:+:$PATH}" ;;
  esac
}

# Portable user-level PATH entries that should follow this repo across machines.
prepend_path_if_dir "$HOME/.krew/bin"
prepend_path_if_dir "$HOME/.local/bin"
prepend_path_if_dir "$HOME/bin"
prepend_path_if_dir "$HOME/shell-arsenal/bin"

unset -f prepend_path_if_dir
