node default {

	# Don't go too far for the hostname
	host { $fqdn:
		ip => '127.0.0.1',
	}

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

	class { 'selinux':
		mode => 'disabled',
	}

	$packageHate = [
		#'selinux-policy',
		#'selinux-policy-targeted',
		'postfix',
	]

	$packageLove = [
		# Making life easy
		'git',
		'ack',
		'htop',
		'screen',
		'mc',
		'vim-enhanced',
		'ctags',
		'telnet',
		'links',
		'bash-completion.noarch',
		# Things for building RT
		'bzip2',
		'gzip',
		'tar',
		'gnupg2',
		'make',
		'autoconf',
		'gcc',
		'less',
		'patch',
		'wget',
		'perl-CPAN',
		'perl-local-lib',
		'perl-GD',
		'gd-devel',
		'openssl-devel',
		'graphviz',
		'perl-GraphViz',
		'perl-Encode',
		# Things for running RT
		'nginx',
		'spawn-fcgi',

		'exim',
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
		subscribe => File[ "/etc/nginx/conf.d/${::fqdn}.conf"],
		require => Package['nginx'],
	}

	file { '/etc/nginx/conf.d':
		ensure => directory,

		group => root,
		owner => root,
		recurse => true,

		require => [ Package['nginx'] ],
	}

	file { "/etc/nginx/conf.d/${::fqdn}.conf":
		ensure => present,

		group => root,
		owner => root,
		content => "
			server {
				listen 80;
				server_name ${::fqdn};
				access_log  /var/log/nginx/${::fqdn}-access.log;

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
		content => "OPTIONS=\" -P /var/run/spawn-fcgi.pid -u nginx -g $::rt_web_group -a $::rt_fastcgi_host -p $::rt_fastcgi_port -- ${::rt_prefix}/sbin/rt-server.fcgi\"",

		notify => Service['spawn-fcgi'],
		require => [ Package['nginx'], Package['spawn-fcgi'], File["/home/${::rt_user}"] ],
	}

	service { 'exim':
		ensure => 'running',
		enable => true,
		require => Package['exim'],
	}


	# We always need MySQL client
	#class { '::mysql::client': }
	include '::mysql::client'

	# We always need bindings (dev for CPAN, perl otherwise)
	class { '::mysql::bindings':
		perl_enable => true,
	}

	case $::rt_setup_local_db {
		'yes', '1', 'true': {
			#class { '::mysql::server': }
			include '::mysql::server'
		}
		default: {
			notice("Skipping local DB setup due to .env settings")
		}
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
				'Apache::Session',
				'CGI',
				'CGI::Cookie',
				'CGI::Emulate::PSGI',
				'CGI::PSGI',
				'Class::Accessor',
				'Convert::Color',
				'Crypt::Eksblowfish',
				'Crypt::SSLeay',
				'Crypt::X509',
				'CSS::Squish',
				'Data::GUID',
				'Data::ICal',
				'Date::Extract',
				'Date::Manip',
				'DateTime',
				'DateTime::Format::Natural',
				'DateTime::Locale',
				#'DBD::mysql',
				'DBI',
				'DBIx::SearchBuilder',
				'Devel::GlobalDestruction',
				'Devel::StackTrace',
				'Email::Address',
				'Email::Address::List',
				'Encode',
				'FCGI',
				'FCGI::ProcManager',
				'File::ShareDir',
				'File::Which',
				'GD',
				'GD::Graph',
				'GD::Text',
				'GnuPG::Interface',
				'GraphViz',
				'HTML::FormatText::WithLinks',
				'HTML::FormatText::WithLinks::AndTables',
				'HTML::Mason',
				'HTML::Mason::PSGIHandler',
				'HTML::Quoted',
				'HTML::RewriteAttributes',
				'HTML::Scrubber',
				'IPC::Run',
				'IPC::Run3',
				'JSON',
				'List::MoreUtils',
				'Locale::Maketext::Fuzzy',
				'Locale::Maketext::Lexicon',
				'Log::Dispatch',
				'LWP::Protocol::https',
				'Mail::Header',
				'Mail::Mailer',
				'MIME::Entity',
				'MIME::Types',
				'Module::Refresh',
				'Module::Versions::Report',
				'Mozilla::CA',
				'Net::CIDR',
				'Net::SSL',
				'PerlIO::eol',
				'Plack',
				'Plack::Handler::Starlet',
				'Starlet',
				'Regexp::Common',
				'Regexp::Common::net::CIDR',
				'Regexp::IPv6',
				'Role::Basic',
				'Server::Starter',
				'String::ShellQuote',
				'Symbol::Global::Name',
				'Sys::Syslog',
				'Text::Password::Pronounceable',
				'Text::Quoted',
				'Text::Template',
				'Text::WikiFormat',
				'Text::Wrapper',
				'Time::HiRes',
				'Time::ParseDate',
				'Tree::Simple',
				'UNIVERSAL::require',
				'XML::RSS',

				'DateTime::Format::Mail',
				'DateTime::Format::W3CDTF',
			]

			cpan { $rt_dependencies: 
				ensure => latest,
				local_lib => $::rt_local_cpan,
				require => [ 
					Package["gcc"], 
					Package["perl-local-lib"], 
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
		environment => ["PERL=/usr/bin/perl -I${::rt_local_cpan}/lib/perl5"],

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

	file { 'RT_SiteConfig.pm':
		path => "$::rt_prefix/etc/RT_SiteConfig.pm",
		content => "
Set( \$rtname, '$::fqdn');
Set(@ReferrerWhitelist, qw($::fqdn:443  $::fqdn:80 127.0.0.1:80));
1;
		",
		notify => Service['spawn-fcgi'],
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

