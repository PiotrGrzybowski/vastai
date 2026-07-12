# Vast.ai Bootstrap Checklist

## Base image

- [x] Select `vastai/base-image:cuda-13.3.0-auto`
- [x] Pull the image locally
- [ ] Confirm the Vast.ai host has an NVIDIA 580+ driver for CUDA 13

## Python environment

- [x] Disable Vast's automatic `/venv/main` activation with `--no-activate-pyenv`
- [x] Keep Miniforge and `/venv/main` installed for initial Vast/Jupyter compatibility
- [x] Confirm `uv` is available in a clean Zsh session
- [ ] Create project-local environments with `uv venv` or `uv sync`
- [ ] Verify Jupyter works without automatic Conda activation
- [ ] Decide whether Conda can be hidden or removed after compatibility testing

## Provisioning

- [x] Add `provision.sh`
- [x] Make provisioning idempotent
- [x] Install Zsh only when missing
- [x] Set `/bin/zsh` as the login shell for `root` and `user`
- [x] Add a minimal `.zshrc`
- [x] Preserve `/etc/environment`, workspace `.env`, and `/workspace` startup behavior
- [ ] Publish `provision.sh` in a public GitHub repository
- [ ] Set `PROVISIONING_SCRIPT` to its raw GitHub URL in the Vast.ai template
- [ ] Run provisioning on a real Vast.ai instance
- [ ] Inspect provisioning logs and verify a second boot is clean

## Local testing

- [x] Add `test-provision.sh`
- [x] Test against the CUDA 13.3 Vast.ai base image
- [x] Run provisioning twice in one disposable container
- [x] Verify both login shells, working directory, `uv`, and inactive Conda state
- [x] Run a headless Lazy plugin sync against the public Neovim config
- [ ] Add checks only when new provisioning behavior is introduced

## Shell and tools

- [x] Add basic Zsh configuration
- [x] Install the latest stable Neovim release for amd64 or arm64
- [x] Install `ripgrep` and `fd-find`
- [x] Expose the Debian `fdfind` command as `fd`
- [x] Load the image's existing NVM/Node installation in Zsh
- [x] Install Prettier and OpenCode with npm
- [x] Install Tree-sitter CLI with npm
- [x] Clone the Neovim config over HTTPS for `root` and `user`
- [x] Disable unused `luarocks.nvim` in provisioned clones
- [ ] Remove `lua/custom/plugins/luarock.lua` from the upstream config repository
- [ ] Run Neovim plugin installation and `:checkhealth` on Vast.ai
- [x] Add Oh My Zsh
- [x] Add Zsh autosuggestions
- [x] Add Zsh syntax highlighting as the last plugin
- [x] Install tmux
- [x] Add `.tmux.conf` with OSC52 clipboard support
- [x] Add TPM and tmux-resurrect
- [ ] Add required CLI tools incrementally
- [ ] Decide which configs live in this repository and which come from a dotfiles repository

## Template settings

- [ ] Use Docker ENTRYPOINT launch mode
- [ ] Set entrypoint arguments to `--no-activate-pyenv`
- [ ] Set `PROVISIONING_SCRIPT=https://raw.githubusercontent.com/USER/REPO/main/provision.sh`
- [ ] Keep secrets in Vast.ai account variables, not the public template or script
