# Add git bash completion.
if [ -f "/etc/bash_completion.d/git" ]; then
	. "/etc/bash_completion.d/git"
fi

# Add git prompt.
if [ -f "/etc/bash_completion.d/git-prompt.sh" ]; then
	. "/etc/bash_completion.d/git-prompt.sh"
fi

# If running bash, include .bashrc if it exists.
if [ -n "$BASH_VERSION" ]; then
	if [ -f "$HOME/.bashrc" ]; then
		. "$HOME/.bashrc"
	fi
fi
