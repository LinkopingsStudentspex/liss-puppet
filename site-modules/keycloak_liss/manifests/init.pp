# Konfigurerar och installerar Keycloak
class keycloak_liss (
  $batadas_userlookup_url = '',
  $domain = '',
  $fail2ban_bantime = 600,
  $fail2ban_findtime = 600,
  $fail2ban_maxretry = 10,
){
  require keycloak

  exec {'enable password reset for liss realm':
    command     => '/opt/keycloak/bin/kcadm-wrapper.sh update realms/liss -x -s resetPasswordAllowed=true',
    refreshonly => true,
    subscribe   => Keycloak_realm['liss'],
  }

  exec {'enable password reset for master realm':
    command     => '/opt/keycloak/bin/kcadm-wrapper.sh update realms/master -x -s resetPasswordAllowed=true',
    refreshonly => true,
    subscribe   => Keycloak_realm['master'],
  }

  file {'/opt/keycloak/bin/check_user_provider_exists.sh':
    source => 'puppet:///modules/keycloak_liss/check_user_provider_exists.sh',
    mode   => 'a+x',
  }

  exec {'create user storage provider':
    command => "/opt/keycloak/bin/kcadm-wrapper.sh create components -r liss -s name=batadas-user-provider -s providerType=org.keycloak.storage.UserStorageProvider -s providerId=batadas-user-provider -s 'config.baseUserLookupUrl=[\"${batadas_userlookup_url}\"]'",
    onlyif  => '/opt/keycloak/bin/check_user_provider_exists.sh',
    require => File['/opt/keycloak/bin/check_user_provider_exists.sh'],
  }

  file {'/opt/keycloak/themes/liss':
    ensure  => directory,
    recurse => remote,
    source  => 'puppet:///modules/keycloak_liss/themes/liss',
  }

  file {'deploy json module':
    ensure  => directory,
    path    => '/opt/keycloak/modules',
    recurse => remote,
    source  => 'puppet:///modules/keycloak_liss/modules',
  }

  keycloak::spi_deployment{ 'keycloak_batadas_provider-0.3.jar':
    ensure  => present,
    source  => 'puppet:///modules/keycloak_liss/keycloak_batadas_provider-0.3.jar',
    require => File['deploy json module'],
  }

  nginx::resource::server { $domain :
    proxy            => 'http://localhost:8080',
    add_header       => {
      'X-Frame-Options' => 'SAMEORIGIN',
    },
    require          => Class['::base::certificates'],
    ssl_redirect     => true,
    ssl              => true,
    ssl_cert         => '/etc/letsencrypt/live/all-sites/fullchain.pem',
    ssl_key          => '/etc/letsencrypt/live/all-sites/privkey.pem',
    proxy_set_header => [
      'X-Forwarded-Proto $scheme',
      'X-Forwarded-Host $host',
      'X-Forwarded-Server $host',
      'X-Forwarded-for $proxy_add_x_forwarded_for',
    ],
  }

  file {'/etc/fail2ban/filter.d/keycloak.conf':
    ensure  => file,
    source  => 'puppet:///modules/keycloak_liss/fail2ban/keycloak_filter.conf',
    notify  => Service['fail2ban'],
    require => Package['fail2ban'],
  }

  file {'/etc/fail2ban/jail.d/keycloak.conf':
    ensure  => file,
    content => epp('keycloak_liss/keycloak_jail.conf.epp'),
    notify  => Service['fail2ban'],
    require => Package['fail2ban'],
  }
}
