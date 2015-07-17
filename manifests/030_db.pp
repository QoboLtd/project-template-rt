node default {

	# We always need MySQL client
	include '::mysql::client'

	# We always need bindings (dev for CPAN, perl otherwise)
	class { '::mysql::bindings':
		perl_enable => true,
	}

	case $::rt_setup_local_db {
		'yes', '1', 'true': {
			include '::mysql::server'
		}
		default: {
			notice("Skipping local DB setup due to .env settings")
		}
	}

}

