# Konfigurerar och installerar Mediawiki
class mediawiki (
  $admin_email = "root@${::organization_domain}",
  $baseurl = '',
  $domain = '',
  $oidc_clientid = 'mediawiki',
  $oidc_clientsecret = '',
  $secretkey = '',
  $upgradekey = '',
  $version_major_minor = '',
  $version_patch = '',
  $wiki_admin_pass = '',
  $wiki_admin_user = 'admin',
  $wiki_db_host = 'localhost',
  $wiki_db_name = 'wikdb',
  $wiki_db_pass = '',
  $wiki_db_user = 'wikiuser',
  $wiki_title = 'Internwiki',

) {
  require mysql::server

  mysql::db { $wiki_db_name:
    user     => $wiki_db_user,
    password => $wiki_db_pass,
  }

  keycloak_client { $oidc_clientid:
    realm                 => 'liss',
    secret                => $oidc_clientsecret,
    redirect_uris         => ["http://${domain}/*"],
    default_client_scopes => ['profile', 'email'],
  }

  $archive_name = "mediawiki-${version_major_minor}.${version_patch}"
  $archive_source = "https://releases.wikimedia.org/mediawiki/${version_major_minor}/${archive_name}.tar.gz"
  $install_path = "/opt/${archive_name}"
  file {$install_path:
    ensure => directory,
    owner  => 'www-data',
    group  => 'www-data',
  }

  archive {$archive_name:
    path         => "/tmp/${archive_name}.tar.gz",
    source       => $archive_source,
    extract      => true,
    extract_path => '/opt',
    creates      => "${install_path}/index.php",
    user         => 'www-data',
    group        => 'www-data',
  }

  dirtree { "${install_path}/skins/common/images":
    ensure  => 'present',
    parents => true,
  }

  file { "${install_path}/skins/common/images/lisse.png":
    source  => 'puppet:///modules/mediawiki/lisse.png',
    require => Dirtree["${install_path}/skins/common/images"],
  }


  $archive_name_oidc = 'OpenIDConnect-REL1_34-1db264d.tar.gz'
  archive {'OpenIDConnect':
    path         => "/tmp/${archive_name_oidc}",
    source       => "puppet:///modules/mediawiki/extensions/${archive_name_oidc}",
    extract      => true,
    extract_path => "${install_path}/extensions",
    creates      => "${install_path}/extensions/OpenIDConnect",
  }

  $archive_name_pluggableauth = 'PluggableAuth-REL1_34-17fb1ea.tar.gz'
  archive {'PluggableAuth':
    path         => "/tmp/${archive_name_pluggableauth}",
    source       => "puppet:///modules/mediawiki/extensions/${archive_name_pluggableauth}",
    extract      => true,
    extract_path => "${install_path}/extensions",
    creates      => "${install_path}/extensions/PluggableAuth",
  }

  $archive_name_usermerge = 'UserMerge-REL1_34-3517022.tar.gz'
  archive {'UserMerge':
    path         => "/tmp/${archive_name_usermerge}",
    source       => "puppet:///modules/mediawiki/extensions/${archive_name_usermerge}",
    extract      => true,
    extract_path => "${install_path}/extensions",
    creates      => "${install_path}/extensions/UserMerge",
  }

  file {'/var/www/mediawiki':
    ensure  => link,
    target  => $install_path,
    require => Archive[$archive_name],
  }

  package {[
    'php',
    'php-apcu',
    'php-curl',
    'php-fpm',
    'php-intl',
    'php-mbstring',
    'php-xml',
    'php-mysql',
    'python3-pymysql',
  ]:
  }

  exec {'run install script':
    command => "php install.php --dbname ${wiki_db_name} --dbuser ${wiki_db_user} --dbpass \"${wiki_db_pass}\" --dbserver ${wiki_db_host} --extensions WikiEditor,Renameuser,PdfHandler,UserMerge,PluggableAuth,OpenIDConnect --lang sv --scriptpath \"\" --pass \"${wiki_admin_pass}\" \"${wiki_title}\" ${wiki_admin_user }",
    cwd     => '/var/www/mediawiki/maintenance',
    creates => '/var/www/mediawiki/LocalSettings.php',
    path    => '/usr/bin',
    require => Package['php', 'php-mysql'],
  }

  file {'/var/www/mediawiki/LocalSettings.php':
    ensure  => file,
    content => epp('mediawiki/LocalSettings.php.epp'),
  }

  file {'/var/www/mediawiki/composer.local.json':
    source  => 'puppet:///modules/mediawiki/composer.local.json',
    require => File['/var/www/mediawiki'],
    notify  => Exec['run composer'],
  }

  include php
  include php::composer

  exec {'run composer':
    command     => 'composer install --no-dev --no-scripts',
    cwd         => '/var/www/mediawiki',
    path        => '/usr/local/bin:/usr/bin',
    user        => 'www-data',
    group       => 'www-data',
    environment => ['COMPOSER_HOME=/tmp/composer_home'],
    refreshonly => true,
    require     => Class['php::composer'],
  }


  include php::fpm

  nginx::resource::server { $domain:
    www_root    => '/var/www/mediawiki/',
    index_files => ['index.php'],
  }

  nginx::resource::location{'mediawiki':
    server             => $domain,
    www_root           => '/var/www/mediawiki/',
    location           => '~ \.php$',
    fastcgi_param      => {
      'SCRIPT_FILENAME' => '$document_root$fastcgi_script_name',
    },
    fastcgi_split_path => '^(.+\.php)(/.+)$',
    fastcgi            => '127.0.0.1:9000',
    index_files        => [],
  }

  nginx::resource::location { 'files':
    location    => '~* \.(js|css|png|jpg|jpeg|gif|ico)$',
    www_root    => '/var/www/mediawiki/',
    server      => $domain,
    index_files => [],
  }

  nginx::resource::location { 'maintenance':
    location            => '^~ /maintenance/',
    server              => $domain,
    index_files         => [],
    location_custom_cfg => {
      'return' => '403',
    },
  }

  nginx::resource::location { 'denial':
    location            => '^~ ^/(cache|includes|maintenance|languages|serialized|tests|images/deleted)/',
    server              => $domain,
    index_files         => [],
    location_custom_cfg => {
      'deny' => 'all',
    },
  }
}
