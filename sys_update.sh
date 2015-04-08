#!/bin/bash

# Check minimum requirements

if [ "$(hostname)" == "localhost.localdomain" ]
then
	echo "Please set hostname to something more appropriate"
	exit 1
fi

if [[ $EUID -ne 0 ]]
then
	echo "This script is intendent to be run as root"
	exit 1
fi

if [ ! -f ".env" ]
then
	echo "Missing .env configuration file. Try copying .env.example to start"
	exit 1
fi

# Load configuration
source .env

# Setup all dependencies

if [ -z $(rpm -q epel-release) ]
then
	echo Installing EPEL yum repository
	rpm -Uvh http://download.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm
fi

if [ -z $(which puppet) ]
then
	echo puppet not found.  Installing...
	yum install puppet
fi

if [ -z $(which gem) ]
then
	echo gem not found.  Installing...
	yum install gem
fi

if [ -z $(which librarian-puppet) ]
then
	echo librarian-puppet not found.  Installing...
	gem install librarian-puppet
fi

# Run the update process

echo Installing puppet modules
librarian-puppet install

echo Applying puppet manifest
puppet apply --modulepath=modules/ manifests/rt.pp

echo All done.
