node default {
	# Fix annoying deprecated warning
	if versioncmp($::puppetversion,'3.6.1') >= 0 {
		$allow_virtual_packages = hiera('allow_virtual_packages',false)
		Package {
			allow_virtual => $allow_virtual_packages,
		}
	}

	$packageHate = [
		'postfix',
	]

	$packageLove = [
		'exim',
	]

	package { $packageLove:
		ensure => 'latest',
	}

	package { $packageHate:
		ensure => 'purged',
	}

	service { 'exim':
		ensure => 'running',
		enable => true,
		require => Package['exim'],
	}

}
