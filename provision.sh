#!/usr/bin/env bash
set -euo pipefail
umask 022

export DEBIAN_FRONTEND=noninteractive

if ! command -v zsh >/dev/null || ! command -v tmux >/dev/null || ! command -v rg >/dev/null || ! command -v fdfind >/dev/null; then
    apt-get update
    apt-get install -y --no-install-recommends zsh tmux ripgrep fd-find
    rm -rf /var/lib/apt/lists/*
fi
ln -sfn /usr/bin/fdfind /usr/local/bin/fd

case $(uname -m) in
    x86_64) nvim_arch=x86_64 ;;
    aarch64 | arm64) nvim_arch=arm64 ;;
    *) echo "Unsupported Neovim architecture: $(uname -m)" >&2; exit 1 ;;
esac

nvim_dir="/opt/nvim-linux-$nvim_arch"
if [[ ! -x "$nvim_dir/bin/nvim" ]]; then
    curl -fsSL "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-$nvim_arch.tar.gz" -o /tmp/nvim.tar.gz
    tar -xzf /tmp/nvim.tar.gz -C /opt
    rm /tmp/nvim.tar.gz
fi
ln -sfn "$nvim_dir/bin/nvim" /usr/local/bin/nvim

source /opt/nvm/nvm.sh
npm_packages=()
command -v prettier >/dev/null || npm_packages+=(prettier)
command -v opencode >/dev/null || npm_packages+=(opencode-ai@latest)
command -v tree-sitter >/dev/null || npm_packages+=(tree-sitter-cli)
((${#npm_packages[@]} == 0)) || npm install -g "${npm_packages[@]}"

if [[ ${PROVISIONING_SCRIPT:-} == http://* || ${PROVISIONING_SCRIPT:-} == https://* ]]; then
    curl -fsSL "${PROVISIONING_SCRIPT%/*}/tmux.conf" -o /tmp/vast-tmux.conf
else
    script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
    cp "$script_dir/tmux.conf" /tmp/vast-tmux.conf
fi

cat > /tmp/vast-zshrc <<'EOF'
set -a
[[ -r /etc/environment ]] && source /etc/environment
[[ -r "${WORKSPACE:-/workspace}/.env" ]] && source "${WORKSPACE:-/workspace}/.env"
set +a

[[ -r /opt/nvm/nvm.sh ]] && source /opt/nvm/nvm.sh

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
source "$ZSH/oh-my-zsh.sh"

cd "${WORKSPACE:-/workspace}" 2>/dev/null || true
EOF

for account in root user; do
    id "$account" >/dev/null 2>&1 || continue
    usermod --shell /bin/zsh "$account"
    home=$(getent passwd "$account" | cut -d: -f6)
    group=$(id -gn "$account")

    omz_dir="$home/.oh-my-zsh"
    [[ -e "$omz_dir" ]] || git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$omz_dir"
    [[ -e "$omz_dir/custom/plugins/zsh-autosuggestions" ]] || \
        git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git "$omz_dir/custom/plugins/zsh-autosuggestions"
    [[ -e "$omz_dir/custom/plugins/zsh-syntax-highlighting" ]] || \
        git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "$omz_dir/custom/plugins/zsh-syntax-highlighting"
    chown -R "$account:$group" "$omz_dir"
    chmod -R go-w "$omz_dir"

    install -o "$account" -g "$group" -m 0644 /tmp/vast-zshrc "$home/.zshrc"
    install -o "$account" -g "$group" -m 0644 /tmp/vast-tmux.conf "$home/.tmux.conf"

    tpm_dir="$home/.tmux/plugins/tpm"
    resurrect_dir="$home/.tmux/plugins/tmux-resurrect"
    install -d -o "$account" -g "$group" "$home/.tmux/plugins"
    [[ -e "$tpm_dir" ]] || git clone --depth=1 https://github.com/tmux-plugins/tpm.git "$tpm_dir"
    [[ -e "$resurrect_dir" ]] || git clone --depth=1 https://github.com/tmux-plugins/tmux-resurrect.git "$resurrect_dir"
    chown -R "$account:$group" "$home/.tmux"
    chmod -R go-w "$home/.tmux"

    config_dir="$home/.config/nvim"
    if [[ ! -e "$config_dir" ]]; then
        install -d -o "$account" -g "$group" "$home/.config"
        git clone --depth=1 https://github.com/PiotrGrzybowski/kickstart.nvim.git "$config_dir"
        chown -R "$account:$group" "$config_dir"
    fi
    rm -f "$config_dir/lua/custom/plugins/luarock.lua"
done

rm /tmp/vast-zshrc /tmp/vast-tmux.conf
