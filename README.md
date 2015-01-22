DanielGibbsNZ's Bootstrap
=========================

This bootstrap installs various configuration files to set up a computer for my use. It can also be used to update the currently installed versions of the config files to the latest versions.

It can be run by downloading and executing the bootstrap script (`bootstrap.sh`):

	wget https://raw.githubusercontent.com/DanielGibbsNZ/bootstrap/master/bootstrap.sh
	bash bootstrap.sh && rm bootstrap.sh

An easier invocation would be the following but the scripts loop forever on the interactive portions:

	curl -fsL https://raw.githubusercontent.com/DanielGibbsNZ/bootstrap/master/bootstrap.sh | bash

The configuration files can be installed to another directory by using the `-d/--dest` option:

	bash bootstrap.sh -d /home/users/foo
