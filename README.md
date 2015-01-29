DanielGibbsNZ's Bootstrap
=========================

This bootstrap sets up a computer for my use. It installs various configuration files, scripts, programs, utilities, and programming language packages. It can also be used to update the currently installed versions of the config files to the latest versions.

It can be run by downloading and executing the bootstrap script (`bootstrap.sh`):

	wget https://raw.githubusercontent.com/DanielGibbsNZ/bootstrap/master/bootstrap.sh
	bash bootstrap.sh && rm bootstrap.sh

The configuration files can be installed to another directory by using the `-d/--dest` option:

	bash bootstrap.sh -d /home/users/foo
