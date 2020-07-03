$organization_domain = lookup('organization_domain')
$smtp_host = lookup('smtp_host')
$smtp_user = lookup('smtp_user')
$smtp_password = lookup('smtp_password')
$smtp_port = lookup('smtp_port')
$keycloak_auth_url = lookup('keycloak_auth_url')

node default {
  include internsidor
  include keycloak_liss
  include mediawiki
  include postfix

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
}
