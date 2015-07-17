#!/bin/bash

# Check minimum requirements

if [ "$(hostname)" == "localhost.localdomain" ]
then
	echo
	echo "Please set hostname to something more appropriate"
	echo
	exit 1
fi

if [[ $EUID -ne 0 ]]
then
	echo
	echo "This script is intendent to be run as root"
	echo
	exit 1
fi

if [ ! -f ".env" ]
then
	echo
	echo "Missing .env configuration file. Try copying .env.example to start"
	echo
	exit 1
fi

# Load configuration
source .env

# Setup all dependencies

if [ -z $(rpm -qa | grep epel-release) ]
then
	echo
	echo Installing EPEL yum repository
	echo
	yum install epel-release
	if [ "$?" -ne 0 ]
	then
		echo
		echo Failed to to install EPEL yum repository ... Aborting.
		echo
		exit 1
	fi
fi

if [ -z $(which puppet 2>/dev/null) ]
then
	echo
	echo puppet not found.  Installing...
	echo
	yum install puppet
	if [ "$?" -ne 0 ]
	then
		echo
		echo Failed to to install puppet ... Aborting.
		echo
		exit 1
	fi
fi

if [ -z $(which gem 2>/dev/null) ]
then
	echo
	echo gem not found.  Installing...
	echo
	yum install gem
	if [ "$?" -ne 0 ]
	then
		echo
		echo Failed to to install gem ... Aborting.
		echo
		exit 1
	fi
fi

if [ -z $(which librarian-puppet 2>/dev/null) ]
then
	echo
	echo librarian-puppet not found.  Installing...
	echo
	gem install librarian-puppet
	if [ "$?" -ne 0 ]
	then
		echo
		echo Failed to to install librarian-puppet ... Aborting.
		echo
		exit 1
	fi
fi

# Run the update process

echo
echo Installing puppet modules
echo
librarian-puppet install

for MANIFEST in $(ls -1 manifests/*.pp)
do
	echo Applying puppet manifest $MANIFEST
	puppet apply --modulepath=modules/ "$MANIFEST"
	if [ "$?" -ne 0 ]
	then
		echo
		echo Failed to apply manifest $MANIFEST ... Aborting.
		echo
		exit 1
	fi
done

echo
echo All done.
echo
