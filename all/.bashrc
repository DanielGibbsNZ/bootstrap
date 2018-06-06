# If not running interactively, don't do anything.
[ -z "$PS1" ] && return
[[ "$-" != *i* ]] && return

# Detect operating system (not exhaustive).
if [ "$(uname -s)" == "Darwin" ]; then
	PLATFORM="OS X"
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
	PLATFORM="Linux"
elif [ "$(expr substr $(uname -s) 1 5)" == "MINGW" ]; then
	PLATFORM="Windows"
elif [ "$(expr substr $(uname -s) 1 6)" == "CYGWIN" ]; then
	PLATFORM="Windows"
fi
export PLATFORM

# Check the window size after each command and, if necessary, update the values of LINES and COLUMNS.
shopt -s checkwinsize

# Append to the history file, don't overwrite it.
shopt -s histappend

# Forgive small errors when changing directories.
shopt -s cdspell

# Don't put duplicate lines or lines starting with space in the history.
HISTCONTROL=ignoreboth

# Set history file size.
HISTSIZE=1000
HISTFILESIZE=2000

# Create `ps1` function to set PS1.
function ps1 {
	# Default the prompt to "[user@host directory]$ " with colours.
	PROMPT='\[\033[32m\]\u@\h\[\033[00m\] \[\033[34m\]\W\[\033[00m\]'
	if type -t __git_ps1 | grep -q "function"; then
		# If in a git repository, add the branch name to the prompt.
		GIT_PROMPT='$(__git_ps1 " \[\033[31m\](%s)")\[\033[00m\]'
		PROMPT="${PROMPT}${GIT_PROMPT}"
	fi

	# If label is set, add label to prompt.
	if [ -n "$1" ]; then
		LABEL="\[\033[36m\]$1\[\033[00m\]"
		PROMPT="${PROMPT} ${LABEL}"
	fi
	export PS1="[${PROMPT}]\$ "
}
ps1

# Create files as 755 or 644.
umask 022

# Enable colors.
export CLICOLOR=1

# My favourite editor.
export EDITOR="vi"

# Cross-platform aliases.
alias todo='vi .todo'
if command -v colordiff &>/dev/null; then
	alias diff='colordiff'
fi

# Platform dependant aliases.
if [ "${PLATFORM}" = "Windows" ]; then
	alias ls='ls --color=auto'
	alias grep='grep --color'
	alias open='cygstart'
	alias winpath='cygpath -w `pwd`'
	alias ifconfig='netsh interface ip show config'
	if command -v vim &>/dev/null; then
		alias vi='vim'
	fi
elif [ "${PLATFORM}" = "Linux" ]; then
	if [ -x /usr/bin/dircolors ]; then
		test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
	fi
	alias ls='ls --color=auto'
	alias grep='grep --color=auto'
elif [ "${PLATFORM}" = "OS X" ]; then
	alias ls='ls -G'
	alias grep='grep --color=auto'
	alias fixpref='killall -u $(whoami) cfprefsd'
fi
