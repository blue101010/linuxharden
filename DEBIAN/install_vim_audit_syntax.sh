#!/bin/bash

#############################################################################
# Install Vim Syntax Highlighting for Audit Rules
# Purpose: Enable syntax highlighting for .rules files in vim
# Usage: sudo ./install_vim_audit_syntax.sh
#############################################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "Installing Vim syntax highlighting for audit rules..."
echo ""

# Determine vim runtime directories to check
VIM_DIRS=(
    "/usr/share/vim/vim[0-9]*/syntax"
    "/usr/share/vim/vimfiles/syntax"
    "$HOME/.vim/syntax"
)

# Find actual vim syntax directory
VIM_SYNTAX_DIR=""
for pattern in "${VIM_DIRS[@]}"; do
    for dir in $pattern; do
        if [ -d "$dir" ]; then
            VIM_SYNTAX_DIR="$dir"
            break 2
        fi
    done
done

# If no system dir found, create user directory
if [ -z "$VIM_SYNTAX_DIR" ]; then
    VIM_SYNTAX_DIR="$HOME/.vim/syntax"
    mkdir -p "$VIM_SYNTAX_DIR"
    echo -e "${YELLOW}Created user vim directory: $VIM_SYNTAX_DIR${NC}"
fi

# Copy syntax file
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [ -f "$SCRIPT_DIR/audit.vim" ]; then
    cp "$SCRIPT_DIR/audit.vim" "$VIM_SYNTAX_DIR/audit.vim"
    echo -e "${GREEN}✓ Installed audit.vim to: $VIM_SYNTAX_DIR${NC}"
else
    echo -e "${RED}✗ audit.vim not found in current directory${NC}"
    exit 1
fi

# Create or update filetype detection
FTDETECT_DIR="${VIM_SYNTAX_DIR%/syntax}/ftdetect"
mkdir -p "$FTDETECT_DIR"

cat > "$FTDETECT_DIR/audit.vim" << 'EOF'
" Detect audit rules files
autocmd BufRead,BufNewFile *.rules set filetype=audit
autocmd BufRead,BufNewFile */audit.d/*.conf set filetype=audit
autocmd BufRead,BufNewFile */audit/*.rules set filetype=audit
autocmd BufRead,BufNewFile audit.rules set filetype=audit
EOF

echo -e "${GREEN}✓ Created filetype detection: $FTDETECT_DIR/audit.vim${NC}"

# Add to user vimrc if it doesn't exist
VIMRC="$HOME/.vimrc"
if [ ! -f "$VIMRC" ] || ! grep -q "filetype.*audit" "$VIMRC"; then
    echo "" >> "$VIMRC"
    echo "\" Enable syntax highlighting for audit rules" >> "$VIMRC"
    echo "autocmd BufRead,BufNewFile *.rules set filetype=audit syntax=audit" >> "$VIMRC"
    echo -e "${GREEN}✓ Updated ~/.vimrc${NC}"
else
    echo -e "${YELLOW}→ ~/.vimrc already configured${NC}"
fi

# Test the installation
echo ""
echo "Testing installation..."
if [ -f "$VIM_SYNTAX_DIR/audit.vim" ]; then
    echo -e "${GREEN}✓ Syntax file installed correctly${NC}"
else
    echo -e "${RED}✗ Installation verification failed${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}Installation complete!${NC}"
echo ""
echo "Usage:"
echo "  vim /etc/audit/rules.d/audit.rules"
echo ""
echo "Features enabled:"
echo "  • Syntax highlighting for system calls"
echo "  • Color-coded flags and options"
echo "  • Comment highlighting"
echo "  • Path and key highlighting"
echo "  • Section dividers"
echo ""
echo "Vim commands to try:"
echo "  :syntax on          - Enable syntax"
echo "  :set filetype=audit - Force audit syntax"
echo "  :syntax             - Show current syntax"
echo ""
