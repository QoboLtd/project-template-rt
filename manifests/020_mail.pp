node default {

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
