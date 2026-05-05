alias kgc='kubectl get certificates'
alias kdelc='kubectl delete certificate'
alias kdc='kubectl describe certificates'
alias kgcr='kubectl get certificaterequest'
alias kdcr='kubectl describe certificaterequest'
alias kgo='kubectl get order'
alias kdo='kubectl describe order'
alias kge='kubectl get events --watch'

jcat() {
  local filter="."
  local bullet="auto"
  local query_used=false
  local errors=false
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
      --error|--errors)
        filter='select(.level == "ERROR") | "\(.timestamp // .time // .ts // .["@timestamp"] // "")   \(.message // "")"'
        query_used=true
        errors=true
        shift
        ;;
      -q|--query)
        filter="${2:?missing jq filter for $1}"
        query_used=true
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
    if [[ "$query_used" == true && "$errors" == false ]]; then
      bullet=true
    else
      bullet=false
    fi
  fi

  if [[ "$bullet" == true && "$query_used" == true ]]; then
    jq -Rr "fromjson? | $filter" "${inputs[@]}" | sed 's/^/- /'
  else
    jq -Rr "fromjson? | $filter" "${inputs[@]}"
  fi
}

_shell_arsenal_log_json() {
  local follow="$1"
  shift
  local filter="."
  local bullet="auto"
  local query_used=false
  local errors=false
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
      --error|--errors)
        filter='select(.level == "ERROR") | "\(.timestamp // .time // .ts // .["@timestamp"] // "")   \(.message // "")"'
        query_used=true
        errors=true
        shift
        ;;
      -q|--query)
        filter="${2:?missing jq filter for $1}"
        query_used=true
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
    if [[ "$query_used" == true && "$errors" == false ]]; then
      bullet=true
    else
      bullet=false
    fi
  fi

  if [[ "$follow" == true ]]; then
    log_args=(-f "${log_args[@]}")
  fi

  if [[ "$bullet" == true && "$query_used" == true ]]; then
    kl "${log_args[@]}" | jq -Rr "fromjson? | $filter" | sed 's/^/- /'
  else
    kl "${log_args[@]}" | jq -Rr "fromjson? | $filter"
  fi
}

kljq() {
  _shell_arsenal_log_json false "$@"
}

klfjq() {
  _shell_arsenal_log_json true "$@"
}

if [[ -n ${ZSH_VERSION-} ]] && (( $+functions[compdef] )); then
  _shell_arsenal_kubectl_pods() {
    local -a pods
    pods=("${(@f)$(kubectl get pods --no-headers -o custom-columns=NAME:.metadata.name 2>/dev/null)}")
    _describe -t pods 'pods' pods
  }

  compdef _shell_arsenal_kubectl_pods kljq klfjq
fi
