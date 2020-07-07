# Configures and installs the django application
class internsidor (
  $admin_email           = "root@${::organization_domain}",
  $debug                 = false,
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
  $gunicorn_port         = undef,
) {
  include nginx
  include postgresql::server
  include postfix
  include base::certificates
  contain internsidor::install
  contain internsidor::milter
  contain internsidor::recipient_lookup
  contain internsidor::web_server

  keycloak_client { $oidc_clientid:
    realm                 => 'liss',
    secret                => $oidc_clientsecret,
    redirect_uris         => ["https://${domain}/*"],
    default_client_scopes => ['profile', 'email'],
  }

  file {"${project_path}/internsidor/settings/local.py":
    ensure  => file,
    content => epp('internsidor/settings/local.py.epp'),
    notify  => Service['internsidor-gunicorn'],
  }
}
