# .profile for OS X as it does not include one by default.

# If Homebrew is installed, make sure the relevant directories are in the PATH
# and PKG_CONFIG_PATH.
if command -v brew &>/dev/null; then
	export PATH="/usr/local/bin:/usr/local/sbin:$PATH"
	export PKG_CONFIG_PATH="$PKG_CONFIG_PATH:/opt/X11/lib/pkgconfig"
	if [ -d /usr/local/opt/android-sdk ]; then
		export ANDROID_HOME="/usr/local/opt/android-sdk"
	fi

	# Add git bash completion.
	if [ -f "$(brew --prefix)/etc/bash_completion.d/git-completion.bash" ]; then
		. "$(brew --prefix)/etc/bash_completion.d/git-completion.bash"
	fi

	# Add git prompt.
	if [ -f "$(brew --prefix)/etc/bash_completion.d/git-prompt.sh" ]; then
		. "$(brew --prefix)/etc/bash_completion.d/git-prompt.sh"
	fi
fi


# Add Scripts directory to PATH if it exists.
if [ -d "$HOME/Scripts" ]; then
	export PATH="$PATH:$HOME/Scripts"
fi

# If Java exists, export JAVA_HOME.
if [ -f /usr/libexec/java_home ]; then
	export JAVA_HOME=$(/usr/libexec/java_home)
fi

# If running bash, include .bashrc if it exists.
if [ -n "$BASH_VERSION" ]; then
	if [ -f "$HOME/.bashrc" ]; then
		. "$HOME/.bashrc"
	fi
fi
