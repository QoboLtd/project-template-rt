node default {
	case $::rt_setup_firewall {
		'yes', '1', 'true': {

			 Remove all firewall rules, managed by anything other than puppet
			resources { "firewall":
				purge => true
			}

			firewall { '000 accept all ICMP requests':
				proto => 'icmp',
				action => 'accept',
			}
			firewall { '005 accept all on lo':
				proto => 'all',
				iniface => 'lo',
				action => 'accept',
			}
			firewall { '010 accept SSH':
				proto => 'tcp',
				port => 22,
				action => 'accept',
			}
			firewall { '020 accept SMTP':
				proto => 'tcp',
				port => [25, 465, 587],
				action => 'accept',
			}
			firewall { '030 accept HTTP and HTTPS':
				proto => 'tcp',
				port => [80, 443],
				action => 'accept',
			}
			firewall { '999 drop everything else':
				action => 'drop',
			}
		}
		default: {
			notice("Skipping firewall setup due to .env settings")
		}
	}
}
