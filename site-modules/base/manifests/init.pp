# Baskonfiguration för servern
class base {
  include firewalld
  firewalld_service { ['ssh', 'http']: }

  package {'fail2ban':}

  file {'/etc/fail2ban/jail.local':
    ensure  => file,
    source  => 'puppet:///modules/base/jail.local',
    require => Package['fail2ban'],
  }

  service {'fail2ban':
    ensure  => running,
    require => [
      Package['fail2ban'],
      File['/etc/fail2ban/jail.local'],
    ],
  }

  #Here we assume that puppet-update.sh will be in /etc/puppet/code
  cron {'puppet-update':
    command => '/etc/puppet/code/puppet-update.sh',
    user    => 'root',
    # Temporary short interval for testing
    minute  => '*/5',
  }
}
