#!/bin/bash
#
# Bootstrap for my personal settings and configuration files.
#

FILE_LOCATION="https://raw.githubusercontent.com/DanielGibbsNZ/bootstrap/master"
INSTALL_LOCATION=${HOME}
NANORC_LOCATIONS=("/usr/share/nano" "/usr/local/share/nano")
RC_FILES=(".bashrc" ".vimrc" ".nanorc" ".gitconfig")

# File installation function.
function install_file {
	FILE=$1
	DEST=$2
	printf "Installing ${FILE}... "
	if [ -e ${DEST}/${FILE} ]; then
		# If file already exists check for differences.
		if cmp -s ${DEST}/${FILE} /tmp/${FILE}; then
			echo -e "\033[32mDONE\033[0m"
		else
			# If there are differences, ask the user which version they want.
			echo -e "\033[33mEXISTS\033[0m"
			REPLACE=""
			while [ "${REPLACE}" != "y" -a "${REPLACE}" != "n" ]; do
				read -p "Replace original file (d for diff)? (y/n/d) " REPLACE
				if [ "${REPLACE}" = "d" ]; then
					${DIFF} ${DEST}/${FILE} /tmp/${FILE} | less -r
				fi
			done
			if [ "${REPLACE}" = "y" ]; then
				mv /tmp/${FILE} ${DEST}/${FILE}
			else
				echo "The downloaded version of ${FILE} can be found in /tmp/${FILE} for manual merging."
			fi
		fi
	else
		mv /tmp/${FILE} ${DEST}/${FILE}
		echo -e "\033[32mDONE\033[0m"
	fi
}

# Process arguments.
if [ "$1" = "-d" -o "$1" = "--dest" ]; then
	if [ "$2" -a -d "$2" ]; then
		INSTALL_LOCATION=$2
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

# Download and install RC files.
echo -e "\033[30;1m===>\033[0m CONFIG FILES \033[30;1m<===\033[0m"
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

	install_file ${FILE} ${INSTALL_LOCATION}
done

# OS X specific setup.
if [ "${PLATFORM}" = "OS X" ]; then
	# Download and install .profile.
	printf "Downloading .profile... "
	if ${DOWNLOAD} ${FILE_LOCATION}/osx/.profile ${OUTPUT} /tmp/.profile; then
		echo -e "\033[32mDONE\033[0m"
		install_file .profile ${INSTALL_LOCATION}
	else
		echo -e "\033[31mFAILED\033[0m"
	fi

	# Download and install scripts.
	echo
	echo -e "\033[30;1m===>\033[0m SCRIPTS \033[30;1m<===\033[0m"
	OSX_SCRIPTS=("delxattr")
	if [ ! -d ${INSTALL_LOCATION}/Scripts ]; then
		mkdir -p ${INSTALL_LOCATION}/Scripts
	fi
	for SCRIPT in ${OSX_SCRIPTS[*]}; do
		printf "Downloading ${SCRIPT}... "
		if ${DOWNLOAD} ${FILE_LOCATION}/osx/${SCRIPT} ${OUTPUT} /tmp/${SCRIPT}; then
			echo -e "\033[32mDONE\033[0m"
			chmod +x /tmp/${SCRIPT}
			install_file ${SCRIPT} ${INSTALL_LOCATION}/Scripts
		else
			echo -e "\033[31mFAILED\033[0m"
		fi
	done

	# Check Homebrew status.
	echo
	echo -e "\033[30;1m===>\033[0m HOMEBREW \033[30;1m<===\033[0m"
	if command -v brew &>/dev/null; then
		printf "Downloading Homebrew formula list... "
		if ${DOWNLOAD} ${FILE_LOCATION}/osx/homebrew-formulae ${OUTPUT} /tmp/homebrew-formulae; then
			echo -e "\033[32mDONE\033[0m"

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

# Check pip status.
echo
echo -e "\033[30;1m===>\033[0m PIP \033[30;1m<===\033[0m"
if command -v python &>/dev/null && command -v pip &>/dev/null; then
	# This can be used when automatically installing packages.
	SITE_PACKAGE_DIR=$(python -c "from distutils.sysconfig import get_python_lib; print get_python_lib()" &>/dev/null)
	if [ ! -w ${SITE_PACKAGE_DIR} ]; then
		PIP="sudo pip"
	else
		PIP="pip"
	fi
	printf "Downloading pip formula list... "
	if ${DOWNLOAD} ${FILE_LOCATION}/pip-packages ${OUTPUT} /tmp/pip-packages; then
		echo -e "\033[32mDONE\033[0m"

		# Check for missing packages.
		pip freeze > /tmp/pip-installed
		PACKAGES_TO_INSTALL=()
		for PACKAGE in $(cat /tmp/pip-packages); do
			if ! grep "^${PACKAGE}==" -q /tmp/pip-installed; then
				echo -e "${PACKAGE} is not installed."
				PACKAGES_TO_INSTALL+=("${PACKAGE}")
			fi
		done
		rm -f /tmp/pip-packages /tmp/pip-installed
		if [ ${#PACKAGES_TO_INSTALL[@]} -gt 0 ]; then
			echo
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
		echo "Pip is not installed; you can install it by updating your version of Python using Homebrew."
	elif [ "${PLATFORM}" = "Windows" ]; then
		echo -e "Pip is not installed; you can install it by installing python-setuptools and running \033[36;1measy_install2.7 pip\033[0m."
	elif [ "${PLATFORM}" = "Linux" ]; then
		echo -e "Pip is not installed; you can install it by installing python-pip."
	fi
	echo -e "Once installed, don't forget to rerun this script."
fi

# Check pip3 status.
echo
echo -e "\033[30;1m===>\033[0m PIP3 \033[30;1m<===\033[0m"
if command -v python3 &>/dev/null && command -v pip3 &>/dev/null; then
	# This can be used when automatically installing packages.
	SITE_PACKAGE_DIR=$(python3 -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())" &>/dev/null)
	if [ ! -w ${SITE_PACKAGE_DIR} ]; then
		PIP="sudo pip3"
	else
		PIP="pip3"
	fi
	printf "Downloading pip3 formula list... "
	if ${DOWNLOAD} ${FILE_LOCATION}/pip3-packages ${OUTPUT} /tmp/pip3-packages; then
		echo -e "\033[32mDONE\033[0m"

		# Check for missing packages.
		pip3 freeze > /tmp/pip3-installed
		PACKAGES_TO_INSTALL=()
		for PACKAGE in $(cat /tmp/pip3-packages); do
			if ! grep "^${PACKAGE}==" -q /tmp/pip3-installed; then
				echo -e "${PACKAGE} is not installed."
				PACKAGES_TO_INSTALL+=("${PACKAGE}")
			fi
		done
		rm -f /tmp/pip3-packages /tmp/pip3-installed
		if [ ${#PACKAGES_TO_INSTALL[@]} -gt 0 ]; then
			echo
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
		echo "Pip3 is not installed; you can install it by updating your version of Python using Homebrew."
	elif [ "${PLATFORM}" = "Windows" ]; then
		echo -e "Pip3 is not installed; you can install it by installing python3-setuptools and running \033[36;1measy_install3.4 pip\033[0m."
	elif [ "${PLATFORM}" = "Linux" ]; then
		echo -e "Pip3 is not installed; you can install it by installing python3-pip."
	fi
	echo -e "Once installed, don't forget to rerun this script."
fi
