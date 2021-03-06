node default {
	# Fix annoying deprecated warning
	if versioncmp($::puppetversion,'3.6.1') >= 0 {
		$allow_virtual_packages = hiera('allow_virtual_packages',false)
		Package {
			allow_virtual => $allow_virtual_packages,
		}
	}

	# We always need MySQL client
	include '::mysql::client'

	# We always need bindings (dev for CPAN, perl otherwise)
	class { '::mysql::bindings':
		perl_enable => true,
	}

	# If rt_db_host is local, setup the database server also
	case $::rt_db_host {
		'', 'localhost', 'localhost.localdomain', '127.0.0.1', $fqdn: {
			include '::mysql::server'
		}
		default: {
			notice("Skipping DB server setup due to non local db_host [${::rt_db_host}]")
		}
	}

}

