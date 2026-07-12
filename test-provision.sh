#!/usr/bin/env bash
set -euo pipefail

image=${IMAGE:-vastai/base-image:cuda-13.3.0-auto}
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

docker run --rm -i \
    --entrypoint /bin/bash \
    --volume "$script_dir/provision.sh:/provision.sh:ro" \
    --volume "$script_dir/tmux.conf:/tmux.conf:ro" \
    "$image" -s <<'CONTAINER'
/provision.sh
/provision.sh

[[ $(getent passwd root | cut -d: -f7) == /bin/zsh ]]
[[ $(getent passwd user | cut -d: -f7) == /bin/zsh ]]
[[ -x /usr/local/bin/nvim ]]
[[ -x /usr/local/bin/fd ]]
[[ -d /root/.config/nvim/.git ]]
[[ -d /home/user/.config/nvim/.git ]]
[[ ! -e /root/.config/nvim/lua/custom/plugins/luarock.lua ]]
[[ -d /root/.oh-my-zsh/custom/plugins/zsh-autosuggestions ]]
[[ -d /root/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting ]]
[[ -z $(find /root/.oh-my-zsh -perm /022 -print -quit) ]]
[[ -f /root/.tmux.conf ]]
[[ -d /root/.tmux/plugins/tpm/.git ]]
[[ -d /root/.tmux/plugins/tmux-resurrect/.git ]]
command -v gh >/dev/null
nvim --headless --clean '+lua assert(vim.fn.has("nvim-0.12") == 1)' +qa

HOME=/root tmux -L provision-test -f /root/.tmux.conf new-session -d
[[ $(HOME=/root tmux -L provision-test show-option -gv prefix) == C-f ]]
HOME=/root tmux -L provision-test kill-server

HOME=/root WORKSPACE=/workspace zsh -c '
    source ~/.zshrc
    [[ $PWD == /workspace ]]
    [[ -z ${CONDA_PREFIX:-} ]]
    command -v uv >/dev/null
    command -v npm >/dev/null
    command -v prettier >/dev/null
    command -v opencode >/dev/null
    command -v tree-sitter >/dev/null
    command -v codex >/dev/null
'

echo "provision smoke test passed"
CONTAINER
