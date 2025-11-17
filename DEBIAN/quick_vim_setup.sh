#!/bin/bash
# Ultra-quick vim syntax setup for audit rules (one-liner compatible)

mkdir -p ~/.vim/syntax ~/.vim/ftdetect && \
cp audit.vim ~/.vim/syntax/ && \
echo "autocmd BufRead,BufNewFile *.rules set filetype=audit" > ~/.vim/ftdetect/audit.vim && \
grep -q "syntax on" ~/.vimrc 2>/dev/null || echo -e "\nsyntax on\nautocmd BufRead,BufNewFile *.rules set filetype=audit syntax=audit" >> ~/.vimrc && \
echo "✓ Vim syntax for audit rules installed! Test with: vim etc/audit/rules.d/audit.rules"
