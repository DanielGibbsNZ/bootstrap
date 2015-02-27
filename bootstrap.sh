#!/bin/bash
#
# Bootstrap for my personal settings and configuration files.
#

FILE_LOCATION="https://raw.githubusercontent.com/DanielGibbsNZ/bootstrap/master"
INSTALL_LOCATION="${HOME}"
NANORC_LOCATIONS=("/usr/share/nano" "/usr/local/share/nano")
RC_FILES=(".bashrc" ".vimrc" ".nanorc" ".gitconfig")

# File installation function.
function install_file {
	FILE="$1"
	DEST="$2"
	printf "Installing ${FILE}... "
	if [ -e "${DEST}/${FILE}" ]; then
		# If file already exists check for differences.
		if cmp -s "${DEST}/${FILE}" "${TMP_DIR}/${FILE}"; then
			echo -e "\033[32mDONE\033[0m"
		else
			# If there are differences, ask the user which version they want.
			echo -e "\033[33mEXISTS\033[0m"
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
	else
		cp "${TMP_DIR}/${FILE}" "${DEST}/${FILE}"
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

# Create temporary directory.
TMP_DIR="$(mktemp -dq /tmp/bootstrap.XXXXXX)"
if [ $? -ne 0 ]; then
	echo "Unable to create temporary directory."
	exit 1
fi
trap "rm -rf ${TMP_DIR}; exit 0" EXIT SIGINT SIGKILL SIGTERM

# Download and install RC files.
echo -e "\033[37m===>\033[0m CONFIG FILES \033[37m<===\033[0m"
for FILE in "${RC_FILES[@]}"; do
	printf "Downloading ${FILE}... "
	if ${DOWNLOAD} "${FILE_LOCATION}/${FILE}" ${OUTPUT} "${TMP_DIR}/${FILE}"; then
		echo -e "\033[32mDONE\033[0m"
	else
		echo -e "\033[31mFAILED\033[0m"
		continue
	fi

	# Search for nanorc files and add them to .nanorc.
	if [ "${FILE}" = ".nanorc" ]; then
		for NANORC_LOCATION in "${NANORC_LOCATIONS[@]}"; do
			if [ -d "${NANORC_LOCATION}" ]; then
				echo "" >> "${TMP_DIR}/${FILE}"
				for NANORC_FILE in $(ls "${NANORC_LOCATION}"/*.nanorc 2>/dev/null); do
					echo "include ${NANORC_FILE}" >> "${TMP_DIR}/${FILE}"
				done
			fi
		done
	fi

	install_file "${FILE}" "${INSTALL_LOCATION}"
done

# OS X specific setup.
if [ "${PLATFORM}" = "OS X" ]; then
	# Download and install .profile.
	printf "Downloading .profile... "
	if ${DOWNLOAD} "${FILE_LOCATION}/osx/.profile" ${OUTPUT} "${TMP_DIR}/.profile"; then
		echo -e "\033[32mDONE\033[0m"
		install_file ".profile" "${INSTALL_LOCATION}"
	else
		echo -e "\033[31mFAILED\033[0m"
	fi

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

	# Check Homebrew status.
	echo
	echo -e "\033[37m===>\033[0m HOMEBREW \033[37m<===\033[0m"
	if command -v brew &>/dev/null; then
		printf "Downloading Homebrew formula list... "
		if ${DOWNLOAD} "${FILE_LOCATION}/osx/homebrew-formulae" ${OUTPUT} "${TMP_DIR}/homebrew-formulae"; then
			echo -e "\033[32mDONE\033[0m"

			# Check for missing formulae.
			brew list > "${TMP_DIR}/homebrew-installed"
			if command -v brew-cask &>/dev/null; then
				brew cask list >> "${TMP_DIR}/homebrew-installed"
			fi
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

# Linux specific setup.
if [ "${PLATFORM}" = "Linux" ]; then
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

# Windows specific setup.
if [ "${PLATFORM}" = "Windows" ]; then
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

# Check pip status.
echo
echo -e "\033[37m===>\033[0m PIP \033[37m<===\033[0m"
if command -v python &>/dev/null && command -v pip &>/dev/null; then
	# This can be used when automatically installing packages.
	SITE_PACKAGE_DIR="$(python -c "from distutils.sysconfig import get_python_lib; print get_python_lib()" 2>/dev/null)"
	if [ ! -w "${SITE_PACKAGE_DIR}" ]; then
		PIP="sudo pip"
	else
		PIP="pip"
	fi
	printf "Downloading pip formula list... "
	if ${DOWNLOAD} "${FILE_LOCATION}/pip-packages" ${OUTPUT} "${TMP_DIR}/pip-packages"; then
		echo -e "\033[32mDONE\033[0m"

		# Check for missing packages.
		pip freeze > "${TMP_DIR}/pip-installed"
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
		echo -e "pip is not installed; you can install it by installing python-setuptools and running \033[36;1measy_install2.7 pip\033[0m."
	elif [ "${PLATFORM}" = "Linux" ]; then
		echo -e "pip is not installed; you can install it by installing python-pip."
	fi
	echo -e "Once installed, don't forget to rerun this script."
fi

# Check pip3 status.
echo
echo -e "\033[37m===>\033[0m PIP3 \033[37m<===\033[0m"
if command -v python3 &>/dev/null && command -v pip3 &>/dev/null; then
	# This can be used when automatically installing packages.
	SITE_PACKAGE_DIR="$(python3 -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())" 2>/dev/null)"
	if [ ! -w "${SITE_PACKAGE_DIR}" ]; then
		PIP="sudo pip3"
	else
		PIP="pip3"
	fi
	printf "Downloading pip3 formula list... "
	if ${DOWNLOAD} "${FILE_LOCATION}/pip3-packages" ${OUTPUT} "${TMP_DIR}/pip3-packages"; then
		echo -e "\033[32mDONE\033[0m"

		# Check for missing packages.
		pip3 freeze > "${TMP_DIR}/pip3-installed"
		PACKAGES_TO_INSTALL=()
		for PACKAGE in $(cat "${TMP_DIR}/pip3-packages"); do
			if ! grep "^${PACKAGE}==" -q "${TMP_DIR}/pip3-installed"; then
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
		echo "pip3 is not installed; you can install it by updating your version of Python using Homebrew."
	elif [ "${PLATFORM}" = "Windows" ]; then
		echo -e "pip3 is not installed; you can install it by installing python3-setuptools and running \033[36;1measy_install3.4 pip\033[0m."
	elif [ "${PLATFORM}" = "Linux" ]; then
		echo -e "pip3 is not installed; you can install it by installing python3-pip."
	fi
	echo -e "Once installed, don't forget to rerun this script."
fi

# Tidy up.
rm -rf "${TMP_DIR}"
