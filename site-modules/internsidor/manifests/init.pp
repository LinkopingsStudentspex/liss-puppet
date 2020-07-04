# Konfiguration och installation av Django-sidan
class internsidor (
  $admin_email           = "root@${::organization_domain}",
  $django_db_name        = 'django',
  $django_db_pass        = '',
  $django_db_user        = 'django',
  $django_secret_key     = '',
  $domain                = '',
  $oidc_clientid         = 'internsidor',
  $oidc_clientsecret     = '',
  $project_path          = '/opt/internsidor/src',
  $static_files_path     = '/var/www/internsidor/static',
  $venv_path             = '/opt/internsidor/venv',
  $milter_port           = undef,
  $recipient_lookup_port = undef,
) {
  include nginx
  include postgresql::server
  include postfix

  # To avoid collision with nginx. Why was this even installed?
  package {'apache2':
    ensure => absent,
  }

  postgresql::server::db {$django_db_name:
    user     => $django_db_user,
    password => $django_db_pass,
    encoding => 'UTF-8',
  }

  class { 'python':
    version    => '3',
    pip        => present,
    virtualenv => present,
  }

  vcsrepo { $project_path:
    ensure   => latest,
    provider => git,
    source   => 'https://github.com/linkopingsstudentspex/internsidor.git',
    notify   => [
      Service['internsidor-gunicorn'],
      Exec['migrate django database'],
      Exec['collect static files'],
    ]
  }

  exec {'migrate django database':
    command     => "${venv_path}/bin/python manage.py migrate --settings=internsidor.settings.production",
    cwd         => $project_path,
    subscribe   => Postgresql::Server::Db[$django_db_name],
    refreshonly => true,
  }

  exec {'collect static files':
    command     => "${venv_path}/bin/python manage.py collectstatic --settings=internsidor.settings.production --no-input",
    cwd         => $project_path,
    user        => 'www-data',
    refreshonly => true,
    require     => Python::Requirements[
      "${project_path}/requirements-prod.txt",
      "${project_path}/requirements.txt",
    ],
  }

  python::virtualenv { $venv_path:
    version => '3',
  }

  keycloak_client { $oidc_clientid:
    realm                 => 'liss',
    secret                => $oidc_clientsecret,
    redirect_uris         => ["http://${domain}/*"],
    default_client_scopes => ['profile', 'email'],
  }

  # Apparently the bundled setuptools version is too old
  python::pip {'setuptools':
    ensure => latest,
  }

  python::requirements  { ["${project_path}/requirements-prod.txt", "${project_path}/requirements.txt"]:
    virtualenv   => $venv_path,
    pip_provider => pip3,
    require      => [
      Python::Virtualenv[$venv_path],
      Python::Pip['setuptools'],
    ],
    subscribe    => Vcsrepo[$project_path],
    forceupdate  => true,
  }

  package {[
    'python3-psycopg2',
    'libmilter-dev',
    'libsasl2-modules',
    'libpq-dev',
  ]:}

  python::pip {['gunicorn', 'psycopg2']:
    virtualenv => $venv_path,
    require    => Package['libpq-dev'],
  }

  dirtree {$static_files_path:
    ensure  => present,
    parents => true,
  }

  file {$static_files_path:
    ensure => directory,
    owner  => 'www-data',
    group  => 'www-data',
  }

  file {'/run/internsidor_gunicorn':
    ensure => directory,
    owner  => 'www-data',
    group  => 'www-data',
  }

  file {"${project_path}/internsidor/settings/local.py":
    ensure  => file,
    content => epp('internsidor/settings/local.py.epp'),
    notify  => Service['internsidor-gunicorn'],
  }

  $gunicorn_port = 8087

  file {'/etc/systemd/system/internsidor-gunicorn.service':
    ensure  => file,
    content => epp('internsidor/internsidor-gunicorn.service.epp')
  }

  service {'internsidor-gunicorn':
    ensure    => running,
    enable    => true,
    require   => Python::Requirements[
      "${project_path}/requirements-prod.txt",
      "${project_path}/requirements.txt",
    ],
    subscribe => File['/etc/systemd/system/internsidor-gunicorn.service'],
  }

  nginx::resource::server { $domain:
    proxy            => "http://localhost:${gunicorn_port}",
    index_files      =>  [],
    require          => Class['::base::certificates'],
    ssl_redirect     => true,
    ssl              => true,
    ssl_cert         => "/etc/letsencrypt/live/${domain}/fullchain.pem",
    ssl_key          => "/etc/letsencrypt/live/${domain}/privkey.pem",
    proxy_set_header => [
      'X-Forwarded-Proto $scheme',
      'X-Forwarded-Host $host',
      'X-Forwarded-Server $host',
      'X-Forwarded-for $proxy_add_x_forwarded_for',
    ],
  }

  nginx::resource::location{'/static/':
    location_alias => "${static_files_path}/",
    server         => $domain,
    index_files    =>  [],
  }

  file {'/etc/systemd/system/lissmilter.service':
    ensure  => file,
    content => epp('internsidor/lissmilter.service.epp'),
  }

  service {'lissmilter':
    ensure    => running,
    enable    => true,
    require   => Vcsrepo[$project_path],
    subscribe => File['/etc/systemd/system/lissmilter.service'],
  }

  file {'/etc/systemd/system/recipient-lookup.service':
    ensure  => file,
    content => epp('internsidor/recipient-lookup.service.epp'),
  }

  service {'recipient-lookup':
    ensure    => running,
    enable    => true,
    require   => Vcsrepo[$project_path],
    subscribe => File['/etc/systemd/system/recipient-lookup.service'],
  }
}
