# Installs mediawiki and sets up basic configuration
class mediawiki::install {
  $mysql_user_str = "${mediawiki::wiki_db_user}@localhost"
  # mysql_user { $mysql_user_str:
  #   ensure   => present,
  #   password_hash => mysql::password($mediawiki::wiki_db_pass),
  # }

  file { '/root/db_pass': content =>  $mediawiki::wiki_db_pass }

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

    $extensions = ['OpenIDConnect', 'PluggableAuth', 'UserMerge']
  $mw_extensions_local_dir = '/opt/mediawiki-extensions'

  # For some reason they stopped tagging releases after 1.35.
  if versioncmp($mediawiki::version_major_minor, '1.35') <= 0 {
    $mw_version_w_underscore = $mediawiki::version_major_minor.regsubst(/\./, '_')
    $extensions_revision = "REL${mw_version_w_underscore}"
  } else {
    $extensions_revision = $mediawiki::version_major_minor ? {
      '1.39'  => '0f35efe7ffb93658b4547d2646a6a192e02f4ea7',
      default => fail('Input a fitting https://github.com/wikimedia/mediawiki-extensions revision into the above table.'),
    }
  }
  vcsrepo { $mw_extensions_local_dir:
    ensure     => present,
    revision   => $extensions_revision,
    source     => 'https://github.com/wikimedia/mediawiki-extensions.git',
    provider   => git,
    submodules => false,
  }
  $extensions.each |$extension| {
    exec { "Fetch extension code for ${extension}":
      command     => "/usr/bin/git -C ${mw_extensions_local_dir} submodule update --init ${extension}",
      refreshonly => true,
      subscribe   => Vcsrepo[$mw_extensions_local_dir];
    }
    file { "${install_path}/extensions/${extension}":
      recurse => true,
      owner   => 'www-data',
      group   => 'www-data',
      source  => "${mw_extensions_local_dir}/${extension}",
      notify  => Exec['run composer'],
      require => Exec["Fetch extension code for ${extension}"];
    }
  }

  file {'/var/www/mediawiki':
    ensure  => link,
    target  => $install_path,
    require => Archive[$archive_name],
  }

  file {'/var/www/mediawiki/cache':
    ensure  => directory,
    owner   => 'www-data',
    group   => 'www-data',
    mode    => '0755',
    require => File['/var/www/mediawiki'],
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
    'imagemagick',
  ]:
  }

  exec {'mediawiki_install_script':
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

  exec { 'run composer':
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
