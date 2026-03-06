#!/usr/bin/env bash
# =============================================================================
# Kali Linux Environment Setup Script
# =============================================================================

set -euo pipefail

# ── Colors for output ────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

info()    { echo -e "${CYAN}[*]${NC} $1"; }
success() { echo -e "${GREEN}[+]${NC} $1"; }
warn()    { echo -e "${YELLOW}[!]${NC} $1"; }
error()   { echo -e "${RED}[-]${NC} $1"; exit 1; }

# ── Check for zsh ────────────────────────────────────────────────────────────
ZSHRC="$HOME/.zshrc"
if [ ! -f "$ZSHRC" ]; then
    warn ".zshrc not found — creating one at $ZSHRC"
    touch "$ZSHRC"
fi

# =============================================================================
# 1. System Update
# =============================================================================
info "Updating system packages..."
sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y
success "System updated."

# =============================================================================
# 2. Install Packages
# =============================================================================
info "Installing zsh-autosuggestions..."
sudo apt install -y zsh-autosuggestions
success "zsh-autosuggestions installed."

# =============================================================================
# 3. Create Directory Structure
# =============================================================================
info "Creating directory structure..."
DIRS=(Tools Docs Notes Scripts Trash Temps)
for dir in "${DIRS[@]}"; do
    mkdir -p "$HOME/$dir"
done
success "Directories created: ${DIRS[*]}"

# =============================================================================
# 4. Write Aliases to .zshrc
# =============================================================================
info "Writing aliases to $ZSHRC..."

# Guard against duplicate entries on re-runs
MARKER="# >>> kali-setup aliases <<<"
if grep -q "$MARKER" "$ZSHRC"; then
    warn "Aliases already present in $ZSHRC — skipping to avoid duplicates."
else
    cat >> "$ZSHRC" << 'EOF'

# >>> kali-setup aliases <<<

# ── Navigation ───────────────────────────────────────────────────────────────
alias scripts="cd ~/Scripts"
alias notes="cd ~/Notes"
alias docsh="cd ~/Docs"
alias tools="cd ~/Tools"
alias wordlists="cd ~/Wordlists"
alias trash="cd ~/Trash"
alias temps="cd ~/Temps"
alias download="cd ~/Downloads"
alias documents="cd ~/Documents"
alias desktop="cd ~/Desktop"
alias ..='cd ..'
alias ...='cd ../..'

# ── Package Management ───────────────────────────────────────────────────────
alias yep="sudo apt install"
alias nope="sudo apt remove"
alias updatekali="sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y"

# ── Shell Utilities ──────────────────────────────────────────────────────────
alias root="sudo -i"
alias c="clear"
alias cls='clear && echo "Welcome back, $(whoami)! Stay sharp 🔥"'
alias hg="history | grep"
alias lss='ls -lah --color=auto'
alias lt='ls -lt --color=auto'
alias run="bash"

# ── File & Folder Shortcuts ──────────────────────────────────────────────────
alias emptytrash='rm -rf ~/Trash/*'
alias cleantemps='rm -rf ~/Temps/*'
alias notepad="nano ~/Notes/quick_notes.txt"

# ── Network & Security ───────────────────────────────────────────────────────
alias ports="nmap localhost"
alias nessus-start="sudo /bin/systemctl start nessusd.service"
alias nessus-stop="sudo /bin/systemctl stop nessusd.service"

# <<< kali-setup aliases <<<
EOF
    success "Aliases written to $ZSHRC."
fi

# =============================================================================
# 5. Wordlists Setup
# =============================================================================
ROCKYOU_GZ="/usr/share/wordlists/rockyou.txt.gz"
ROCKYOU_TXT="/usr/share/wordlists/rockyou.txt"
WORDLISTS_LINK="$HOME/Wordlists"

if [ -f "$ROCKYOU_GZ" ]; then
    info "Decompressing rockyou.txt..."
    sudo gunzip "$ROCKYOU_GZ"
    success "rockyou.txt decompressed."
elif [ -f "$ROCKYOU_TXT" ]; then
    warn "rockyou.txt already decompressed — skipping."
else
    warn "rockyou.txt.gz not found — skipping decompression."
fi

if [ ! -L "$WORDLISTS_LINK" ]; then
    ln -s /usr/share/wordlists "$WORDLISTS_LINK"
    success "Symlink created: ~/Wordlists → /usr/share/wordlists"
else
    warn "~/Wordlists symlink already exists — skipping."
fi

# =============================================================================
# 6. Reload Shell Config
# =============================================================================
info "Reloading $ZSHRC..."
# shellcheck disable=SC1090
source "$ZSHRC" 2>/dev/null || warn "Could not source $ZSHRC from bash — open a new zsh session to apply aliases."

# =============================================================================
echo ""
success "Setup complete! Open a new zsh session to use all aliases."
