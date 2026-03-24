#!/usr/bin/env zsh

if [[ -n ${ZSH_VERSION-} ]]; then
  alias_root="${${(%):-%N}:A:h}"
else
  alias_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" && pwd)"
fi

for alias_dir in \
  "$alias_root/aliases" \
  "$alias_root/.local/aliases"
do
  [[ -d "$alias_dir" ]] || continue
  while IFS= read -r alias_file; do
    source "$alias_file"
  done < <(find "$alias_dir" -maxdepth 1 -type f -name '*.sh' | sort)
done

unset alias_root alias_dir alias_file
