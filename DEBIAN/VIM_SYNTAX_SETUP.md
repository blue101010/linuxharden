# Vim Syntax Highlighting for Audit Rules

## Quick Install (Automatic)

```bash
chmod +x install_vim_audit_syntax.sh
./install_vim_audit_syntax.sh
```

That's it! Now when you edit `.rules` files, you'll get syntax highlighting.

---

## Manual Install

### Method 1: User-Level (No Root Required)

```bash
# Create vim syntax directory
mkdir -p ~/.vim/syntax
mkdir -p ~/.vim/ftdetect

# Copy syntax file
cp audit.vim ~/.vim/syntax/audit.vim

# Create filetype detection
cat > ~/.vim/ftdetect/audit.vim << 'EOF'
autocmd BufRead,BufNewFile *.rules set filetype=audit
autocmd BufRead,BufNewFile */audit/*.rules set filetype=audit
autocmd BufRead,BufNewFile audit.rules set filetype=audit
EOF

# Add to .vimrc
echo "autocmd BufRead,BufNewFile *.rules set filetype=audit syntax=audit" >> ~/.vimrc
```

### Method 2: System-Wide (Requires Root)

```bash
# Find your vim version
VIM_DIR=$(ls -d /usr/share/vim/vim[0-9]* | tail -1)

# Copy syntax file
sudo cp audit.vim $VIM_DIR/syntax/audit.vim

# Create filetype detection
sudo mkdir -p $VIM_DIR/ftdetect
sudo tee $VIM_DIR/ftdetect/audit.vim << 'EOF'
autocmd BufRead,BufNewFile *.rules set filetype=audit
autocmd BufRead,BufNewFile */audit/*.rules set filetype=audit
EOF
```

---

## Test It

```bash
# Open an audit rules file
vim /etc/audit/rules.d/audit.rules

# Or from this repo
vim etc/audit/rules.d/audit.rules
```

You should see:
- 🟦 **Blue** - Comments
- 🟩 **Green** - Strings and paths
- 🟪 **Purple** - Keywords and flags
- 🟨 **Yellow** - System calls
- 🟥 **Red** - Numbers and constants

---

## What Gets Highlighted

### Comments
```bash
# This is highlighted as a comment
## TODO: This is highlighted with TODO emphasis
############### Section dividers are highlighted
```

### Rule Components
```bash
# Flags and options
-a always,exit          # 'always', 'exit' highlighted
-F arch=b64             # 'arch', 'b64' highlighted
-S chmod                # System call highlighted
-k key_name             # Key name highlighted
-w /etc/passwd          # Path highlighted
-p wa                   # Permissions highlighted
```

### System Calls
```bash
-S adjtimex -S settimeofday -S clock_settime  # All highlighted
-S chmod -S fchmod -S fchmodat                # All highlighted
-S execve -S execveat                         # All highlighted
```

### Fields and Operators
```bash
-F auid>=1000           # Field and operator highlighted
-F exit=-EACCES         # Error code highlighted
-F auid!=4294967295     # Comparison highlighted
```

### Special Commands
```bash
-D          # Delete all rules (highlighted)
-b 8192     # Set buffer (highlighted)
-f 1        # Set failure mode (highlighted)
-e 2        # Set immutable (highlighted)
```

---

## Troubleshooting

### Syntax highlighting not working?

1. **Check syntax is enabled:**
   ```vim
   :syntax on
   ```

2. **Manually set filetype:**
   ```vim
   :set filetype=audit
   ```

3. **Check filetype was detected:**
   ```vim
   :set filetype?
   ```
   Should show: `filetype=audit`

4. **Verify syntax file exists:**
   ```bash
   ls -la ~/.vim/syntax/audit.vim
   # or
   ls -la /usr/share/vim/vim*/syntax/audit.vim
   ```

### Colors look wrong?

Try different color schemes:
```vim
:colorscheme desert
:colorscheme evening
:colorscheme slate
```

Or add to `~/.vimrc`:
```vim
colorscheme desert
syntax on
```

### Still not working?

Force the syntax:
```vim
:set syntax=audit
```

Or add to the top of your rules file:
```bash
# vim: syntax=audit
```

---

## Vim Commands Reference

### While Editing

| Command | Action |
|---------|--------|
| `:syntax on` | Enable syntax highlighting |
| `:syntax off` | Disable syntax highlighting |
| `:set filetype=audit` | Set filetype to audit |
| `:set syntax=audit` | Force audit syntax |
| `:syntax` | Show current syntax info |
| `:highlight` | Show all highlight groups |

### Navigation

| Command | Action |
|---------|--------|
| `/pattern` | Search forward |
| `?pattern` | Search backward |
| `n` | Next search result |
| `N` | Previous search result |
| `*` | Search for word under cursor |

### Useful .vimrc Settings

Add these to `~/.vimrc` for better editing:

```vim
" Enable syntax highlighting
syntax on

" Show line numbers
set number

" Highlight search results
set hlsearch

" Incremental search
set incsearch

" Auto-indent
set autoindent

" Show matching brackets
set showmatch

" Enable filetype detection
filetype plugin indent on

" Specific settings for audit rules
autocmd FileType audit setlocal ts=4 sw=4 expandtab
autocmd FileType audit setlocal commentstring=#\ %s
```

---

## Color Customization

To customize colors, add to `~/.vimrc`:

```vim
" Custom colors for audit syntax
highlight auditComment ctermfg=darkgray
highlight auditSyscall ctermfg=yellow
highlight auditKey ctermfg=cyan
highlight auditPath ctermfg=green
highlight auditCommand ctermfg=red cterm=bold
```

---

## Uninstall

```bash
# Remove syntax file
rm ~/.vim/syntax/audit.vim
rm /usr/share/vim/vim*/syntax/audit.vim

# Remove filetype detection
rm ~/.vim/ftdetect/audit.vim
rm /usr/share/vim/vim*/ftdetect/audit.vim

# Remove from .vimrc (edit manually)
vim ~/.vimrc
# Delete lines mentioning 'audit'
```

---

## Files Included

- **`audit.vim`** - Main syntax file
- **`install_vim_audit_syntax.sh`** - Automatic installer
- **`VIM_SYNTAX_SETUP.md`** - This guide

---

## Examples

### Before (No Highlighting)
```
-a always,exit -F arch=b64 -S chmod -F auid>=1000 -k perm_mod
```

### After (With Highlighting)
```
-a always,exit -F arch=b64 -S chmod -F auid>=1000 -k perm_mod
   ^^^^^^ ^^^^    ^^^^^^^^    ^^^^^    ^^^^^^^^^^    ^^^^^^^^
   action type    arch        syscall  field         key
```

All in different colors for easy reading!

---

## Tips

1. **Use tabs for better alignment** when editing rules
2. **Enable line numbers** (`:set number`) to match error messages
3. **Use search** (`/syscall_name`) to find specific system calls
4. **Comment liberally** - comments are clearly visible
5. **Test rules immediately** with `:!sudo auditctl -l` from within vim

---

Enjoy colorful audit rules! 🎨
