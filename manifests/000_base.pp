node default {

	# Don't go too far for the hostname
	host { $::rt_host:
		ip => '127.0.0.1',
	}

	class { 'selinux':
		mode => 'disabled',
	}

	$packageHate = [
		#'selinux-policy',
		#'selinux-policy-targeted',
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
		'bzip2',
		'gzip',
		'tar',
		'less',
		'wget',
	]

	package { $packageLove:
		ensure => 'latest',
	}

	package { $packageHate:
		ensure => 'purged',
	}
}

