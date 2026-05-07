_shell_arsenal_log_json_usage() {
  case "$1" in
    jcat)
      cat <<'EOF'
Usage: jcat [FILE...] [OPTIONS]

Parse newline-delimited JSON from files or stdin.

Options:
  -q, --query FILTER   Apply a jq filter. Output is bulleted by default.
      --error          Print ERROR log timestamps and messages.
      --errors         Alias for --error.
      --no-stack       Do not include stack_info in --error output.
      --message        Print all log timestamps and messages.
      --messages       Alias for --message.
      --yaml           Render parsed JSON as YAML with multiline strings.
      --fields LIST    Show only comma-separated fields. Missing fields are omitted.
  -b, --bullet         Prefix query output lines with "- ".
      --no-bullet      Do not prefix query output lines.
      --nobullet       Alias for --no-bullet.
  -h, --help           Show this usage.
EOF
      ;;
    kljq)
      cat <<'EOF'
Usage: kljq KUBECTL_LOGS_ARGS... [OPTIONS]

Run kl, parse each log line as JSON, and optionally filter the output.

Options:
  -q, --query FILTER   Apply a jq filter. Output is bulleted by default.
      --error          Print ERROR log timestamps and messages.
      --errors         Alias for --error.
      --no-stack       Do not include stack_info in --error output.
      --message        Print all log timestamps and messages.
      --messages       Alias for --message.
      --yaml           Render parsed JSON as YAML with multiline strings.
      --fields LIST    Show only comma-separated fields. Missing fields are omitted.
  -b, --bullet         Prefix query output lines with "- ".
      --no-bullet      Do not prefix query output lines.
      --nobullet       Alias for --no-bullet.
  -h, --help           Show this usage.
EOF
      ;;
    klfjq)
      cat <<'EOF'
Usage: klfjq KUBECTL_LOGS_ARGS... [OPTIONS]

Run kl -f, parse each followed log line as JSON, and optionally filter the output.

Options:
  -q, --query FILTER   Apply a jq filter. Output is bulleted by default.
      --error          Print ERROR log timestamps and messages.
      --errors         Alias for --error.
      --no-stack       Do not include stack_info in --error output.
      --message        Print all log timestamps and messages.
      --messages       Alias for --message.
      --yaml           Render parsed JSON as YAML with multiline strings.
      --fields LIST    Show only comma-separated fields. Missing fields are omitted.
  -b, --bullet         Prefix query output lines with "- ".
      --no-bullet      Do not prefix query output lines.
      --nobullet       Alias for --no-bullet.
  -h, --help           Show this usage.
EOF
      ;;
  esac
}

_shell_arsenal_json_field_filter() {
  local fields="$1"
  local filter="["
  local first=true
  local field
  local clean_field

  while IFS= read -r field || [[ -n "$field" ]]; do
    clean_field="$(printf '%s' "$field" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
    [[ -n "$clean_field" ]] || continue
    case "$clean_field" in
      *[!A-Za-z0-9_@.-]*)
        printf 'Invalid field name for --fields: %s\n' "$clean_field" >&2
        return 2
        ;;
    esac
    if [[ "$first" == true ]]; then
      first=false
    else
      filter+=", "
    fi
    filter+="if has(\"$clean_field\") then {\"$clean_field\": .[\"$clean_field\"]} else {} end"
  done < <(printf '%s' "$fields" | tr ',' '\n')

  if [[ "$first" == true ]]; then
    printf 'Missing field list for --fields\n' >&2
    return 2
  fi

  filter+="] | add"
  printf '%s\n' "$filter"
}

_shell_arsenal_error_filter() {
  if [[ "$1" == true ]]; then
    printf '%s\n' 'select(.level == "ERROR") | select(.message? != null) | "\(.timestamp // .time // .ts // .["@timestamp"] // "")   \(.message)\(if .stack_info? != null then "\n\(.stack_info)" else "" end)"'
  else
    printf '%s\n' 'select(.level == "ERROR") | select(.message? != null) | "\(.timestamp // .time // .ts // .["@timestamp"] // "")   \(.message)"'
  fi
}

_shell_arsenal_render_json_lines() {
  local filter="$1"
  local query_used="$2"
  local bullet="$3"
  local yaml="$4"
  shift 4

  if [[ "$yaml" == true ]]; then
    if command -v yq >/dev/null 2>&1 && [[ "$(yq --version 2>/dev/null)" == *"github.com/mikefarah/yq/"* ]]; then
      jq -Rr "fromjson? | $filter | tojson" "$@" \
        | awk 'BEGIN { first = 1 } { if (!first) print "---"; first = 0; print }' \
        | yq -P -o=yaml '.'
      return
    fi

    jq -Rr '
      def indent($n): " " * $n;
      def render($n):
        if type == "object" then
          to_entries[]
          | if (.value | type) == "object" or (.value | type) == "array" then
              "\(indent($n))\(.key):",
              (.value | render($n + 2))
            elif (.value | type) == "string" and (.value | contains("\n")) then
              "\(indent($n))\(.key): |",
              (.value | split("\n")[] | "\(indent($n + 2))\(.)")
            elif (.value | type) == "string" then
              "\(indent($n))\(.key): \(.value)"
            else
              "\(indent($n))\(.key): \(.value | tojson)"
            end
        elif type == "array" then
          .[]
          | if type == "object" or type == "array" then
              "\(indent($n))-",
              (. | render($n + 2))
            elif type == "string" and contains("\n") then
              "\(indent($n))- |",
              (split("\n")[] | "\(indent($n + 2))\(.)")
            elif type == "string" then
              "\(indent($n))- \(.)"
            else
              "\(indent($n))- \(tojson)"
            end
        elif type == "string" then
          .
        else
          tojson
        end;
      fromjson? | '"$filter"' | render(0)
    ' "$@"
    return
  fi

  if [[ "$query_used" != true ]]; then
    jq -Rr 'fromjson?' "$@"
    return
  fi

  if [[ "$bullet" == true ]]; then
    jq -Rr "fromjson? | $filter | if type == \"string\" then \"- \" + gsub(\"\n\"; \"\n  \") else \"- \" + tojson end" "$@"
  else
    jq -Rr "fromjson? | $filter | if type == \"string\" then gsub(\"\n\"; \"\n  \") else . end" "$@"
  fi
}

jcat() {
  if [[ "${1-}" == "-h" || "${1-}" == "--help" ]]; then
    _shell_arsenal_log_json_usage jcat
    return 0
  fi

  local filter="."
  local bullet="auto"
  local query_used=false
  local formatted=false
  local yaml=false
  local include_stack=true
  local error_mode=false
  local fields_filter
  local -a inputs=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -b|--bullet)
        bullet=true
        shift
        ;;
      --no-bullet|--nobullet)
        bullet=false
        shift
        ;;
      --no-stack)
        include_stack=false
        if [[ "$error_mode" == true ]]; then
          filter="$(_shell_arsenal_error_filter "$include_stack")"
        fi
        shift
        ;;
      --error|--errors)
        filter="$(_shell_arsenal_error_filter "$include_stack")"
        query_used=true
        formatted=true
        error_mode=true
        shift
        ;;
      --message|--messages)
        filter='select(.message? != null) | "\(.timestamp // .time // .ts // .["@timestamp"] // "")   \(.message)"'
        query_used=true
        formatted=true
        error_mode=false
        shift
        ;;
      --yaml)
        yaml=true
        shift
        ;;
      --fields)
        fields_filter="$(_shell_arsenal_json_field_filter "${2:?missing field list for --fields}")" || return
        filter="$fields_filter"
        query_used=true
        formatted=true
        error_mode=false
        shift 2
        ;;
      -q|--query)
        filter="${2:?missing jq filter for $1}"
        query_used=true
        error_mode=false
        shift 2
        ;;
      --)
        shift
        inputs+=("$@")
        break
        ;;
      *)
        inputs+=("$1")
        shift
        ;;
    esac
  done

  if [[ "$bullet" == "auto" ]]; then
    if [[ "$query_used" == true && "$formatted" == false ]]; then
      bullet=true
    else
      bullet=false
    fi
  fi

  _shell_arsenal_render_json_lines "$filter" "$query_used" "$bullet" "$yaml" "${inputs[@]}"
}

_shell_arsenal_log_json() {
  local follow="$1"
  local command="$2"
  shift 2

  if [[ "${1-}" == "-h" || "${1-}" == "--help" ]]; then
    _shell_arsenal_log_json_usage "$command"
    return 0
  fi

  local filter="."
  local bullet="auto"
  local query_used=false
  local formatted=false
  local yaml=false
  local include_stack=true
  local error_mode=false
  local fields_filter
  local -a log_args=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -b|--bullet)
        bullet=true
        shift
        ;;
      --no-bullet|--nobullet)
        bullet=false
        shift
        ;;
      --no-stack)
        include_stack=false
        if [[ "$error_mode" == true ]]; then
          filter="$(_shell_arsenal_error_filter "$include_stack")"
        fi
        shift
        ;;
      --error|--errors)
        filter="$(_shell_arsenal_error_filter "$include_stack")"
        query_used=true
        formatted=true
        error_mode=true
        shift
        ;;
      --message|--messages)
        filter='select(.message? != null) | "\(.timestamp // .time // .ts // .["@timestamp"] // "")   \(.message)"'
        query_used=true
        formatted=true
        error_mode=false
        shift
        ;;
      --yaml)
        yaml=true
        shift
        ;;
      --fields)
        fields_filter="$(_shell_arsenal_json_field_filter "${2:?missing field list for --fields}")" || return
        filter="$fields_filter"
        query_used=true
        formatted=true
        error_mode=false
        shift 2
        ;;
      -q|--query)
        filter="${2:?missing jq filter for $1}"
        query_used=true
        error_mode=false
        shift 2
        ;;
      --)
        shift
        log_args+=("$@")
        break
        ;;
      *)
        log_args+=("$1")
        shift
        ;;
    esac
  done

  if [[ "$bullet" == "auto" ]]; then
    if [[ "$query_used" == true && "$formatted" == false ]]; then
      bullet=true
    else
      bullet=false
    fi
  fi

  if [[ "$follow" == true ]]; then
    log_args=(-f "${log_args[@]}")
  fi

  kl "${log_args[@]}" | _shell_arsenal_render_json_lines "$filter" "$query_used" "$bullet" "$yaml"
}

kljq() {
  _shell_arsenal_log_json false kljq "$@"
}

klfjq() {
  _shell_arsenal_log_json true klfjq "$@"
}
