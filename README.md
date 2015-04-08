project-template-rt
===================

This is a template project for RT installations.

Overview
--------

We are using the following components:

* CentOS 7
* EPEL yum repository, for puppet and such
* Puppet configuration manager with masterless setup
* Ruby gems, for librarian-puppet
* Librarian-puppet, for puppet module management
* Request Tracker 4.2

Usage
-----

Everything is setup, configured and started automagically, using
the ```sys_update.sh``` script in the root folder of the project.

In order for this to work though, a few assumption must be true.

Assumptions
-----------

* The setup and configuration is executed by user root.
* Server's hostname is the FQDN on which the RT will run.
* Server has access to the Internet, for git, puppet, perl and yum dependencies.
* Server will run all necessary parts locally - web, database, and mail software.
* No other critical software runs on the server.

Configuration
-------------

Most things should just work.  When something doesn't work, a helpful
error message is usually given.  Certain things can (and should) be 
adjusted using the ```.env``` configuration file in the root folder
of the project.  For convenience, ```.env.example``` file is provided
with sensible defaults.

Some of the things that can be adjusted are:

* User and group under which RT will run
* Installation location for RT 
* Whether or not to install CPAN modules for RT dependencies
* Whether or not tweak the network firewall
* Whether or not to install local database
* Whether or not to initialize the database with some data
* spawn-fcgi location

Known Issues
------------

* CPAN related errors during module installation.  These are caused by some weirdness Plack::Handler::Starlet module.  This should be sorted out sooner or later.
* spawn-fcgi service fails to start, due to "address already in use" error. This happens because service stop functionality doesn't work properly.  To be investigated and fixed shortly.
* web user and group are hardcoded into ```/etc/sysconfig/spawn-fcgi``` due to $::rt_web_user returning string 'foobar' for some weird reason.  To be investigated and fixed shortly.
* Database initialization might fail, due to the 'database already exists' error.  Whether or not database should be initialized is controled via the configuration file.

TODO
----

* Move Nginx configuration into one of the available puppet modules
* Finalize configuration of the RT itself
* Make it possible to update RT configuration and database without rebuilding everything
* Configure MySQL database backups to go into the RT folder for easier restores
* Provide Vagrantfile configuration for easier development and testing

