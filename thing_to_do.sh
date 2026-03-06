#!/bin/bash
#
# System Setup Script for Kali Linux
# This script sets up directories, aliases, and installs essential tools
#

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Print colored messages
print_status() {
    echo -e "${GREEN}[*]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[x]${NC} $1"
}

# =============================================================================
# System Update
# =============================================================================
print_status "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# =============================================================================
# Create Directories
# =============================================================================
print_status "Creating directories..."

DIRECTORIES=(
    "$HOME/Tools"
    "$HOME/Docs"
    "$HOME/Notes"
    "$HOME/Scripts"
    "$HOME/Trash"
    "$HOME/Temps"
)

for dir in "${DIRECTORIES[@]}"; do
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        print_status "Created: $dir"
    else
        print_warning "Already exists: $dir"
    fi
done

# =============================================================================
# Directory Navigation Aliases
# =============================================================================
print_status "Setting up directory aliases..."

cat >> ~/.bashrc << 'EOF'

# =============================================================================
# Custom Aliases - Directory Navigation
# =============================================================================
alias scripts='cd ~/Scripts'
alias notes='cd ~/Notes'
alias docsh='cd ~/Docs'
alias tools='cd ~/Tools'
alias wordlists='cd ~/Wordlists'
alias trash='cd ~/Trash'
alias temps='cd ~/Temps'
alias download='cd ~/Downloads'
alias documents='cd ~/Documents'
alias desktop='cd ~/Desktop'
EOF

# =============================================================================
# Utility Aliases
# =============================================================================
print_status "Setting up utility aliases..."

cat >> ~/.bashrc << 'EOF'

# =============================================================================
# Custom Aliases - Utilities
# =============================================================================
alias yep='sudo apt install'
alias nope='sudo apt remove'
alias root='sudo -i'
alias c='clear'
alias cls='clear && echo "Welcome back, $(whoami)! Stay sharp"'
alias hg='history | grep'
alias ports='nmap localhost'
alias lss='ls -lah --color=auto'
alias lt='ls -lt --color=auto'
alias emptytrash='rm -rf ~/Trash/*'
alias cleantemps='rm -rf ~/Temps/*'
alias notepad='nano ~/Notes/quick_notes.txt'
alias updatekali='sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y'
alias run='bash'
alias ..='cd ..'
alias ...='cd ../..'
alias nessus-start='sudo /bin/systemctl start nessusd.service'
alias nessus-stop='sudo /bin/systemctl stop nessusd.service'
EOF

# =============================================================================
# Source Configuration
# =============================================================================
print_status "Sourcing shell configuration..."
if [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi

# =============================================================================
# Install Zsh Autosuggestions
# =============================================================================
print_status "Installing zsh-autosuggestions..."
if command -v zsh &> /dev/null; then
    sudo apt install -y zsh-autosuggestions
else
    print_warning "Zsh not installed, skipping zsh-autosuggestions"
fi

# =============================================================================
# Setup Wordlists
# =============================================================================
print_status "Setting up wordlists..."

# Check if rockyou.txt exists and decompress if needed
if [ -f /usr/share/wordlists/rockyou.txt.gz ]; then
    if [ ! -f /usr/share/wordlists/rockyou.txt ]; then
        sudo gunzip /usr/share/wordlists/rockyou.txt.gz
        print_status "Decompressed rockyou.txt"
    else
        print_warning "rockyou.txt already exists"
    fi
fi

# Create symbolic link if it doesn't exist
if [ ! -L "$HOME/Wordlists" ] && [ ! -d "$HOME/Wordlists" ]; then
    ln -s /usr/share/wordlists ~/Wordlists
    print_status "Created Wordlists symlink"
else
    print_warning "Wordlists symlink already exists"
fi

# =============================================================================
# Final Message
# =============================================================================
print_status "Setup complete! Restart your terminal or run 'source ~/.bashrc' to apply changes."
print_status "Useful commands:"
echo "  - scripts, notes, docsh, tools  : Navigate to directories"
echo "  - updatekali                      : Update system"
echo "  - lss, lt                         : List files"
echo "  - emptytrash, cleantemps         : Clean directories"
