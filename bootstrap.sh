#!/bin/bash
#
# Bootstrap for my personal settings and configuration files.
#
# The following files are downloaded from my web server and copied to the appropriate place:
# - .bashrc
# - .vimrc
# - .nanorc
# - .gitconfig
#

FILE_LOCATION="https://raw.githubusercontent.com/DanielGibbsNZ/bootstrap/master"
RC_FILES=(".bashrc" ".vimrc" ".nanorc" ".gitconfig")

# 0. Detect operating system (not exhaustive).
if [ "$(uname -s)" == "Darwin" ]; then
    PLATFORM="OS X"
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    PLATFORM="Linux"
elif [ "$(expr substr $(uname -s) 1 5)" == "MINGW" ]; then
    PLATFORM="Windows"
elif [ "$(expr substr $(uname -s) 1 6)" == "CYGWIN" ]; then
    PLATFORM="Windows"
fi

# 0. Check for wget or cURL.
if type -t curl | grep -q file; then
	DOWNLOAD="curl -s"
	OUTPUT="-o"
elif type -t wget | grep -q file; then
	DOWNLOAD="wget -q"
	OUTPUT="-O"
else
	echo "Can't bootstrap without cURL or wget."
	exit 1
fi

# 0. Check for colordiff.
if type -t colordiff | grep -q file; then
	DIFF="colordiff"
else
	DIFF="diff"
fi

# 1. Download and install RC files.
for FILE in ${RC_FILES[*]}; do
	printf "Downloading ${FILE}... "
	if ${DOWNLOAD} ${FILE_LOCATION}/${FILE} ${OUTPUT} /tmp/${FILE}; then
		echo -e "\033[32mDONE\033[0m"
	else
		echo -e "\033[31mFAILED\033[0m"
	fi

	printf "Installing ${FILE}... "
	if [ -e ~/${FILE} ]; then
		# If file already exists check for differences.
		if cmp -s ~/${FILE} /tmp/${FILE}; then
			echo -e "\033[32mDONE\033[0m"
		else
			# If there are differences, ask the user which version they want.
			echo -e "\033[33mEXISTS\033[0m"
			REPLACE=""
			while [ "${REPLACE}" != "y" -a "${REPLACE}" != "n" ]; do
				read -p "Replace original file (d for diff)? (y/n/d) " REPLACE
				if [ "${REPLACE}" = "d" ]; then
					${DIFF} ~/${FILE} /tmp/${FILE} | less -r
				fi
			done
			if [ "${REPLACE}" = "y" ]; then
				mv /tmp/${FILE} ~/${FILE}
			else
				echo "The downloaded version of ${FILE} can be found in /tmp/${FILE} for manual merging."
			fi
		fi
	else
		mv /tmp/${FILE} ~/${FILE}
		echo -e "\033[32mDONE\033[0m"
	fi
done
