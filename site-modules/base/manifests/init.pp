# Baskonfiguration för servern
class base {
  include unattended_upgrades
  include firewalld
  include telegraf
  contain base::cron

  package {'fail2ban':}

  # Required for telegraf module
  package {'toml-rb':
    ensure   => 'installed',
    provider => 'gem',
  }

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

  # Stop old puppet logs from accruing more than ~6 months. As of
  # 230606 1/3 of the disk space was taken up by puppet logs.
  tidy { 'puppet-log-cleanup':
    path    => "/var/cache/puppet/reports/${facts['fqdn']}",
    age     => '24w',
    recurse => true,
    rmdirs  => false,
    type    => 'ctime',
  }
}
