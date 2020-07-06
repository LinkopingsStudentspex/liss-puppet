# Baskonfiguration för servern
class base {
  include unattended_upgrades
  include firewalld

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

  package {'moreutils':}

  # Here we assume that puppet-update.sh will be in /etc/puppet/code.
  # Using chronic to only show output after failures to avoid email noise from stderr.
  cron {'puppet-update':
    command => 'chronic /etc/puppet/code/puppet-update.sh',
    user    => 'root',
    minute  => '16',
    require => Package['moreutils'],
  }
}
