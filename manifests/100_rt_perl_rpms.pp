node default {

	$packageLove = [
		'perl-CPAN',
		'perl-local-lib',

		'perl-Apache-Session',
		'perl-CGI',
		'perl-CGI-Emulate-PSGI',
		'perl-Class-Accessor',
		'perl-Crypt-Eksblowfish',
		'perl-Crypt-SSLeay',
		'perl-CSS-Squish',
		'perl-Date-Manip',
		'perl-DateTime',
		'perl-DateTime-Format-Mail',
		'perl-DateTime-Format-W3CDTF',
		'perl-DateTime-Locale',
		'perl-DBI',
		'perl-Devel-GlobalDestruction',
		'perl-Devel-StackTrace',
		'perl-Encode',
		'perl-Email-Address',
		'perl-FCGI',
		'perl-FCGI-ProcManager',
		'perl-File-ShareDir',
		'perl-File-Which',
		'perl-GD',
		'perl-GraphViz',
		'perl-HTML-FormatText-WithLinks',
		'perl-HTML-FormatText-WithLinks-AndTables',
		'perl-HTML-Scrubber',
		'perl-IPC-Run',
		'perl-IPC-Run3',
		'perl-JSON',
		'perl-List-MoreUtils',
		'perl-Log-Dispatch',
		'perl-LWP-Protocol-https',
		'perl-MIME-Types',
		'perl-Module-Refresh',
		'perl-Module-Versions-Report',
		'perl-Mozilla-CA',
		'perl-Net-CIDR',
		'perl-Plack',
		'perl-Regexp-Common',
		'perl-Regexp-IPv6',
		'perl-String-ShellQuote',
		'perl-Sys-Syslog',
		'perl-Text-Template',
		'perl-Time-HiRes',
		'perl-Time-ParseDate',
		'perl-UNIVERSAL-require',
		'perl-XML-RSS',

	]

	package { $packageLove:
		ensure => 'latest',
	}

}

