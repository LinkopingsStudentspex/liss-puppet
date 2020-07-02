# Konfigurerar och installerar Keycloak
class keycloak_liss (
  $domain = '',
  $email_from_addr = "root@${::organization_domain}",
  $email_from_name = 'Spexets internsidor',
  $smtp_auth = true,
  $smtp_ssl = true,
  $smtp_starttls = true,
  $batadas_userlookup_url = ''
){
  include keycloak
  keycloak_realm { 'liss':
    remember_me                  => true,
    login_theme                  => 'liss',
    display_name                 => 'Linköpings Studentspex',
    internationalization_enabled => true,
    supported_locales            => ['sv', 'en'],
  }

  exec {'update realm':
    command => "/opt/keycloak/bin/kcadm-wrapper.sh update realms/liss -x -s resetPasswordAllowed=true -s \"smtpServer.host=${::smtp_host}\" -s smtpServer.port=${::smtp_port} -s \"smtpServer.from=${email_from_addr}\" -s \"smtpServer.fromDisplayName=${email_from_name}\" -s \"smtpServer.auth=${smtp_auth}\" -s \"smtpServer.ssl=${smtp_ssl}\" -s \"smtpServer.starttls=${smtp_starttls}\" -s \"smtpServer.user=${::smtp_user}\" -s \"smtpServer.password=${::smtp_password}\""
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
    proxy      => 'http://localhost:8080',
    add_header => {
      'X-Frame-Options' => 'SAMEORIGIN',
    },
  }
}
