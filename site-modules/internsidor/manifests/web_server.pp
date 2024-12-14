# Configures the web server components that serves the application
class internsidor::web_server {

  # To avoid collision with nginx. Why was this even installed?
  package {['apache2', 'apache2-bin']:
    ensure => absent,
  }

  python::pip {'gunicorn':
    virtualenv => $internsidor::venv_path,
    require    => Package['libpq-dev'],
  }

  file {'/etc/systemd/system/internsidor-gunicorn.service':
    ensure  => file,
    content => epp('internsidor/internsidor-gunicorn.service.epp')
  }

  service {'internsidor-gunicorn':
    ensure    => running,
    enable    => true,
    require   => Python::Requirements[
      "${internsidor::project_path}/requirements-prod.txt",
    ],
    subscribe => File['/etc/systemd/system/internsidor-gunicorn.service'],
  }

  # Work around the fact that the nginx service from the puppet module doesn't create
  # the /run/nginx directory on startup, by adding the RuntimeDirectory setting for it in systemd.
  file {'/etc/systemd/system/nginx.service.d/override.conf':
    ensure  => file,
    owner   => 0,
    group   => 0,
    mode    => '0644',
    content => "[Service]\nRuntimeDirectory=nginx\n",
    notify  => [
      Service['nginx'],
    ]
  }

  file {'/etc/systemd/system/nginx.service.d':
    ensure  => directory,
    mode    => '0755',
  }

  nginx::resource::server { $internsidor::domain:
    proxy            => "http://localhost:${internsidor::gunicorn_port}",
    index_files      =>  [],
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

  nginx::resource::location{'/static/':
    location_alias => "${internsidor::static_files_path}/",
    server         => $internsidor::domain,
    index_files    =>  [],
    ssl            => true,
    ssl_only       => true,
  }

  # Redirect requests to old domain to new location
  nginx::resource::server { "spexflix.${::organization_domain}":
    maintenance       => true,
    maintenance_value => "return 301 \$scheme://${internsidor::domain}/spexflix\$request_uri",
  }
}
