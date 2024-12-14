# Installs the application
class internsidor::install {

  postgresql::server::db {$internsidor::django_db_name:
    user     => $internsidor::django_db_user,
    password => $internsidor::django_db_pass,
    encoding => 'UTF-8',
  }

  class { 'python':
    version    => '3',
    pip        => present,
    virtualenv => present,
  }

  vcsrepo { $internsidor::project_path:
    ensure   => latest,
    provider => git,
    source   => 'https://github.com/linkopingsstudentspex/internsidor.git',
    notify   => [
      Service['internsidor-gunicorn'],
      Service['lissmilter'],
      Service['recipient-lookup'],
      Exec['migrate django database'],
      Exec['collect static files'],
    ]
  }

  exec {'migrate django database':
    command     => "${internsidor::venv_path}/bin/python manage.py migrate --settings=internsidor.settings.production",
    cwd         => $internsidor::project_path,
    subscribe   => Postgresql::Server::Db[$internsidor::django_db_name],
    refreshonly => true,
  }

  exec {'collect static files':
    command     => "${internsidor::venv_path}/bin/python manage.py collectstatic --settings=internsidor.settings.production --no-input",
    cwd         => $internsidor::project_path,
    user        => 'www-data',
    refreshonly => true,
    require     => [
       Python::Requirements[
         "${internsidor::project_path}/requirements-prod.txt",
       ],
      File[$internsidor::static_files_path],
    ],
  }

  python::virtualenv { $internsidor::venv_path:
    version => '3',
  }

  # Apparently the bundled setuptools version is too old
  python::pip {'setuptools':
    ensure => latest,
  }

  python::requirements  { "${internsidor::project_path}/requirements-prod.txt":
    virtualenv   => $internsidor::venv_path,
    pip_provider => pip3,
    require      => [
      Python::Virtualenv[$internsidor::venv_path],
      Python::Pip['setuptools'],
    ],
    subscribe    => Vcsrepo[$internsidor::project_path],
    forceupdate  => true,
  }

  package {[
    'python3-psycopg2',
    'libmilter-dev',
    'libsasl2-modules',
    'libpq-dev',
  ]:}

  python::pip {'psycopg2':
    virtualenv => $internsidor::venv_path,
    require    => Package['libpq-dev'],
  }

  dirtree {$internsidor::static_files_path:
    ensure  => present,
    parents => true,
  }

  file {$internsidor::static_files_path:
    ensure  => directory,
    owner   => 'www-data',
    group   => 'www-data',
    recurse => true
  }

  $spexflix_media_path = "${internsidor::media_files_path}/spexflix"

  dirtree {$spexflix_media_path:
    ensure  => present,
    parents => true,
  }

  file {$internsidor::media_files_path:
    ensure  => directory,
    owner   => 'www-data',
    group   => 'www-data',
  }

  file {$spexflix_media_path:
    ensure  => directory,
    owner   => 'www-data',
    group   => 'www-data',
    recurse => true,
    require => File[$internsidor::media_files_path],
  }

  mount { $spexflix_media_path:
    device   => "${::nfs_storage_path}/spexflix",
    atboot   => yes,
    fstype   => "nfs4",
    options  => "sec=sys,rw,nodev,nosuid,hard",
    ensure   => mounted,
    remounts => true,
    pass     => "0",
    require  => File[$spexflix_media_path], 
  }
}
