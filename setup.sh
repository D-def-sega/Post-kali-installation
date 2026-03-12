#!/usr/bin/env bash
# =============================================================================
# Kali Linux Environment Setup Script
# =============================================================================

set -uo pipefail  # Removed -e so update failures don't abort the script

# ── Colors for output ────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

info()    { echo -e "${CYAN}[*]${NC} $1"; }
success() { echo -e "${GREEN}[+]${NC} $1"; }
warn()    { echo -e "${YELLOW}[!]${NC} $1"; }
error()   { echo -e "${RED}[-]${NC} $1"; }  # No longer exits — script continues

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

# Run each step independently so a failure in one doesn't stop the rest
if sudo apt update -y; then
    success "Package lists updated."
else
    warn "apt update encountered issues — continuing anyway."
fi

if sudo apt upgrade -y; then
    success "Packages upgraded."
else
    warn "apt upgrade encountered issues — continuing anyway."
fi

if sudo apt autoremove -y; then
    success "Unused packages removed."
else
    warn "apt autoremove encountered issues — continuing anyway."
fi

success "System update phase complete."

# =============================================================================
# 2. Install Packages
# =============================================================================
info "Installing zsh-autosuggestions..."
if sudo apt install -y zsh-autosuggestions; then
    success "zsh-autosuggestions installed."
else
    warn "Failed to install zsh-autosuggestions — continuing anyway."
fi

# ── Enable zsh-autosuggestions in .zshrc ─────────────────────────────────────
ZSH_AUTOSUG_MARKER="# >>> zsh-autosuggestions <<<"
if grep -q "$ZSH_AUTOSUG_MARKER" "$ZSHRC"; then
    warn "zsh-autosuggestions already sourced in $ZSHRC — skipping."
else
    info "Enabling zsh-autosuggestions in $ZSHRC..."
    cat >> "$ZSHRC" << 'EOF'

# >>> zsh-autosuggestions <<<
if [ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
    source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi
# <<< zsh-autosuggestions <<<
EOF
    success "zsh-autosuggestions sourced in $ZSHRC."
fi

# =============================================================================
# 3. Create Directory Structure
# =============================================================================
info "Creating directory structure..."
DIRS=(Tools Docs Notes Scripts Trash Temps)
DIRS_CREATED=()
DIRS_FAILED=()
for dir in "${DIRS[@]}"; do
    if mkdir -p "$HOME/$dir" 2>/dev/null; then
        DIRS_CREATED+=("$dir")
    else
        warn "Failed to create $HOME/$dir — continuing anyway."
        DIRS_FAILED+=("$dir")
    fi
done
[ ${#DIRS_CREATED[@]} -gt 0 ] && success "Directories created: ${DIRS_CREATED[*]}"
[ ${#DIRS_FAILED[@]}  -gt 0 ] && warn    "Directories skipped: ${DIRS_FAILED[*]}"

# =============================================================================
# 4. Write Aliases to .zshrc
# =============================================================================
info "Writing aliases to $ZSHRC..."

# Guard against duplicate entries on re-runs
MARKER="# >>> kali-setup aliases <<<"
if grep -q "$MARKER" "$ZSHRC" 2>/dev/null; then
    warn "Aliases already present in $ZSHRC — skipping to avoid duplicates."
else
    if cat >> "$ZSHRC" << 'EOF'

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
    then
        success "Aliases written to $ZSHRC."
    else
        warn "Failed to write aliases to $ZSHRC — continuing anyway."
    fi
fi

# =============================================================================
# 5. Wordlists Setup
# =============================================================================
ROCKYOU_GZ="/usr/share/wordlists/rockyou.txt.gz"
ROCKYOU_TXT="/usr/share/wordlists/rockyou.txt"
WORDLISTS_LINK="$HOME/Wordlists"

if [ -f "$ROCKYOU_GZ" ]; then
    info "Decompressing rockyou.txt..."
    if sudo gunzip "$ROCKYOU_GZ"; then
        success "rockyou.txt decompressed."
    else
        warn "Failed to decompress rockyou.txt — continuing anyway."
    fi
elif [ -f "$ROCKYOU_TXT" ]; then
    warn "rockyou.txt already decompressed — skipping."
else
    warn "rockyou.txt.gz not found — skipping decompression."
fi

if [ ! -L "$WORDLISTS_LINK" ]; then
    if ln -s /usr/share/wordlists "$WORDLISTS_LINK" 2>/dev/null; then
        success "Symlink created: ~/Wordlists → /usr/share/wordlists"
    else
        warn "Failed to create ~/Wordlists symlink — continuing anyway."
    fi
else
    warn "~/Wordlists symlink already exists — skipping."
fi

# =============================================================================
# 6. Reload Shell Config
# =============================================================================
info "Reloading $ZSHRC..."
# shellcheck disable=SC1090
if source "$ZSHRC" 2>/dev/null; then
    success "$ZSHRC reloaded successfully."
else
    warn "Could not source $ZSHRC from bash — open a new zsh session to apply aliases."
fi

# =============================================================================
echo ""
success "Setup complete! Open a new zsh session to use all aliases."
