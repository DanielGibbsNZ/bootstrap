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
INSTALL_LOCATION="${HOME}"
NANORC_LOCATIONS=("/usr/share/nano" "/usr/local/share/nano")
RC_FILES=(".bashrc" ".vimrc" ".nanorc" ".gitconfig")

# File installation function.
function install_file {
	FILE=$1
	printf "Installing ${FILE}... "
	if [ -e ${INSTALL_LOCATION}/${FILE} ]; then
		# If file already exists check for differences.
		if cmp -s ${INSTALL_LOCATION}/${FILE} /tmp/${FILE}; then
			echo -e "\033[32mDONE\033[0m"
		else
			# If there are differences, ask the user which version they want.
			echo -e "\033[33mEXISTS\033[0m"
			REPLACE=""
			while [ "${REPLACE}" != "y" -a "${REPLACE}" != "n" ]; do
				read -p "Replace original file (d for diff)? (y/n/d) " REPLACE
				if [ "${REPLACE}" = "d" ]; then
					${DIFF} ${INSTALL_LOCATION}/${FILE} /tmp/${FILE} | less -r
				fi
			done
			if [ "${REPLACE}" = "y" ]; then
				mv /tmp/${FILE} ${INSTALL_LOCATION}/${FILE}
			else
				echo "The downloaded version of ${FILE} can be found in /tmp/${FILE} for manual merging."
			fi
		fi
	else
		mv /tmp/${FILE} ${INSTALL_LOCATION}/${FILE}
		echo -e "\033[32mDONE\033[0m"
	fi
}

# Process arguments.
if [ "$1" = "-d" -o "$1" = "--dest" ]; then
	if [ "$2" -a -d "$2" ]; then
		INSTALL_LOCATION="$2"
	else
		echo "Invalid destination: $2"
		exit 1
	fi
fi

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

# Check for wget or cURL.
if command -v curl &>/dev/null; then
	DOWNLOAD="curl -fsL"
	OUTPUT="-o"
elif command -v wget &>/dev/null; then
	DOWNLOAD="wget -q"
	OUTPUT="-O"
else
	echo "Can't bootstrap without cURL or wget."
	exit 1
fi

# Check for colordiff.
if command -v colordiff &>/dev/null; then
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
		continue
	fi

	# Search for nanorc files and add them to .nanorc.
	if [ "${FILE}" = ".nanorc" ]; then
		for NANORC_LOCATION in ${NANORC_LOCATIONS[*]}; do
			if [ -d ${NANORC_LOCATION} ]; then
				echo "" >> /tmp/${FILE}
				for NANORC_FILE in $(ls ${NANORC_LOCATION}/*.nanorc 2>/dev/null); do
					echo "include ${NANORC_FILE}" >> /tmp/${FILE}
				done
			fi
		done
	fi

	install_file "${FILE}"
done

# OS X specific setup.
if [ "${PLATFORM}" = "OS X" ]; then
	# Download and install .profile.
	printf "Downloading .profile... "
	if ${DOWNLOAD} ${FILE_LOCATION}/osx/.profile ${OUTPUT} /tmp/.profile; then
		echo -e "\033[32mDONE\033[0m"
		install_file ".profile"
	else
		echo -e "\033[31mFAILED\033[0m"
	fi

	echo
	if command -v brew &>/dev/null; then
		printf "Downloading Homebrew formula list... "
		if ${DOWNLOAD} ${FILE_LOCATION}/osx/homebrew-formulae ${OUTPUT} /tmp/homebrew-formulae; then
			echo -e "\033[32mDONE\033[0m"
		else
			echo -e "\033[31mFAILED\033[0m"
		fi

		# Check for missing formulae.
		brew list > /tmp/homebrew-installed
		FORMULAE_TO_INSTALL=()
		for FORMULA in $(cat /tmp/homebrew-formulae); do
			if ! grep "^${FORMULA}$" -q /tmp/homebrew-installed; then
				echo -e "${FORMULA} is not installed."
				FORMULAE_TO_INSTALL+=("${FORMULA}")
			fi
		done
		rm -f /tmp/homebrew-formulae /tmp/homebrew-installed
		if [ ${#FORMULAE_TO_INSTALL[@]} -gt 0 ]; then
			echo
			echo -e "You can install the missing formulae with \033[36;1mbrew install ${FORMULAE_TO_INSTALL[*]}\033[0m."
		else
			echo "All formulae installed."
		fi
		echo
		echo -e "Remember to run \033[36;1mbrew update\033[0m and \033[36;1mbrew upgrade\033[0m regularly."
	else
		echo "Homebrew is not installed, you can install it with the following command."
		echo -e "\033[36;1mruby -e \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)\"\033[0m"
		echo -e "Once installed, don't forget to run \033[36;1mbrew doctor\033[0m and rerun this script."
	fi
fi
