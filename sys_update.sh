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

if [ -z $(rpm -qa | grep epel-release) ]
then
	echo Installing EPEL yum repository
	yum install epel-release
fi

if [ -z $(which puppet 2>/dev/null) ]
then
	echo puppet not found.  Installing...
	yum install puppet
fi

if [ -z $(which gem 2>/dev/null) ]
then
	echo gem not found.  Installing...
	yum install gem
fi

if [ -z $(which librarian-puppet 2>/dev/null) ]
then
	echo librarian-puppet not found.  Installing...
	gem install librarian-puppet
fi

# Run the update process

echo Installing puppet modules
librarian-puppet install

for MANIFEST in $(ls -1 manifests/*.pp)
do
	echo Applying puppet manifest $MANIFEST
	puppet apply --modulepath=modules/ "$MANIFEST"
	if [ "$?" -ne 0 ]
	then
		echo Failed to apply manifest $MANIFEST ... Aborting.
		exit 1
	fi
done

echo All done.
