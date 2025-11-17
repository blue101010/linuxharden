" Vim syntax file
" Language:     Linux Audit Rules
" Maintainer:   Auto-generated for audit hardening
" Last Change:  2025
" File Types:   audit.rules, *.rules (in /etc/audit/)

if exists("b:current_syntax")
  finish
endif

" Comments
syn match auditComment "#.*$"

" Rule flags and options
syn match auditFlag "\s-[a-zA-Z]"
syn match auditLongFlag "\s--[a-zA-Z-]*"

" Numbers (including buffer size, exit codes, etc.)
syn match auditNumber "\<\d\+\>"
syn match auditNumber "\<0x\x\+\>"
syn match auditNumber "\s-\d\+\>"

" Rule actions
syn keyword auditAction always never
syn keyword auditList task exit user exclude

" System call architecture
syn match auditArch "arch=b\(32\|64\)"

" System calls
syn keyword auditSyscall adjtimex settimeofday clock_settime stime
syn keyword auditSyscall sethostname setdomainname
syn keyword auditSyscall chmod fchmod fchmodat chown fchown fchownat lchown
syn keyword auditSyscall setxattr lsetxattr fsetxattr removexattr lremovexattr fremovexattr
syn keyword auditSyscall open openat openat2 creat truncate ftruncate
syn keyword auditSyscall unlink unlinkat rename renameat renameat2 rmdir
syn keyword auditSyscall init_module delete_module finit_module
syn keyword auditSyscall setuid setreuid setresuid setgid setregid setresgid
syn keyword auditSyscall execve execveat
syn keyword auditSyscall mount umount umount2
syn keyword auditSyscall swapon swapoff

" Field options
syn match auditField "-F\s\+\(arch\|auid\|uid\|gid\|euid\|egid\|suid\|sgid\|fsuid\|fsgid\)"
syn match auditField "-F\s\+\(pid\|ppid\|success\|exit\|a[0-3]\|path\|dir\|perm\|key\|subj\)"
syn match auditField "-F\s\+\(obj_user\|obj_role\|obj_type\|obj_lev_low\|obj_lev_high\)"

" Watch options
syn match auditWatch "-w\s\+\S\+" contains=auditPath
syn match auditPath "/[^ ]*" contained

" Permissions
syn match auditPerm "-p\s\+[rwxa]\+"

" Keys
syn match auditKey "-k\s\+[a-zA-Z0-9_-]\+"

" Exit codes and error numbers
syn match auditExit "exit=-\?\w\+"
syn keyword auditErrorCode EACCES EPERM ENOENT

" Special operators
syn match auditOperator "!="
syn match auditOperator ">="
syn match auditOperator "<="
syn match auditOperator "="
syn match auditOperator "&"

" System call filters
syn match auditSyscallFlag "-S\s\+\w\+"

" Comparison values
syn match auditAuid "auid[!<>=]\+\d\+"
syn match auditUid "uid[!<>=]\+\d\+"

" Special rule commands
syn match auditCommand "^-D" " Delete all rules
syn match auditCommand "^-b\s\+\d\+" " Set buffer
syn match auditCommand "^-f\s\+[0-2]" " Set failure mode
syn match auditCommand "^-e\s\+[0-2]" " Set enabled/immutable
syn match auditCommand "^-r\s\+\d\+" " Set rate limit

" File paths (common directories)
syn match auditDirectory "/etc/"
syn match auditDirectory "/var/"
syn match auditDirectory "/usr/"
syn match auditDirectory "/bin/"
syn match auditDirectory "/sbin/"
syn match auditDirectory "/boot/"
syn match auditDirectory "/root"
syn match auditDirectory "/tmp"

" Important keywords in comments
syn keyword auditTodo TODO FIXME NOTE WARNING IMPORTANT contained containedin=auditComment
syn keyword auditSection CIS NIST PCI-DSS STIG contained containedin=auditComment

" Section dividers (comment lines with # symbols)
syn match auditSectionDivider "^#\{10,}.*$"

" Define highlighting
hi def link auditComment        Comment
hi def link auditFlag           Keyword
hi def link auditLongFlag       Keyword
hi def link auditNumber         Number
hi def link auditAction         Statement
hi def link auditList           Type
hi def link auditArch           PreProc
hi def link auditSyscall        Function
hi def link auditField          Identifier
hi def link auditWatch          Special
hi def link auditPath           String
hi def link auditPerm           Type
hi def link auditKey            Constant
hi def link auditExit           Special
hi def link auditErrorCode      Constant
hi def link auditOperator       Operator
hi def link auditSyscallFlag    Keyword
hi def link auditAuid           Number
hi def link auditUid            Number
hi def link auditCommand        PreProc
hi def link auditDirectory      Directory
hi def link auditTodo           Todo
hi def link auditSection        SpecialComment
hi def link auditSectionDivider SpecialComment

let b:current_syntax = "audit"
