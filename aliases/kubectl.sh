alias kgc='kubectl get certificates'
alias kdelc='kubectl delete certificate'
alias kdc='kubectl describe certificates'
alias kgcr='kubectl get certificaterequest'
alias kdcr='kubectl describe certificaterequest'
alias kgo='kubectl get order'
alias kdo='kubectl describe order'
alias kge='kubectl get events --watch'

if [[ -n ${ZSH_VERSION-} ]] && (( $+functions[compdef] )); then
  _shell_arsenal_kubectl_pods() {
    local -a pods
    pods=("${(@f)$(kubectl get pods --no-headers -o custom-columns=NAME:.metadata.name 2>/dev/null)}")
    _describe -t pods 'pods' pods
  }

  compdef _shell_arsenal_kubectl_pods kljq klfjq
fi
