# shell-arsenal

Small personal shell utilities.

Make sure `~/shell-arsenal/bin` is on your `PATH`.
If you want the managed aliases too, source `~/shell-arsenal/aliases.sh` from your shell config.
If you want the portable PATH entries too, source `~/shell-arsenal/paths.sh` from your shell config and keep machine-specific PATH additions in `~/.zshrc`.

## Getting Started

Use the same loader snippet in either `~/.zshrc` or `~/.bashrc`:

```sh
if [[ -r "$HOME/shell-arsenal/paths.sh" ]]; then
  source "$HOME/shell-arsenal/paths.sh"
fi

if [[ -r "$HOME/shell-arsenal/aliases.sh" ]]; then
  source "$HOME/shell-arsenal/aliases.sh"
fi
```

Put it in `~/.zshrc` for zsh or `~/.bashrc` for bash. These files are meant to be sourced from your shell config, not executed directly.

For `tmux`, keep a tiny `~/.tmux.conf` bootstrap that sources the repo-managed config:

```tmux
if-shell '[ -r "$HOME/shell-arsenal/tmux.conf" ]' \
  'source-file "$HOME/shell-arsenal/tmux.conf"' \
  'display-message "shell-arsenal/tmux.conf not found"'
```

That avoids a symlink while keeping the actual tmux configuration in this repo.

## Aliases

Aliases are split by category under `aliases/` and loaded through `aliases.sh`.
`aliases.sh` sources every `*.sh` file in `aliases/`, then every `*.sh` file in `.local/aliases/`, both in sorted order.
Private machine- or environment-specific aliases can live under `.local/aliases/`; that directory is intentionally gitignored but still sourced by `aliases.sh`.

## PATH

`paths.sh` prepends these portable user-level directories when they exist:

- `~/shell-arsenal/bin`
- `~/bin`
- `~/.local/bin`
- `~/.krew/bin`

Keep versioned Homebrew, app bundle, SDK, and other machine-specific PATH entries in your local shell config.

| File | Purpose |
| --- | --- |
| `aliases/common.sh` | Generic shell aliases that are safe to keep broadly enabled. |
| `aliases/kubectl.sh` | Kubernetes and cert-manager shortcuts. |
| `aliases/firebase.sh` | Firebase emulator shortcuts. |

## Utilities

| Utility | Description |
| --- | --- |
| `akgno` | Show `kubectl get nodes -o wide` with an extra EKS nodegroup `POOL` column. |
| `az-sub` | Interactively pick an Azure subscription with `fzf` and set it as the active Azure CLI subscription. |
| `bru_body` | Run a Bruno collection and print the first response body from the JSON report. |
| `kalloc` | Show per-node Kubernetes allocatable and effective free CPU and memory after subtracting `kube-system` requests. |
| `klogmsg` | Read `kubectl logs` output and extract JSON `message` fields into a single-line view; use `-f` to follow. |
