# Installs mediawiki and sets up basic configuration
class mediawiki::install {
  mysql::db { $mediawiki::wiki_db_name:
    user     => $mediawiki::wiki_db_user,
    password => $mediawiki::wiki_db_pass,
  }

  # Dummy file to make logrotate script happy
  file {'/etc/mysql/debian.cnf':
    ensure => present,
  }

  $archive_name = "mediawiki-${mediawiki::version_major_minor}.${mediawiki::version_patch}"
  $archive_source = "https://releases.wikimedia.org/mediawiki/${mediawiki::version_major_minor}/${archive_name}.tar.gz"
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
    command => "php install.php --dbname ${mediawiki::wiki_db_name} --dbuser ${mediawiki::wiki_db_user} --dbpass \"${mediawiki::wiki_db_pass}\" --dbserver ${mediawiki::wiki_db_host} --extensions WikiEditor,Renameuser,PdfHandler,UserMerge,PluggableAuth,OpenIDConnect --lang sv --scriptpath \"\" --pass \"${mediawiki::wiki_admin_pass}\" \"${mediawiki::wiki_title}\" ${mediawiki::wiki_admin_user }",
    cwd     => '/var/www/mediawiki/maintenance',
    creates => '/var/www/mediawiki/LocalSettings.php',
    path    => '/usr/bin',
    require => Package['php', 'php-mysql'],
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
}
