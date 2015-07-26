node default {

	group { $::rt_group:
		ensure => "present",
	}
	user { $::rt_user:
		comment => 'Request Tracker',
		ensure => "present",
		managehome => true,
		groups => [$::rt_group, $::rt_web_group ],
		require => [ Group[$::rt_group], Package["nginx"] ],
	}
	user { $::rt_web_user:
		ensure => "present",
		groups => [$::rt_group, $::rt_web_group],
		require => [ Group[$::rt_group], Package["nginx"] ],
	}

	$packageHate = [
		#'selinux-policy',
		#'selinux-policy-targeted',
	]

	$packageLove = [
		# Things for building RT
		'make',
		'autoconf',
		'gcc',
		'patch',
		'gd-devel',
		'openssl-devel',
		'graphviz',
		# Things for running RT
		'nginx',
		'spawn-fcgi',
		# HTML formatters
		'w3m',
		'elinks',
		'html2text',
		'lynx',
	]

	package { $packageLove:
		ensure => 'latest',
	}

	package { $packageHate:
		ensure => 'purged',
	}

	service { 'nginx':
		ensure => 'running',
		enable => true,
		subscribe => File[ "/etc/nginx/conf.d/${::rt_host}.conf"],
		require => Package['nginx'],
	}

	file { '/etc/nginx/conf.d':
		ensure => directory,

		group => root,
		owner => root,
		recurse => true,

		require => [ Package['nginx'] ],
	}

	file { "/etc/nginx/conf.d/${::rt_host}.conf":
		ensure => present,

		group => root,
		owner => root,
		content => "
			server {
				listen 80;
				server_name ${::rt_host};
				access_log  /var/log/nginx/${::rt_host}-access.log;

				location / {
					fastcgi_param  QUERY_STRING       \$query_string;
					fastcgi_param  REQUEST_METHOD     \$request_method;
					fastcgi_param  CONTENT_TYPE       \$content_type;
					fastcgi_param  CONTENT_LENGTH     \$content_length;

					fastcgi_param  SCRIPT_NAME        '';
					fastcgi_param  PATH_INFO          \$uri;
					fastcgi_param  REQUEST_URI        \$request_uri;
					fastcgi_param  DOCUMENT_URI       \$document_uri;
					fastcgi_param  DOCUMENT_ROOT      \$document_root;
					fastcgi_param  SERVER_PROTOCOL    \$server_protocol;

					fastcgi_param  GATEWAY_INTERFACE  CGI/1.1;
					fastcgi_param  SERVER_SOFTWARE    nginx/\$nginx_version;

					fastcgi_param  REMOTE_ADDR        \$remote_addr;
					fastcgi_param  REMOTE_PORT        \$remote_port;
					fastcgi_param  SERVER_ADDR        \$server_addr;
					fastcgi_param  SERVER_PORT        \$server_port;
					fastcgi_param  SERVER_NAME        \$server_name;
					fastcgi_pass ${::rt_fastcgi_host}:${::rt_fastcgi_port};
				}
			}
		",

		notify => Service['nginx'],
		require => [ File['/etc/nginx/conf.d'] ],
	}

	service { 'spawn-fcgi':
		ensure => 'running',
		enable => true,
		subscribe => [ File[ "/etc/sysconfig/spawn-fcgi"],File["RT_SiteConfig.pm"], Exec["make-install"] ],
		require => [ Package['spawn-fcgi']],
	}

	file { "/home/${::rt_user}":
		ensure => directory,
		group => $::rt_web_group,
		mode => 750,
		require => [ User[$::rt_user], Package['nginx'] ],
	}
		

	file { "/etc/sysconfig/spawn-fcgi":
		ensure => present,

		group => root,
		owner => root,
		# For some reason $::rt_web_user returns 'foobar' here
		content => "OPTIONS=\" -P /var/run/spawn-fcgi.pid -u nginx -g $::rt_web_group -a $::rt_fastcgi_host -p $::rt_fastcgi_port -- ${::rt_current}/sbin/rt-server.fcgi\"",

		notify => Service['spawn-fcgi'],
		require => [ Package['nginx'], Package['spawn-fcgi'], File["/home/${::rt_user}"] ],
	}

	# Get RT from GitHub
	vcsrepo { $::rt_local_repo:
		ensure => present,
		provider => $::rt_remote_vcs,
		source => $::rt_remote_repo,
		revision => $::rt_revision,
		require => User[$::rt_user],
		user => $::rt_user,
	}

	# chown / chgrp
	file { $::rt_local_repo:
		ensure => directory,
		group => $::rt_group,
		owner => $::rt_user,
		recurse => true,
		require => [ User[$::rt_user], Group[$::rt_group], Vcsrepo[$::rt_local_repo] ],
	}


	case $::rt_setup_cpan_modules {
		'yes', '1', 'true': {
			file { $::rt_local_cpan:
				ensure => directory,
				owner => $::rt_user,
				group => $::rt_group,
				require => User[$::rt_user],
			}

			$rt_dependencies = [
				'GD::Graph',
				'CGI::Cookie',
				'CGI::PSGI',
				'Convert::Color',
				'Crypt::X509',
				'Data::GUID',
				'Data::ICal',
				'Date::Extract',
				'DateTime::Format::Natural',
				'DBIx::SearchBuilder',
				'Encode',
				'Email::Address::List',
				'HTML::FormatExternal',
				'HTML::Mason',
				'HTML::Mason::PSGIHandler',
				'HTML::Quoted',
				'HTML::RewriteAttributes',
				'Locale::Maketext::Fuzzy',
				'Locale::Maketext::Lexicon',
				'Mail::Header',
				'Mail::Mailer',
				'MIME::Entity',
				'Module::Util',
				'Net::SSL',
				'PerlIO::eol',
				'Plack::Handler::Starlet',
				'Starlet::Server',
				'Regexp::Common::net::CIDR',
				'Role::Basic',
				'Server::Starter',
				'Symbol::Global::Name',
				'Text::Password::Pronounceable',
				'Text::Quoted',
				'Text::WikiFormat',
				'Text::Wrapper',
				'Tree::Simple',
			]

			cpan { $rt_dependencies: 
				ensure => latest,
				local_lib => $::rt_local_cpan,
				require => [ 
					Package["gcc"], 
					File[$::rt_local_cpan],
				],
			}
		}
		default: {
			notice("Skipping CPAN modules setup due to .env settings")
		}
	}

	# Create ./configure in RT
	exec { 'autoconfig':
		command => 'autoconf',

		path => [ "$::rt_local_repo/", "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ],
		group => $::rt_group,
		user => $::rt_user, 
		cwd => $::rt_local_repo,

		require => [ File[$::rt_local_repo], Package['autoconf'] ],
	}

	# ./configure
	exec { 'configure':
		command => "configure $::rt_configure_options",
		environment => ["PERL=/usr/bin/perl -I${::rt_prefix}/lib -I${::rt_local_cpan}/lib/perl5"],

		path => [ "$::rt_local_repo/", "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ],
		group => $::rt_group,
		user => $::rt_user, 
		cwd => $::rt_local_repo,

		require => Exec['autoconfig'],
	}

	exec { 'make-testdeps':
		command => "make testdeps",

		path => [ "$::rt_local_repo/", "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ],
		group => $::rt_group,
		user => $::rt_user, 
		cwd => $::rt_local_repo,

		require => Exec["configure"],
	}

	# make install as root for chown/chgrp stuff
	exec { 'make-install':
		command => "make install",

		path => [ "$::rt_local_repo/", "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ],
		cwd => $::rt_local_repo,
		user => "root",
		group => "root",

		require => Exec["make-testdeps"],
		notify => Service['spawn-fcgi'],
	}

	$rt_extensions = [
		'RT::Action::AssignUnownedToActor',
		'RT::Extension::ActivityReports',
		'RT::Extension::Gravatar',
	]
	cpan { $rt_extensions:
		ensure => latest,
		local_lib => $::rt_prefix,
		require => Exec['make-install'],
	}

	file { 'RT_SiteConfig.pm':
		path => "$::rt_prefix/etc/RT_SiteConfig.pm",
		content => "
# WARNING: This file is automatically generated by puppet!
#          All changes will be overwritten on next run!
#
# Reference: https://www.bestpractical.com/docs/rt/4.2/RT_Config.html
# 
# RT configuration
Set( \$rtname, '${::rt_name}');
Set( \$Organization, '${::rt_org}');
Set( \$CorrespondAddress, '${::rt_correspond_address}');
Set( \$CommentAddress, '${::rt_comment_address}');
Set( \$WebDomain, '${::rt_host}');

# Database configuration
Set( \$DatabaseHost, '${::rt_db_host}');
Set( \$DatabasePort, '${::rt_db_port}');
Set( \$DatabaseName, '${::rt_db_name}');
Set( \$DatabaseUser, '${::rt_db_user}');
Set( \$DatabasePassword, '${::rt_db_pass}');

# Encryption
Set( %GnuPG, Enable => 0);
Set( %SMIME, Enable => 0);

# Miscelaneous
Set( \$DisplayTicketAfterQuickCreate, 1);
Set( \$HideResolveActionsWithDependencies, 1);
Set( \$UseTransactionBatch, 1);
Set( \$DateDayBeforeMonth, 1);
#Set( \$RestrictReferrer, 0);

# Plugins
Plugin('RT::Action::AssignUnownedToActor');
Plugin('RT::Extension::ActivityReports');
Plugin('RT::Extension::Gravatar');

1;
		",
		notify => Service['spawn-fcgi'],
		require => Exec["make-install"],
	}

	file { $::rt_current:
		ensure => 'link',
		target => $::rt_prefix,
	}

	case $::rt_setup_initdb {
		'yes', '1', 'true': {
			# make initialize-database
			exec { 'make-init-db':
				command => "make initialize-database",

				path => [ "$::rt_local_repo/", "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ],
				group => $::rt_group,
				user => $::rt_user, 
				cwd => $::rt_local_repo,

				require => Exec["make-install"],	
			}
		}
		default: {
			notice("Skipping initialize-database setup due to .env settings")
		}
	}

}

