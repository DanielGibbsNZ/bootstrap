#!/bin/bash
#
# Bootstrap for my personal settings and configuration files.
#
ALL_SECTIONS=("config" "scripts" "defaults" "fonts" "homebrew" "packages" "pip")
SECTIONS=()
FILE_LOCATION="https://raw.githubusercontent.com/DanielGibbsNZ/bootstrap/master"
INSTALL_LOCATION="${HOME}"
CONFIG_FILES=(".bashrc" ".inputrc" ".vimrc" ".gitconfig" ".gitignore_global")

# Function to check if a section is valid.
function valid_section {
	for _SECTION in "${ALL_SECTIONS[@]}"; do
		if [ "$1" = "${_SECTION}" ]; then
			return 0 # True.
		fi
	done
	return 1 # False.
}

# Function to check if a section should be executed.
function do_section {
	for _SECTION in "${SECTIONS[@]}"; do
		if [ "$1" = "${_SECTION}" ]; then
			return 0 # True.
		fi
	done
	return 1 # False.
}

# File installation function.
function install_file {
	FILE="$1"
	DEST="$2"
	printf "Installing ${FILE}... "
	if [ -e "${DEST}/${FILE}" -a "${ALWAYS_REPLACE}" = "no" ]; then
		# If file already exists check for differences.
		# Unless the --replace argument was given.
		if cmp -s "${DEST}/${FILE}" "${TMP_DIR}/${FILE}"; then
			echo -e "\033[32mDONE\033[0m"
		else
			# If there are differences, ask the user which version they want.
			# Unless the --never-replace argument was given.
			echo -e "\033[33mEXISTS\033[0m"
			if [ "${NEVER_REPLACE}" = "no" ]; then
				REPLACE=""
				while [ "${REPLACE}" != "y" -a "${REPLACE}" != "n" -a "${REPLACE}" != "m" ]; do
					read -p "Replace original file (d for diff, m for manual merge)? (y/n/d/m) " REPLACE
					if [ "${REPLACE}" = "d" ]; then
						${DIFF} "${DEST}/${FILE}" "${TMP_DIR}/${FILE}" | less -r
					fi
				done
				if [ "${REPLACE}" = "y" ]; then
					cp "${TMP_DIR}/${FILE}" "${DEST}/${FILE}"
				elif [ "${REPLACE}" = "m" ]; then
					MERGE_FILE="${DEST}/${FILE}.bootstrap"
					cp "${TMP_DIR}/${FILE}" "${DEST}/${FILE}.bootstrap"
					echo "The downloaded version of ${FILE} can be found in ${MERGE_FILE} for manual merging."
				fi
			fi
		fi
	else
		cp "${TMP_DIR}/${FILE}" "${DEST}/${FILE}"
		echo -e "\033[32mDONE\033[0m"
	fi
}

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

# Process arguments.
SKIPPED_SECTIONS=()
ALWAYS_REPLACE="no"
NEVER_REPLACE="no"
KEEP_TMP="no"
CLEAN="no"
while [ $# -gt 0 ]; do
	case "$1" in
		-k|--keep-tmp|--keeptmp)
			KEEP_TMP="yes"
			;;
		-c|--clean)
			CLEAN="yes"
			;;
		-r|--replace)
			ALWAYS_REPLACE="yes"
			;;
		-n|--no-replace|--noreplace)
			NEVER_REPLACE="yes"
			;;
		--skip=*)
			ARGS=$(echo "$1" | tail -c +8)
			set -- "--skip" "${ARGS}" "${@:2}"
			continue
			;;
		-s|--skip)
			if [ -z "$2" ]; then
				echo "$1 requires an argument."
				exit 1
			fi
			for SECTION in ${2//,/ }; do
				if valid_section "${SECTION}"; then
					SKIPPED_SECTIONS+=("${SECTION}")
				else
					echo "Invalid section: ${SECTION}"
					exit 1
				fi
			done
			shift
			;;
		-h|--help)
			echo "Usage $0 [options] [section1 section2...]"
			echo
			echo "Sets up a computer for my use. If a list of sections is given, only those"
			echo "sections will be executed. Otherwise all sections will be executed. If any"
			echo "sections are skipped they will not be executed."
			echo
			echo "Options:"
			echo "  -h/--help                      Display this help message."
			echo "  -s/--skip section1,section2... Skip the given sections."
			echo "  -k/--keep-tmp                  Do not delete the temporary folder used to"
			echo "                                 store downloaded files."
			echo "  -c/--clean                     Remove any temporary downloaded files or files"
			echo "                                 used to manually merge."
			echo "  -r/--replace                   Always replace downloaded files if there is a"
			echo "                                 different version already present."
			echo "  -n/--no-replace                Never replace downloaded files if there is a"
			echo "                                 different version already present."
			echo
			echo "Sections:"
			echo "  ${ALL_SECTIONS[@]}"
			echo
			exit 0
			;;
		-*)
			echo "Unknown option: $1"
			exit 1
			;;
		*)
			# This allows sections separated by spaces or commas.
			for SECTION in ${1//,/ }; do
				if valid_section "${SECTION}"; then
					SECTIONS+=("${SECTION}")
				else
					echo "Invalid section: ${SECTION}"
					exit 1
				fi
			done
			;;
	esac
	shift
done
if [ "${#SECTIONS[@]}" -eq 0 ]; then
	SECTIONS=("${ALL_SECTIONS[@]}")
fi
for SECTION in "${SKIPPED_SECTIONS[@]}"; do
	for I in "${!SECTIONS[@]}"; do
		if [ "${SECTION}" = "${SECTIONS[${I}]}" ]; then
			unset SECTIONS[${I}]
		fi
	done
done

if [ "${CLEAN}" = "yes" ]; then
	echo -e "\033[37m===>\033[0m CLEAN \033[37m<===\033[0m"
		OLDIFS="${IFS}"
		IFS=$'\n'
		for FILE in $(ls "${INSTALL_LOCATION}"/*.bootstrap 2>/dev/null); do
			echo -e "Removing \033[36;1m${FILE}\033[0m..."
			rm "${FILE}"
		done
		for DIR in $(ls -d "/tmp"/bootstrap* 2>/dev/null); do
			echo -e "Removing \033[36;1m${DIR}\033[0m..."
			rm -rf "${DIR}"
		done
		IFS="${OLDIFS}"
	echo "All files cleaned."
	exit 0
fi

# Output general information about bootstrap.
echo -e "\033[37m>>>>\033[0m BOOTSTRAP \033[37m<<<<\033[0m"
if [ "${#SECTIONS[@]}" -gt 0 ]; then
	echo "Sections: ${SECTIONS[@]}"
else
	echo "No sections will be executed."
	exit 0
fi

# Create temporary directory.
TMP_DIR="$(mktemp -dq /tmp/bootstrap.XXXXXX)"
if [ $? -ne 0 ]; then
	echo "Unable to create temporary directory."
	exit 1
fi
if [ "${KEEP_TMP}" = "no" ]; then
	trap "rm -rf ${TMP_DIR}; exit 0" EXIT SIGINT SIGKILL SIGTERM
fi

if do_section "config"; then
	# Download and install RC files.
	echo
	echo -e "\033[37m===>\033[0m CONFIG FILES \033[37m<===\033[0m"
	for FILE in "${CONFIG_FILES[@]}"; do
		printf "Downloading ${FILE}... "
		if ${DOWNLOAD} "${FILE_LOCATION}/all/${FILE}" ${OUTPUT} "${TMP_DIR}/${FILE}"; then
			echo -e "\033[32mDONE\033[0m"
		else
			echo -e "\033[31mFAILED\033[0m"
			continue
		fi
		install_file "${FILE}" "${INSTALL_LOCATION}"
	done
fi

# OS X specific setup.
if [ "${PLATFORM}" = "OS X" ]; then
	if do_section "config"; then
		# Download and install .profile.
		printf "Downloading .profile... "
		if ${DOWNLOAD} "${FILE_LOCATION}/osx/.profile" ${OUTPUT} "${TMP_DIR}/.profile"; then
			echo -e "\033[32mDONE\033[0m"
			install_file ".profile" "${INSTALL_LOCATION}"
		else
			echo -e "\033[31mFAILED\033[0m"
		fi
	fi

	if do_section "scripts"; then
		# Download and install scripts.
		echo
		echo -e "\033[37m===>\033[0m SCRIPTS \033[37m<===\033[0m"
		OSX_SCRIPTS=("delxattr")
		if [ ! -d "${INSTALL_LOCATION}/Scripts" ]; then
			mkdir -p "${INSTALL_LOCATION}/Scripts"
		fi
		for SCRIPT in "${OSX_SCRIPTS[@]}"; do
			printf "Downloading ${SCRIPT}... "
			if ${DOWNLOAD} "${FILE_LOCATION}/osx/${SCRIPT}" ${OUTPUT} "${TMP_DIR}/${SCRIPT}"; then
				echo -e "\033[32mDONE\033[0m"
				chmod +x "${TMP_DIR}/${SCRIPT}"
				install_file "${SCRIPT}" "${INSTALL_LOCATION}/Scripts"
			else
				echo -e "\033[31mFAILED\033[0m"
			fi
		done
	fi

	if do_section "defaults"; then
		# Set defaults for operating system and applications.
		echo
		echo -e "\033[37m===>\033[0m DEFAULTS \033[37m<===\033[0m"
		printf "Downloading defaults... "
		if ${DOWNLOAD} "${FILE_LOCATION}/osx/defaults" ${OUTPUT} "${TMP_DIR}/defaults"; then
			echo -e "\033[32mDONE\033[0m"
			printf "Setting defaults... "
			bash "${TMP_DIR}/defaults"
			echo -e "\033[32mDONE\033[0m"
			echo "If this is the first time you're setting these defaults, you may need to restart your computer."
		else
			echo -e "\033[31mFAILED\033[0m"
		fi

		# Sets the terminal profile for the fonts installed.
		TERMINAL_PLIST="${HOME}/Library/Preferences/com.apple.Terminal.plist"
		function set_terminal_profile {
			if /usr/libexec/PlistBuddy -c "Print :Window\ Settings:Dark" "${TERMINAL_PLIST}" &>/dev/null; then
				if [ -f "${HOME}/Library/Fonts/FiraMono-Regular.ttf" ]; then
					TERMINAL_PROFILE="Dark"
				else
					TERMINAL_PROFILE="Dark (Monaco)"
				fi
				defaults write com.apple.Terminal "Startup Window Settings" -string "${TERMINAL_PROFILE}"
				defaults write com.apple.Terminal "Default Window Settings" -string "${TERMINAL_PROFILE}"
			fi
		}

		# Download and install terminal profile "Dark" if it doesn't exist, and use this by default.
		# The terminal profile "Dark (Monaco)" is also installed, to be used if the font "Fira Mono" isn't installed.
		if ! /usr/libexec/PlistBuddy -c "Print :Window\ Settings:Dark" "${TERMINAL_PLIST}" &>/dev/null; then
			printf "Downloading terminal profile... "
			if ${DOWNLOAD} "${FILE_LOCATION}/osx/terminal_profile.plist" ${OUTPUT} "${TMP_DIR}/terminal_profile.plist"; then
				echo -e "\033[32mDONE\033[0m"
				printf "Installing terminal profile... "
				/usr/libexec/PlistBuddy -c "Merge ${TMP_DIR}/terminal_profile.plist Window\ Settings" "${TERMINAL_PLIST}" &>/dev/null
				echo -e "\033[32mDONE\033[0m"
				echo "You will have to restart Terminal for the new profile to take effect."
			else
				echo -e "\033[31mFAILED\033[0m"
			fi
		fi
		set_terminal_profile
	fi

	if do_section "fonts"; then
		# Download and install fonts.
		echo
		echo -e "\033[37m===>\033[0m FONTS \033[37m<===\033[0m"
		printf "Downloading font list... "
		if ${DOWNLOAD} "${FILE_LOCATION}/all/fonts" ${OUTPUT} "${TMP_DIR}/fonts"; then
			echo -e "\033[32mDONE\033[0m"
			FONT_DIR="${HOME}/Library/Fonts"
			ALL_FONTS_INSTALLED="yes"
			while read FONT; do
				FONT_NAME=$(echo "${FONT}" | cut -d, -f1)
				FONT_URL=$(echo "${FONT}" | cut -d, -f2)
				FONT_FILE=$(echo "${FONT_URL}" | grep -o "[^/]*$")
				if [ ! -f "${FONT_DIR}/${FONT_FILE}" ]; then
					printf "Downloading ${FONT_NAME}... "
					if ${DOWNLOAD} "${FONT_URL}" ${OUTPUT} "${FONT_DIR}/${FONT_FILE}"; then
						echo -e "\033[32mDONE\033[0m"
					else
						echo -e "\033[31mFAILED\033[0m"
						ALL_FONTS_INSTALLED="no"
					fi
				fi
			done < "${TMP_DIR}/fonts"
			if [ "${ALL_FONTS_INSTALLED}" = "yes" ]; then
				echo "All fonts installed."
			fi
			# Set terminal profile again.
			if do_section "defaults"; then
				set_terminal_profile
			fi
		else
			echo -e "\033[31mFAILED\033[0m"
		fi
	fi

	if do_section "homebrew"; then
		# Check Homebrew status.
		echo
		echo -e "\033[37m===>\033[0m HOMEBREW \033[37m<===\033[0m"
		if command -v brew &>/dev/null; then
			printf "Downloading Homebrew formula list... "
			if ${DOWNLOAD} "${FILE_LOCATION}/osx/homebrew-formulae" ${OUTPUT} "${TMP_DIR}/homebrew-formulae"; then
				echo -e "\033[32mDONE\033[0m"

				# Check for missing formulae.
				brew list > "${TMP_DIR}/homebrew-installed" 2>/dev/null
				FORMULAE_TO_INSTALL=()
				for FORMULA in $(cat "${TMP_DIR}/homebrew-formulae"); do
					LAST_PART=$(echo "${FORMULA}" | grep -o "[^/]*$")
					if ! grep "^${LAST_PART}$" -q "${TMP_DIR}/homebrew-installed"; then
						echo -e "${LAST_PART} is not installed."
						FORMULAE_TO_INSTALL+=("${FORMULA}")
					fi
				done

				if [ ${#FORMULAE_TO_INSTALL[@]} -gt 0 ]; then
					echo -e "You can install the missing formulae with \033[36;1mbrew install ${FORMULAE_TO_INSTALL[@]}\033[0m."
				else
					echo "All formulae installed."
				fi

				# Download cask list if brew-cask is installed.
				INSTALL_CASKS="no"
			else
				echo -e "\033[31mFAILED\033[0m"
			fi

			printf "Downloading Homebrew cask list... "
			if ${DOWNLOAD} "${FILE_LOCATION}/osx/homebrew-casks" ${OUTPUT} "${TMP_DIR}/homebrew-casks"; then
				echo -e "\033[32mDONE\033[0m"

				# Check for missing casks.
				CASKS_TO_INSTALL=()
				brew cask list > "${TMP_DIR}/homebrew-casks-installed" 2>/dev/null
				for CASK in $(cat "${TMP_DIR}/homebrew-casks"); do
					LAST_PART=$(echo "${CASK}" | grep -o "[^/]*$")
					if ! grep "^${LAST_PART}$" -q "${TMP_DIR}/homebrew-casks-installed"; then
						echo -e "${LAST_PART} is not installed."
						CASKS_TO_INSTALL+=("${CASK}")
					fi
				done

				if [ ${#CASKS_TO_INSTALL[@]} -gt 0 ]; then
					echo -e "You can install the missing casks with \033[36;1mbrew cask install ${CASKS_TO_INSTALL[@]}\033[0m."
				else
					echo "All casks installed."
				fi
			else
				echo -e "\033[31mFAILED\033[0m"
			fi

			echo -e "Remember to run \033[36;1mbrew update\033[0m and \033[36;1mbrew upgrade\033[0m regularly."
		else
			echo "Homebrew is not installed; you can install it with the following command."
			echo -e "\033[36;1mruby -e \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)\"\033[0m"
			echo -e "Once installed, don't forget to run \033[36;1mbrew doctor\033[0m and rerun this script."
		fi
	fi
fi

# Linux specific setup.
if [ "${PLATFORM}" = "Linux" ]; then
	if do_section "packages"; then
		# Check Aptitude status.
		echo
		echo -e "\033[37m===>\033[0m PACKAGES \033[37m<===\033[0m"
		if command -v apt-get &>/dev/null; then
			if [ ! -w "/var/lib/dpkg" ]; then
				APT_GET="sudo apt-get"
			else
				APT_GET="apt-get"
			fi
			printf "Downloading Aptitude package list... "
			if ${DOWNLOAD} "${FILE_LOCATION}/linux/aptitude-packages" ${OUTPUT} "${TMP_DIR}/aptitude-packages"; then
				echo -e "\033[32mDONE\033[0m"

				# Check for missing packages.
				dpkg --get-selections | awk '{print $1}' > "${TMP_DIR}/aptitude-installed"
				PACKAGES_TO_INSTALL=()
				for PACKAGE in $(cat "${TMP_DIR}/aptitude-packages"); do
					if ! grep "^${PACKAGE}$" -q "${TMP_DIR}/aptitude-installed"; then
						echo -e "${PACKAGE} is not installed."
						PACKAGES_TO_INSTALL+=("${PACKAGE}")
					fi
				done
				if [ ${#PACKAGES_TO_INSTALL[@]} -gt 0 ]; then
					echo -e "You can install the missing packages with \033[36;1m${APT_GET} install ${PACKAGES_TO_INSTALL[*]}\033[0m."
				else
					echo "All packages installed."
				fi
			else
				echo -e "\033[31mFAILED\033[0m"
			fi
			echo -e "Remember to run \033[36;1m${APT_GET} update\033[0m and \033[36;1m${APT_GET} upgrade\033[0m regularly."
		else
			echo "What package manager are you using?"
		fi
	fi
fi

# Windows specific setup.
if [ "${PLATFORM}" = "Windows" ]; then
	if do_section "config"; then
		# Download and install .profile.
		printf "Downloading .profile... "
		if ${DOWNLOAD} "${FILE_LOCATION}/windows/.profile" ${OUTPUT} "${TMP_DIR}/.profile"; then
			echo -e "\033[32mDONE\033[0m"
			install_file ".profile" "${INSTALL_LOCATION}"
		else
			echo -e "\033[31mFAILED\033[0m"
		fi

		# Download and install git-prompt.sh.
		if [ ! -f "/etc/bash_completion.d/git-prompt.sh" ]; then
			printf "Downloading git-prompt.sh... "
			if ${DOWNLOAD} "https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh" ${OUTPUT} "/etc/bash_completion.d/git-prompt.sh"; then
				echo -e "\033[32mDONE\033[0m"
			else
				echo -e "\033[31mFAILED\033[0m"
			fi
		fi
	fi

	if do_section "fonts"; then
		# Download and install fonts.
		echo
		echo -e "\033[37m===>\033[0m FONTS \033[37m<===\033[0m"
		printf "Downloading font list... "
		if ${DOWNLOAD} "${FILE_LOCATION}/all/fonts" ${OUTPUT} "${TMP_DIR}/fonts"; then
			echo -e "\033[32mDONE\033[0m"
			FONT_DIR=$(cygpath -w "${TMP_DIR}")
			FONT_REG_PATH="HKLM\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Fonts"
			ALL_FONTS_INSTALLED="yes"
			while read FONT; do
				FONT_NAME=$(echo "${FONT}" | cut -d, -f1)
				FONT_URL=$(echo "${FONT}" | cut -d, -f2)
				FONT_FILE=$(echo "${FONT_URL}" | grep -o "[^/]*$")
				FONT_REG_KEY="${FONT_NAME} (TrueType)"
				if ! reg query "${FONT_REG_PATH}" /v "${FONT_REG_KEY}" &>/dev/null; then
					printf "Downloading ${FONT_NAME}... "
					if ${DOWNLOAD} "${FONT_URL}" ${OUTPUT} "${TMP_DIR}/${FONT_FILE}"; then
						echo "CreateObject(\"Shell.Application\").Namespace(\"${FONT_DIR}\").ParseName(\"${FONT_FILE}\").InvokeVerb(\"Install\")" > "${TMP_DIR}/${FONT_FILE}.vbs"
						cscript $(cygpath -w "${TMP_DIR}/${FONT_FILE}.vbs") &>/dev/null
						echo -e "\033[32mDONE\033[0m"
					else
						echo -e "\033[31mFAILED\033[0m"
						ALL_FONTS_INSTALLED="no"
					fi
				fi
			done < "${TMP_DIR}/fonts"
			if [ "${ALL_FONTS_INSTALLED}" = "yes" ]; then
				echo "All fonts installed."
			fi
		else
			echo -e "\033[31mFAILED\033[0m"
		fi
	fi
fi

if do_section "pip"; then
	# Check pip status.
	echo
	echo -e "\033[37m===>\033[0m PIP \033[37m<===\033[0m"

	# Try and find the correct pip command for Python 3.
	PIP=""
	if command -v pip3 &>/dev/null; then
		PIP="pip3"
	elif pip --version 2>/dev/null | grep -q "python3"; then
		PIP="pip"
	fi

	if [ -n "${PIP}" ]; then
		# This can be used when automatically installing packages.
		SITE_PACKAGE_DIR="$(python3 -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())" 2>/dev/null)"
		if [ ! -w "${SITE_PACKAGE_DIR}" ]; then
			PIP="sudo ${PIP}"
		fi
		printf "Downloading pip formula list... "
		if ${DOWNLOAD} "${FILE_LOCATION}/all/pip-packages" ${OUTPUT} "${TMP_DIR}/pip-packages"; then
			echo -e "\033[32mDONE\033[0m"

			# Check for missing packages.
			${PIP} freeze > "${TMP_DIR}/pip-installed"
			PACKAGES_TO_INSTALL=()
			for PACKAGE in $(cat "${TMP_DIR}/pip-packages"); do
				if ! grep "^${PACKAGE}==" -q "${TMP_DIR}/pip-installed"; then
					echo -e "${PACKAGE} is not installed."
					PACKAGES_TO_INSTALL+=("${PACKAGE}")
				fi
			done
			if [ ${#PACKAGES_TO_INSTALL[@]} -gt 0 ]; then
				echo -e "You can install the missing packages with \033[36;1m${PIP} install ${PACKAGES_TO_INSTALL[*]}\033[0m."
			else
				echo "All packages installed."
			fi
		else
			echo -e "\033[31mFAILED\033[0m"
		fi
		echo -e "Remember to run \033[36;1m${PIP} install --upgrade pip\033[0m regularly."
	else
		if [ "${PLATFORM}" = "OS X" ]; then
			echo "pip is not installed; you can install it by updating your version of Python using Homebrew."
		elif [ "${PLATFORM}" = "Windows" ]; then
			echo -e "pip is not installed; you can install it by installing python3-setuptools and running \033[36;1measy_install3.4 pip\033[0m."
		elif [ "${PLATFORM}" = "Linux" ]; then
			echo -e "pip is not installed; you can install it by installing python3-pip."
		fi
		echo -e "Once installed, don't forget to rerun this script."
	fi
fi
